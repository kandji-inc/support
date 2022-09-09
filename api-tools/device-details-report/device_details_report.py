#!/usr/bin/env python3

"""Generate reports from the device details tab."""

########################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
########################################################################################
#
# Created:  2022.06.03
# Modified: 2022.07.22
#
########################################################################################
# Software Information
########################################################################################
#
# This script is used to generate device reports based on the GET Device Details API
# endpoint for all devices in a Kandji tenant.
#
########################################################################################
# License Information
########################################################################################
# Copyright 2022 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to \
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CNNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
########################################################################################

__version__ = "0.0.4"


# Standard library
import argparse
import csv
import pathlib
import sys
from datetime import datetime

# 3rd party imports

try:
    import requests
except ImportError as import_error:
    print(import_error)
    sys.exit(
        "Looks like you need to install the requests module. Open a Terminal and run  "
        "python3 -m pip install requests."
    )

from requests.adapters import HTTPAdapter

########################################################################################
######################### UPDATE VARIABLES BELOW #######################################
########################################################################################

SUBDOMAIN = "accuhive"  # bravewaffles, example, company_name
REGION = "us"  # us and eu - this can be found in the Kandji settings on the Access tab

# Kandji Bearer Token
TOKEN = "your_api_key_here"

########################################################################################
######################### DO NOT MODIFY BELOW THIS LINE ################################
########################################################################################

# Initialize some variables
# Kandji API base URL
BASE_URL = f"https://{SUBDOMAIN}.clients.{REGION}-1.kandji.io/api"

SCRIPT_NAME = "Device details report"
TODAY = datetime.today().strftime("%Y%m%d")

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}

# Current working directory
HERE = pathlib.Path("__file__").parent.absolute()


def var_validation():
    """Validate varialbes."""
    if "accuhive" in BASE_URL:
        print(
            f'\n\tThe subdomain "{SUBDOMAIN}" in {BASE_URL} needs to be updated to '
            "your Kandji tenant subdomain..."
        )
        print("\tPlease see the example in the README for this repo.\n")
        sys.exit()

    if "api_key" in TOKEN:
        print(f'\n\tThe TOKEN should not be "{TOKEN}"...')
        print("\tPlease update this to your API Token.\n")
        sys.exit()


def program_arguments():
    """Return arguments."""
    parser = argparse.ArgumentParser(
        prog="device_details_report",
        description=(
            "Get a report containing information from the device details API."
        ),
        allow_abbrev=False,
    )

    # add grouped arguments that cannot be called together
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--user-activation-lock",
        type=str,
        metavar="on|off",
        help="Return devices were user-based activation lock is either on or off. If "
        "user-based activation lock is on this means that the user has signed into "
        "iCloud with a personal Apple ID.",
        required=False,
    )

    group.add_argument(
        "--ade-eligible",
        type=str,
        metavar="yes|no",
        help="Return devices that are either ADE eligible(yes) via Apple Business "
        "Manager or not(no).",
        required=False,
    )

    group.add_argument(
        "--auto-enrolled",
        type=str,
        metavar="yes|no",
        help="Return devices that were either automatically enrolled(yes) via "
        "Automated Device Enrollment and Apple Business Manager or not(no).",
        required=False,
    )

    group.add_argument(
        "--filevault",
        type=str,
        metavar="on|off",
        help="Return macOS devices where FileVault is on or off",
        required=False,
    )

    group.add_argument(
        "--prk-escrowed",
        type=str,
        metavar="yes|no",
        help="Return macOS devices where FileVault PRK has either been escrowed(yes) "
        "or not(no).",
        required=False,
    )

    group.add_argument(
        "--kandji-agent",
        type=str,
        metavar="yes|no",
        help="Return macOS devices where the Kandji agent is or is not installed.",
        required=False,
    )

    group.add_argument(
        "--recovery-lock",
        type=str,
        metavar="on|off",
        help="Return macOS devices where recovery lock is either on or off.",
        required=False,
    )

    group.add_argument(
        "--remote-desktop",
        type=str,
        metavar="on|off",
        help="Return macOS devices where remote desktop is either on or off.",
        required=False,
    )

    group.add_argument(
        "--all",
        action="store_true",
        help="Just give me everything for all devices. No filters please...",
        required=False,
    )

    parser.add_argument(
        "--platform",
        type=str,
        metavar='"Mac"',
        help="Enter a specific device platform type. This will limit the search "
        "results to only the specified platform. Examples: Mac, iPhone, iPad, AppleTV.",
        required=False,
    )

    parser.version = __version__
    parser.add_argument("--version", action="version", help="Show this tool's version.")
    # parser.add_argument("-v", "--verbose", action="store", metavar="LEVEL")

    # handle some errors
    args = vars(parser.parse_args())
    if not any(args.values()):
        print()
        parser.error("No command options given. Use the --help flag for more details\n")

    args = parser.parse_args()

    return parser.parse_args()


