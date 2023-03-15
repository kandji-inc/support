#!/usr/bin/env python3

"""Generate reports from the device details tab."""

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created:  2022.06.03
# Last Modified: 2023.03.01
################################################################################################
# Software Information
################################################################################################
#
# This script is used to generate device reports based on the GET Device Details API
# endpoint for all devices in a Kandji tenant.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2023 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
################################################################################################

__version__ = "0.1.2"


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

# us("") and eu - this can be found in the Kandji settings on the Access tab
REGION = ""

# Kandji Bearer Token
TOKEN = ""

########################################################################################
######################### DO NOT MODIFY BELOW THIS LINE ################################
########################################################################################

# Kandji API base URL
if REGION in ["", "us"]:
    BASE_URL = f"https://{SUBDOMAIN}.api.kandji.io/api"

elif REGION in ["eu"]:
    BASE_URL = f"https://{SUBDOMAIN}.api.{REGION}.kandji.io/api"

else:
    sys.exit(f'\nUnsupported region "{REGION}". Please update and try again\n')

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
    """Validate variables."""
    if SUBDOMAIN in ["", "accuhive"]:
        print(
            f'\nThe subdomain "{SUBDOMAIN}" in {BASE_URL} needs to be updated to '
            "your Kandji tenant subdomain..."
        )
        print("Please see the example in the README for this repo.\n")
        sys.exit()

    if TOKEN in ["api_key", ""]:
        print(f'\nThe TOKEN should not be "{TOKEN}"...')
        print("Please update this to your API Token.\n")
        sys.exit()


