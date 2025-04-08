#!/usr/bin/env python3

"""Return device secrets."""

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2023-03-21
################################################################################################
# Software Information
################################################################################################
#
# This script can be used to return device secrets.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2024 Kandji, Inc.
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

__version__ = "0.0.8"


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
        prog="device_secrets.py",
        description="Get device secrets from a Kandji instance.",
        allow_abbrev=False,
    )

    group_secrets = parser.add_argument_group(
        title="Device secrets",
        description="The following option can be used to return device secrets. "
        "Multiple options can be combined together.",
    )

    group_secrets.add_argument(
        "--filevault",
        action="store_true",
        help="Return the FileVault recovery key. Only for macOS.",
        required=False,
    )

    group_secrets.add_argument(
        "--pin",
        action="store_true",
        help="Return the unlockpin",
        required=False,
    )

    group_secrets.add_argument(
        "--albc",
        action="store_true",
        help="Return the device-based and user-based activation lock bypass codes.",
        required=False,
    )

    group_secrets.add_argument(
        "--recovery",
        action="store_true",
        help="Return the device recovery key that is configured by the Recovery Password library item.",
        required=False,
    )

    # add grouped arguments that cannot be called together
    group_search = parser.add_argument_group(
        title="Search options",
        description="A search can be limited to a specific device, blueprint, or an "
        "entire device platform.",
    )
    group_search_mx = group_search.add_mutually_exclusive_group(required=True)

    group_search_mx.add_argument(
        "--serial-number",
        type=str,
        metavar="XX7FFXXSQ1GH",
        help="Look up a device by its serial number and send an action to it.",
        required=False,
    )

    group_search_mx.add_argument(
        "--blueprint",
        type=str,
        metavar="[blueprint_name]",
        help="Send an action to devices in a specific blueprint in a Kandji instance. "
        "If this option is used, you will see a prompt to comfirm the action and will "
        "be required to enter a code to continue.",
        required=False,
    )

    group_search_mx.add_argument(
        "--platform",
        type=str,
        metavar="[Mac|iPhone|iPad|AppleTV]",
        help="Send an action to a specific device family in a Kandji instance. If "
        "this option is used, you will see a prompt to comfirm the action and will be "
        "required to enter a code to continue.",
        required=False,
    )

    group_search_mx.add_argument(
        "--all-devices",
        action="store_true",
        help="Send an action to all devices in a Kandji instance. If this option is "
        "used, you will see a prompt to comfirm the action and will be required to "
        "enter a code to continue.",
        required=False,
    )

    parser.version = __version__
    parser.add_argument("--version", action="version", help="Show this tool's version.")

    args = vars(parser.parse_args())
    if not any(args.values()):
        print()
        parser.error(
            "No command options given. Use the --help flag for more details.\n"
        )

    args = parser.parse_args()

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

        # check to see if a platform was specified
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


def get_device_secrets(devices, secrets):
    """Return device secrets."""
    # list to hold all device secrets
    data = []

    count = 0

    for device in devices:
        # this should contain the device serial_number plus any relevent secrets.
        device_secrets = {}

        device_secrets.update({"device_id": device.get("device_id")})
        device_secrets.update({"device_name": device.get("device_name")})
        device_secrets.update({"serial_number": device.get("serial_number")})
        device_secrets.update({"blueprint_name": device.get("blueprint_name")})
        device_secrets.update({"user": device.get("user")})
        device_secrets.update({"platform": device.get("platform")})

        for secret in secrets:
            response = kandji_api(
                method="GET",
                endpoint=f"/v1/devices/{device['device_id']}/secrets/{secret}",
            )

            if secret == "bypasscode":
                for item in response:
                    device_secrets.update(response)

            else:
                device_secrets.update(response)

            count += 1

        data.append(device_secrets)

    return data


def flatten(input_dict, separator="_", prefix=""):
    """Flatten JSON."""
    output_dict = {}

    for key, value in input_dict.items():
        # Check to see if the JSON value is a dict type. If it is then we we need to
        # break the JSON structure out more.
        if isinstance(value, dict) and value:
            deeper = flatten(value, separator, prefix + key + separator)

            # update the dictionary with the new structure.
            output_dict.update({key2: val2 for key2, val2 in deeper.items()})

        # If the JSON value is a list then loop over and see if we need to break out
        # any values contained in the list.
        elif isinstance(value, list) and value:
            for index, sublist in enumerate(value, start=1):
                # Check to see if the JSON value is a dict type. If it is then we we
                # need to break the JSON structure out more.
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

    # cleanup any fields that we do not need because theyve been flattened.
    output_dict.pop("user", None)

    return output_dict


def generate_report_payload(_input, details_param=None):
    """Create a JSON payload."""
    report_payload = []

    for record in _input:
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
    # validate vars
    var_validation()

    # Return the arguments
    arguments = program_arguments()

    print(f"\nVersion: {__version__}")
    print(f"Base URL: {BASE_URL}\n")

    device_params = {}
    secrets = []
    looking_for = []
    report_name_items = []

    if arguments.filevault:
        looking_for.append("FileVault Key")
        secret = "filevaultkey"
        secrets.append(secret)
        report_name_items.append(f"{secret.lower()}")

    if arguments.pin:
        looking_for.append("Unlock PIN")
        secret = "unlockpin"
        secrets.append(secret)
        report_name_items.append(f"{secret.lower()}")

    if arguments.albc:
        looking_for.append("Bypass Codes")
        secret = "bypasscode"
        secrets.append(secret)
        report_name_items.append(f"{secret.lower()}")

    if arguments.recovery:
        looking_for.append("Recovery Key")
        secret = "recoverypassword"
        secrets.append(secret)
        report_name_items.append(f"{secret.lower()}")

    if arguments.serial_number:
        report_name_items.append(f"{arguments.serial_number.lower()}")
        device_params.update({"serial_number": f"{arguments.serial_number}"})
        print(
            "Looking for device record with the following serial number: "
            f"{arguments.serial_number}"
        )

    if arguments.blueprint:
        blueprint_name = arguments.blueprint
        report_name_items.append(f"{blueprint_name.lower()}")
        device_params.update(
            {"blueprint_id": f"{get_blueprint(bp_name=blueprint_name)}"}
        )

    if arguments.platform:
        report_name_items.append(f"{arguments.platform.lower()}")
        device_params.update({"platform": f"{arguments.platform}"})

    if arguments.all_devices:
        report_name_items.append(f"{arguments.all_devices}")
        print("Look for secrets across all devices in the Kandji instance...")

    # Get all device inventory records
    print("Getting device inventory from Kandji...")
    device_inventory = get_devices(params=device_params)
    print(f"Total records returned: {len(device_inventory)}")
    print(f"Secrets query: {', '.join(looking_for)}")

    # secrets
    print("Running query...hang tight.")
    device_secrets = get_device_secrets(devices=device_inventory, secrets=secrets)

    # build report name
    if report_name_items:
        report_name = "_".join(report_name_items)
        report_name = f"{report_name}_secrets_report_{TODAY}.csv"

    else:
        report_name = f"device_secrets_{TODAY}.csv"

    # build the report payload
    report_payload = generate_report_payload(_input=device_secrets)

    print(f"Total records in report: {len(report_payload)}")

    if len(report_payload) < 1:
        print("No device found with matching search criteria")
        print("No report generated")
        sys.exit()

    print("Generating device report...")
    write_report(_input=report_payload, report_name=report_name)

    print(f"Kandji report at: {HERE.resolve()}/{report_name}")


if __name__ == "__main__":
    main()