def error_handling(resp, resp_code, err_msg):
    """Handle HTTP errors."""
    # 400
    if resp_code == requests.codes["bad_request"]:
        print(f"\n\t{err_msg}")
        print(f"\tResponse msg: {resp.text}\n")
    # 401
    elif resp_code == requests.codes["unauthorized"]:
        print("Make sure that you have the required permissions to access this data.")
        print(
            "Depending on the API platform this could mean that access has just been "
            "blocked."
        )
        sys.exit(f"\t{err_msg}")
    # 403
    elif resp_code == requests.codes["forbidden"]:
        print("The api key may be invalid or missing.")
        sys.exit(f"\t{err_msg}")
    # 404
    elif resp_code == requests.codes["not_found"]:
        print("\nWe cannot find the one that you are looking for...")
        print("Move along...")
        print(f"\tError: {err_msg}")
        print(f"\tResponse msg: {resp}")
        print(
            "\tPossible reason: If this is a device it could be because the device is "
            "not longer\n"
            "\t\t\t enrolled in Kandji. This would prevent the MDM command from being\n"
            "\t\t\t sent successfully.\n"
        )
    # 429
    elif resp_code == requests.codes["too_many_requests"]:
        print("You have reached the rate limit ...")
        print("Try again later ...")
        sys.exit(f"\t{err_msg}")
    # 500
    elif resp_code == requests.codes["internal_server_error"]:
        print("The service is having a problem...")
        sys.exit(err_msg)
    # 503
    elif resp_code == requests.codes["service_unavailable"]:
        print("Unable to reach the service. Try again later...")
    else:
        print("Something really bad must have happened...")
        print(err_msg)
        # sys.exit()


def kandji_api(method, endpoint, params=None, payload=None):
    """Make an API request and return data.

    method   - an HTTP Method (GET, POST, PATCH, DELETE).
    endpoint - the API URL endpoint to target.
    params   - optional parameters can be passed as a dict.
    payload  - optional payload is passed as a dict and used with PATCH and POST
               methods.
    Returns a JSON data object.
    """
    attom_adapter = HTTPAdapter(max_retries=3)
    session = requests.Session()
    session.mount(BASE_URL, attom_adapter)

    try:
        response = session.request(
            method,
            BASE_URL + endpoint,
            data=payload,
            headers=HEADERS,
            params=params,
            timeout=30,
        )

        # If a successful status code is returned (200 and 300 range)
        if response:
            try:
                data = response.json()
            except Exception:
                data = response.text

        # if the request is successful exeptions will not be raised
        response.raise_for_status()

    except requests.exceptions.RequestException as err:
        error_handling(resp=response, resp_code=response.status_code, err_msg=err)
        data = {"error": f"{response.status_code}", "api resp": f"{err}"}

    return data


def get_devices(params=None, ordering="serial_number"):
    """Return device inventory."""
    count = 0
    # limit - set the number of records to return per API call
    limit = 300
    # offset - set the starting point within a list of resources
    offset = 0
    # inventory
    data = []

    while True:
        # update params
        params.update(
            {"ordering": f"{ordering}", "limit": f"{limit}", "offset": f"{offset}"}
        )
        # print(params)

        # check to see if a platform was sprecified
        response = kandji_api(method="GET", endpoint="/v1/devices", params=params)

        count += len(response)
        offset += limit
        if len(response) == 0:
            break

        # breakout the response then append to the data list
        for record in response:
            data.append(record)

    if len(data) < 1:
        print("No devices found...\n")
        sys.exit()

    return data


