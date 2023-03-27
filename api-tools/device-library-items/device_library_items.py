#!/usr/bin/env python3

"""Generate a report from the device library items API."""

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2022-02-08
# Last modified - 2023.02.07
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

__version__ = "1.2.1"


# Standard library
import argparse
import csv
import pathlib
import sys
from datetime import datetime

try:
    import requests
except ImportError as import_error:
    print(import_error)
    sys.exit(
        "Looks like you need to install the requests module. Open a Terminal and run "
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

SCRIPT_NAME = "Library items Report"
TODAY = datetime.today().strftime("%Y%m%d")

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}

# Current working directory
HERE = pathlib.Path("__file__").parent


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
        prog="device_library_items",
        description=(
            "Get a report containing information for a given library item or all "
            "library items for all devices."
        ),
        allow_abbrev=False,
    )

    parser.add_argument(
        "--platform",
        type=str,
        metavar='"Mac"',
        help="Enter a specific device platform type. This will limit the search "
        "results to only the specified platform. Examples: Mac, iPhone, iPad, AppleTV. "
        "Ether the --library-item or --all-lit options must also be specified "
        "if the --platform is used.",
        required=False,
    )

    # add grouped arguments that cannot be called together
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--library-item",
        type=str,
        metavar='"Google Chrome"',
        help="Enter the name of a specific Kandji library item. Cannot be used "
        "together with the --all-lit option",
        required=False,
    )

    group.add_argument(
        "--all-lit",
        action="store_true",
        help="Use this option to return all library items for all devices. Cannot be "
        "used together with the --library-item option",
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


def device_status_category(data, category):
    """Return the device library items."""
    return data[category]


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
    arguments = program_arguments()

    var_validation()

    print(f"\nRunning: {SCRIPT_NAME} ...")
    print(f"Version: {__version__}")
    print(f"Base URL: {BASE_URL}")

    # dict placeholder for params passed to api requests
    params_dict = {}

    # Report name
    if arguments.library_item:
        lit_to_lower = arguments.library_item.lower().replace(" ", "_")
        report_name = f"{lit_to_lower}_lit_report_{TODAY}.csv"
        search_term = arguments.library_item
        print(f'Looking for devices with the "{search_term}" library item assigned...')

        if arguments.platform:
            params_dict.update({"platform": f"{arguments.platform}"})
            report_name = (
                f"{arguments.platform.lower()}_{lit_to_lower}_lit_report_{TODAY}.csv"
            )

    # Report name
    if arguments.all_lit:
        report_name = f"all_library_items_report_{TODAY}.csv"

        if arguments.platform:
            params_dict.update({"platform": f"{arguments.platform}"})
            report_name = (
                f"{arguments.platform.lower()}_all_library_items_report_{TODAY}.csv"
            )

    # Get all device inventory records
    print("Getting device inventory from Kandji...")
    device_inventory = get_devices(params=params_dict)
    print(f"Total device records: {len(device_inventory)}")

    report_payload = []

    for device in device_inventory:
        # We are looking for a library item

        lib_items_data = kandji_api(
            method="GET", endpoint=f"/v1/devices/{device['device_id']}/library-items"
        )
        library_items = device_status_category(lib_items_data, "library_items")

        for item in library_items:

            # these are all the fields that will be used in the report
            item_info = {
                "serial_number": device["serial_number"].upper(),
                "device_name": device["device_name"],
                "blueprint_name": device["blueprint_name"],
                "os_version": device["os_version"],
                "user": device["user"],
                "name": item["name"],
                "status": item["status"],
                "type": item["type"],
                "reported_at": item["reported_at"],
                "last_audit_run": item["last_audit_run"],
                "last_audit_log": item["last_audit_log"],
                "control_reported_at": item["control_reported_at"],
                "control_log": item["control_log"],
                "log": item["log"],
            }

            # if a specific lit is specified then we only want to build a report
            # containing that name only.
            if arguments.library_item:
                if item["name"] == search_term:
                    report_payload.append(item_info)

            else:
                report_payload.append(item_info)

    if len(report_payload) < 1:
        print(f"No devices found with {search_term} in scope...")
        print(
            "Double check the name of the Library item and make sure that it exists in "
            "Kandji..."
        )
    else:
        if arguments.library_item:
            print(f"Found {len(report_payload)} devices with {search_term} assigned...")
        print("Generating LIT report...")
        write_report(report_payload, report_name)

        print(f"Kandji report at: {HERE.resolve()}/{report_name} ")

    print("")


if __name__ == "__main__":
    main()