def program_arguments():
    """Return arguments."""
    parser = argparse.ArgumentParser(
        prog="device_details",
        description=(
            "Generate reports containing information from the device details API."
        ),
        allow_abbrev=False,
    )

    query_options = parser.add_argument_group(
        title="Query options",
        description="The following option can be used to create queries against devices in a Kandji instance. Multiple options can be combined together.",
    )

    query_options.add_argument(
        "--ade-eligible",
        type=str,
        metavar="[yes|no]",
        help="Return devices that are either ADE eligible (yes) via Apple Business "
        "Manager or not (no).",
        required=False,
    )

    query_options.add_argument(
        "--auto-enrolled",
        type=str,
        metavar="[yes|no]",
        help="Return devices that were either automatically enrolled(yes) via "
        "Automated Device Enrollment and Apple Business Manager or not(no).",
        required=False,
    )

    query_options.add_argument(
        "--device-activation-lock",
        type=str,
        metavar="[on|off]",
        help="Return devices where device-based activation lock is either on or off.",
        required=False,
    )

    query_options.add_argument(
        "--filevault",
        type=str,
        metavar="[on|off]",
        help="Return macOS devices where FileVault is on or off",
        required=False,
    )

    query_options.add_argument(
        "--kandji-agent",
        type=str,
        metavar="[yes|no]",
        help="Return macOS devices where the Kandji agent is or is not installed.",
        required=False,
    )

    query_options.add_argument(
        "--os-version",
        type=str,
        metavar='"13.2.1"',
        help="Look for devices with OS versions matching the version string specified. If 13 is passed, for example, all devices with an OS version that starts with 13 will be returned.",
        required=False,
    )

    query_options.add_argument(
        "--prk-escrowed",
        type=str,
        metavar="[yes|no]",
        help="Return macOS devices where FileVault PRK has either been escrowed (yes) "
        "or not (no).",
        required=False,
    )

    query_options.add_argument(
        "--processor-type",
        type=str,
        metavar="[Intel|Apple]",
        help="Return devices with the specified processor architecture.",
        required=False,
    )

    query_options.add_argument(
        "--recovery-lock",
        type=str,
        metavar="[on|off]",
        help="Return macOS devices where recovery lock is either on or off.",
        required=False,
    )

    query_options.add_argument(
        "--remote-desktop",
        type=str,
        metavar="[on|off]",
        help="Return macOS devices where remote desktop is either on or off.",
        required=False,
    )

    query_options.add_argument(
        "--user-activation-lock",
        type=str,
        metavar="[on|off]",
        help="Return devices where user-based activation lock is either on or off. If "
        "user-based activation lock is on this means that the user has signed into "
        "iCloud with a personal Apple ID.",
        required=False,
    )

    query_options.add_argument(
        "--all-details",
        action="store_true",
        help="Just give me everything for all devices. No filters please...",
        required=False,
    )

    group_search = parser.add_argument_group(
        title="Limit search",
        description="A search can be limited to a specific device, blueprint, or an entire device platform. If no options are specified, the script will search through "
        "all devices in the Kandji tenant.",
    )
    group_search.add_argument(
        "--serial-number",
        type=str,
        metavar="XX7FFXXSQ1GH",
        help="Search for a specific device by serial number.",
        required=False,
    )

    group_search.add_argument(
        "--blueprint",
        type=str,
        metavar="[blueprint_name]",
        help="Search for devices in a specific blueprint in a Kandji instance. ",
        required=False,
    )

    group_search.add_argument(
        "--platform",
        type=str,
        metavar="[Mac|iPhone|iPad|AppleTV]",
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
        parser.error(
            "No command options given. Use the --help flag for more details.\n"
        )

    return parser.parse_args()


def http_errors(resp, resp_code, err_msg):
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
            "\tPossible reason: If this is a device, it could be because the device is "
            "no longer\n"
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
        sys.exit()


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

        # if the request is successful exceptions will not be raised
        response.raise_for_status()

    except requests.exceptions.RequestException as err:
        http_errors(resp=response, resp_code=response.status_code, err_msg=err)
        data = {"error": f"{response.status_code}", "api resp": f"{err}"}

    return data


def get_devices(params=None, ordering="serial_number"):
    """Return device inventory."""
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

        # check to see if a platform was specified
        response = kandji_api(method="GET", endpoint="/v1/devices", params=params)

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

        update_ade_dict(_input=response)
        update_hardware_overview_dict(_input=response)
        data.append(response)
        count += 1

    return data


def update_ade_dict(_input):
    """Update ade dict for non ade enrolled devices."""
    ade_enrollment_dict = _input.get("automated_device_enrollment")

    # update keys in the response for auto device enrollment
    # updates dict for devices that are not ade eligible and not auto-enrolled.
    if _input["automated_device_enrollment"] == {}:
        ade_enrollment_dict.update(
            {"auto_enroll_eligible": False, "auto_enrolled": False}
        )


def update_hardware_overview_dict(_input):
    """Return chip architecture type."""
    hw_overview_dict = _input.get("hardware_overview")

    try:
        if "apple" in _input["hardware_overview"].get("processor_name").lower():
            hw_overview_dict.update({"processor_type": "Apple"})
        else:
            hw_overview_dict.update({"processor_type": "Intel"})

    except TypeError as error:
        hw_overview_dict.update({"processor_type": "Unknown"})

    except AttributeError as error:
        hw_overview_dict.update({"processor_type": "Unknown"})


def get_blueprint(bp_name=None):
    """Get blueprint.

    Return the blueprint ID of the blueprint if found."""
    blueprint_id = ""
    blueprint_record = kandji_api(
        method="GET",
        endpoint="/v1/blueprints",
        params={"name": f"{bp_name}"},
    )

    if blueprint_record["count"] == 0:
        print(f"WARNING: {bp_name} blueprint not found...")
        print("WARNING: Check the name of the blueprint and try again.")
        sys.exit()

    count = 0

    # ensure that the name returned matches the name we are looking for exactly.
    for blueprint in blueprint_record["results"]:
        if bp_name == blueprint["name"]:
            print(f'Found blueprint matching the name "{bp_name}"...')
            blueprint_id = blueprint.get("id")
            break

        count += 1

        if count == blueprint_record.get("count"):
            print(f'Did not find any blueprints matching the name "{bp_name}"...')
            print("WARNING: Check the name of the blueprint and try again.")
            sys.exit()

    return blueprint_id


def flatten(input_dict, separator=".", prefix=""):
    """Flatten JSON."""
    output_dict = {}

    for key, value in input_dict.items():

        # Check to see if the JSON value is a dict type. If it is then we we need to break the
        # JSON structure out more.
        if isinstance(value, dict) and value:
            deeper = flatten(value, separator, prefix + key + separator)

            # update the dictionary with the new structure.
            output_dict.update({key2: val2 for key2, val2 in deeper.items()})

        # If the JSON value is a list then loop over and see if we need to break out any values
        # contained in the list.
        elif isinstance(value, list) and value:
            for index, sublist in enumerate(value, start=1):
                # Check to see if the JSON value is a dict type. If it is then we we need to
                # break the JSON structure out more.
                if isinstance(sublist, dict) and sublist:
                    deeper = flatten(
                        sublist,
                        separator,
                        prefix + key + separator + str(index) + separator,
                    )

                    # update the dictionary with the new structure.
                    output_dict.update({key2: val2 for key2, val2 in deeper.items()})

                else:
                    output_dict[prefix + key + separator + str(index)] = value

        else:
            output_dict[prefix + key] = value

    return output_dict


def generate_report_payload(_input, details_param=None):
    """Create a JSON payload."""
    report_payload = []

    for record in _input:
        flattened = flatten(record)
        if details_param:
            if details_param.items() <= flattened.items():
                report_payload.append(flattened)

        else:
            report_payload.append(flattened)

    return report_payload


def write_report(_input, report_name, sort_by="serial_number"):
    """Write the report."""
    with open(report_name, mode="w", encoding="utf-8") as report:

        out_fields = []

        for item in _input:
            for key in item.keys():
                if key not in out_fields:
                    out_fields.append(key)

        # find the "sort_by" field so that we can sort the report on that.
        def thingy(out_field):
            this = ""
            if sort_by in out_field:
                this = sort_by
            return this

        writer = csv.DictWriter(
            report, fieldnames=sorted(out_fields, key=thingy, reverse=True)
        )

        # Write headers to CSV
        writer.writeheader()

        # Loop over the item list
        for item in _input:
            # Write row to csv file
            writer.writerow(item)


def main():
    """Run main logic."""

    # Return the arguments
    arguments = program_arguments()

    # validate vars
    var_validation()

    print(f"\nScript Version: {__version__}")
    print(f"Base URL: {BASE_URL}")

    # holds params passed to devices enpoint
    device_params = {}

    # holds params used to search device details
    details_param = {}

    # holds report name components
    report_name_items = []

    looking_for = []

    if arguments.ade_eligible:
        looking_for.append(f"ade-eligible: {arguments.ade_eligible}")
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
        looking_for.append(f"auto-enrolled: {arguments.auto_enrolled}")
        if arguments.auto_enrolled.lower() == "yes":
            details_param.update({"automated_device_enrollment.auto_enrolled": True})
        else:
            # ade, no auto enroll
            details_param.update({"automated_device_enrollment.auto_enrolled": False})
        report_name_items.append(f"auto_enrolled_{arguments.auto_enrolled.lower()}")

    if arguments.device_activation_lock:
        looking_for.append(
            f"device-activation-lock: {arguments.device_activation_lock}"
        )
        if arguments.device_activation_lock.lower() == "on":
            details_param.update(
                {"activation_lock.device_activation_lock_enabled": True}
            )
        else:
            # ade, no auto enroll
            details_param.update(
                {"activation_lock.device_activation_lock_enabled": False}
            )
        report_name_items.append(
            f"device_activation_lock_{arguments.device_activation_lock.lower()}"
        )

    if arguments.filevault:
        looking_for.append(f"filevault: {arguments.filevault}")
        if arguments.filevault == "on":
            device_params.update({"filevault_enabled": "true"})
        else:
            device_params.update({"filevault_enabled": "false"})
        report_name_items.append(f"filevault_{arguments.filevault.lower()}")

    if arguments.kandji_agent:
        # this needs to get details then parse out this info from there
        looking_for.append(f"kandji-agent: {arguments.kandji_agent}")
        if arguments.kandji_agent == "yes":
            details_param.update({"kandji_agent.agent_installed": "True"})
        else:
            details_param.update({"kandji_agent.agent_installed": "False"})
        report_name_items.append(f"kandji_agent_{arguments.kandji_agent.lower()}")

    if arguments.os_version:
        looking_for.append(f"os-version: {arguments.os_version}")
        device_params.update({"os_version": f"{arguments.os_version}"})
        report_name_items.append(
            f"os_version_{arguments.os_version.replace('.', '_').lower()}"
        )

    if arguments.prk_escrowed:
        looking_for.append(f"prk-escrowed: {arguments.prk_escrowed}")
        if arguments.prk_escrowed.lower() == "yes":
            details_param.update({"filevault.filevault_prk_escrowed": True})
        else:
            details_param.update({"filevault.filevault_prk_escrowed": False})
        report_name_items.append(
            f"filevault_prk_escrowed_{arguments.prk_escrowed.lower()}"
        )

    if arguments.processor_type:
        looking_for.append(f"processor-type: {arguments.processor_type}")
        if arguments.processor_type.lower() == "apple":
            details_param.update({"hardware_overview.processor_type": "Apple"})
        else:
            details_param.update({"hardware_overview.processor_type": "Intel"})
        report_name_items.append(f"processor_type_{arguments.processor_type.lower()}")

    if arguments.recovery_lock:
        looking_for.append(f"recovery-lock: {arguments.recovery_lock}")
        if arguments.recovery_lock.lower() == "on":
            details_param.update({"recovery_information.recovery_lock_enabled": True})
        else:
            details_param.update({"recovery_information.recovery_lock_enabled": False})
        report_name_items.append(f"recovery_lock_{arguments.recovery_lock.lower()}")

    if arguments.remote_desktop:
        looking_for.append(f"remote-desktop: {arguments.remote_desktop}")
        if arguments.remote_desktop.lower() == "on":
            details_param.update({"security_information.remote_desktop_enabled": True})
        else:
            details_param.update({"security_information.remote_desktop_enabled": False})
        report_name_items.append(f"remote_desktop_{arguments.remote_desktop.lower()}")

    if arguments.user_activation_lock:
        looking_for.append(f"user-activation-lock: {arguments.user_activation_lock}")
        if arguments.user_activation_lock.lower() == "on":
            details_param.update({"activation_lock.user_activation_lock_enabled": True})
        else:
            # ade, no auto enroll
            details_param.update(
                {"activation_lock.user_activation_lock_enabled": False}
            )
        report_name_items.append(
            f"user_activation_lock_{arguments.user_activation_lock.lower()}"
        )

    if arguments.all_details:
        looking_for.append("everything")
        report_name_items.append("all_details")

    if arguments.serial_number:
        device_params.update({"serial_number": f"{arguments.serial_number}"})
        print(
            "Looking for device record with the following serial number: "
            f"{arguments.serial_number}"
        )

    if arguments.blueprint:
        blueprint_name = arguments.blueprint
        device_params.update(
            {"blueprint_id": f"{get_blueprint(bp_name=blueprint_name)}"}
        )

    if arguments.platform:
        report_name_items.append(f"{arguments.platform.lower()}")
        device_params.update({"platform": f"{arguments.platform}"})

    # Get all device inventory records
    print("Getting device inventory from Kandji...")
    device_inventory = get_devices(params=device_params)
    print(f"Total records: {len(device_inventory)}")

    print(f"Query: {', '.join(looking_for)}")

    if arguments.all_details:
        # return device details for each record returned in the inventory
        print("Getting all details for all devices...")
        print("No filters will be applied...")
        device_details = get_device_details(devices=device_inventory, _all=True)

    else:
        # return device details for each record returned in the inventory
        print("Getting device record details...")
        device_details = get_device_details(devices=device_inventory)

    # search device details output
    if details_param:
        report_payload = generate_report_payload(
            _input=device_details, details_param=details_param
        )
    else:
        report_payload = generate_report_payload(_input=device_details)

    # build report name
    if report_name_items:
        report_name = "_".join(report_name_items)
        report_name = f"{report_name}_report_{TODAY}.csv"

    else:
        report_name = f"device_details_report_{TODAY}.csv"

    print(f"Total records in report: {len(report_payload)}")

    if len(report_payload) < 1:
        print("No device found with matching search criteria")
        print("No report generated")
        sys.exit()

    print("Generating device report...")
    write_report(_input=report_payload, report_name=report_name)

    print(f"Kandji report at: {HERE.resolve()}/{report_name}\n")


if __name__ == "__main__":
    main()