def get_device_details(devices, _all=False):
    """Return device details."""
    # list to hold all device detail records
    data = []
    # Get device details for each device
    count = 0

    for device in devices:

        response = kandji_api(
            method="GET", endpoint=f"/v1/devices/{device['device_id']}/details"
        )

        if not _all:
            # remove the keys we want to exclude from the response
            del response["volumes"]
            del response["users"]["system_users"]
            del response["installed_profiles"]

        # update keys in the response for auto device enrollment
        # updates dict for devices that are not ade eligible and not autoenrolled.
        if response["automated_device_enrollment"] == {}:
            response.update(
                {
                    "automated_device_enrollment": {
                        "auto_enroll_eligible": False,
                        "auto_enrolled": False,
                    }
                }
            )

        data.append(response)
        count += 1

    return data


def flatten(input_dict, separator=".", prefix=""):
    """Flatten JSON."""
    output_dict = {}

    for key, value in input_dict.items():
        if isinstance(value, dict) and value:
            deeper = flatten(value, separator, prefix + key + separator)
            output_dict.update({key2: val2 for key2, val2 in deeper.items()})

        elif isinstance(value, list) and value:
            for index, sublist in enumerate(value, start=1):
                if isinstance(sublist, dict) and sublist:
                    deeper = flatten(
                        sublist,
                        separator,
                        prefix + key + separator + str(index) + separator,
                    )

                    output_dict.update({key2: val2 for key2, val2 in deeper.items()})

                else:
                    output_dict[prefix + key + separator + str(index)] = value

        else:
            output_dict[prefix + key] = value

    return output_dict


def generate_report_payload(input_, details_param=None):
    """Create a JSON payload."""
    report_payload = []

    for record in input_:
        # flattend = flatten_dictionary(dict_=attr)
        flattened = flatten(record)

        if details_param:
            details_param_keys = list(details_param.keys())
            details_param_values = list(details_param.values())

            for key, value in flattened.items():

                if key == details_param_keys[0] and details_param_values[0] == value:
                    report_payload.append(flattened)

        else:
            report_payload.append(flattened)

    return report_payload


def write_report(input_, report_name):
    """Write report."""
    # write report to csv file
    with open(report_name, mode="w", encoding="utf-8") as report:

        out_fields = []

        # automatically loop over keys in the payload to pullout header fields
        for item in input_:
            for key in item.keys():
                if key not in out_fields:
                    out_fields.append(key)

        writer = csv.DictWriter(report, fieldnames=out_fields)

        # Write headers to CSV
        writer.writeheader()

        # Loop over the list sorted by serial_number
        for item in input_:
            writer.writerow(item)


def main():
    """Run main logic."""
    # validate vars
    var_validation()

    # Return the arguments
    arguments = program_arguments()

    print(f"\nVersion: {__version__}")
    print(f"Base URL: {BASE_URL}\n")

    # dict placeholder for params passed to api requests
    params_dict = {}

    details_param = {}

    # hold items used in report name
    report_name_items = []

    # evaluate options
    if arguments.platform:
        report_name_items.append(f"{arguments.platform.lower()}")
        params_dict.update({"platform": f"{arguments.platform}"})

    if arguments.filevault:
        # this leverages the devices params
        if arguments.filevault == "on":
            params_dict.update({"filevault_enabled": "true"})
        else:
            params_dict.update({"filevault_enabled": "false"})
        report_name_items.append(f"filevault_{arguments.filevault.lower()}")

    if arguments.prk_escrowed:
        # this leverages the devices params
        looking_for = f"FileVault PRK escrowed: {arguments.prk_escrowed}"
        if arguments.prk_escrowed.lower() == "yes":
            details_param.update({"filevault.filevault_prk_escrowed": True})
        else:
            details_param.update({"filevault.filevault_prk_escrowed": False})
        report_name_items.append(
            f"filevault_prk_escrowed_{arguments.prk_escrowed.lower()}"
        )

    if arguments.user_activation_lock:
        # this leverages the devices params
        looking_for = f"User Activation Lock: {arguments.user_activation_lock}"
        if arguments.user_activation_lock.lower() == "yes":
            details_param.update({"activation_lock.user_activation_lock_enabled": True})
        else:
            # ade, no auto enroll
            details_param.update(
                {"activation_lock.user_activation_lock_enabled": False}
            )
        report_name_items.append(
            f"user_activation_lock_{arguments.user_activation_lock.lower()}"
        )

    if arguments.ade_eligible:
        # this leverages the devices params
        looking_for = f"ADE eligible: {arguments.ade_eligible}"
        if arguments.ade_eligible.lower() == "yes":
            details_param.update(
                {"automated_device_enrollment.auto_enroll_eligible": True}
            )
        else:
            # ade, no auto enroll
            details_param.update(
                {"automated_device_enrollment.auto_enroll_eligible": False}
            )
        report_name_items.append(f"ade_eligible_{arguments.ade_eligible.lower()}")

    if arguments.auto_enrolled:
        # this leverages the devices params
        looking_for = f"Auto Enrolled: {arguments.auto_enrolled}"
        if arguments.auto_enrolled.lower() == "yes":
            details_param.update({"automated_device_enrollment.auto_enrolled": True})
        else:
            # ade, no auto enroll
            details_param.update({"automated_device_enrollment.auto_enrolled": False})
        report_name_items.append(f"auto_enrolled_{arguments.auto_enrolled.lower()}")

    if arguments.recovery_lock:
        # this leverages the devices params
        looking_for = f"Recovery lock: {arguments.recovery_lock}"
        if arguments.recovery_lock.lower() == "on":
            details_param.update({"recovery_information.recovery_lock_enabled": True})
        else:
            details_param.update({"recovery_information.recovery_lock_enabled": False})
        report_name_items.append(f"recovery_lock_{arguments.recovery_lock.lower()}")

    if arguments.kandji_agent:
        # this needs to get details then parse out this info from there
        looking_for = f"Kandji Agent Installed: {arguments.kandji_agent}"
        if arguments.kandji_agent == "yes":
            details_param.update({"kandji_agent.agent_installed": "True"})
        else:
            details_param.update({"kandji_agent.agent_installed": "False"})
        report_name_items.append(f"kandji_agent_{arguments.kandji_agent.lower()}")

    if arguments.remote_desktop:
        # this leverages the devices params
        looking_for = f"Remote Desktop: {arguments.remote_desktop}"
        if arguments.remote_desktop.lower() == "on":
            details_param.update({"security_information.remote_desktop_enabled": True})
        else:
            details_param.update({"security_information.remote_desktop_enabled": False})
        report_name_items.append(f"remote_desktop_{arguments.remote_desktop.lower()}")

    if arguments.all:
        # this leverages the devices params
        looking_for = "Everything"
        report_name_items.append("all_details")

    # Get all device inventory records
    print("Getting device inventory from Kandji...")
    device_inventory = get_devices(params=params_dict)
    print(f"Total records: {len(device_inventory)}\n")

    if arguments.all:
        # return device details for each record returned in the inventory
        print("Getting all details for all devices...")
        print("No filters will be applied...")
        device_details = get_device_details(devices=device_inventory, _all=True)

    else:
        # return device details for each record returned in the inventory
        print("Getting device record details...")
        device_details = get_device_details(devices=device_inventory)

    # Get the app names and app versions from the app details by passing a list of
    # device ids
    if details_param:
        print(f"Looking for devices with {looking_for}")
        # print(details_param)
        report_payload = generate_report_payload(
            input_=device_details, details_param=details_param
        )
    else:
        report_payload = generate_report_payload(input_=device_details)

    # build report name
    if report_name_items:
        report_name = "_".join(report_name_items)
        report_name = f"{report_name}_report_{TODAY}.csv"

    else:
        report_name = f"device_details_report_{TODAY}.csv"

    print(f"Total records in report: {len(report_payload)}\n")

    if len(report_payload) < 1:
        print("No device found...")
        print("No report generated...\n")
        sys.exit()

    print("Generating device report...")
    write_report(input_=report_payload, report_name=report_name)

    print(f"Kandji report at: {HERE.resolve()}/{report_name}\n")


if __name__ == "__main__":
    main()
