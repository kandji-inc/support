#!/usr/bin/env python3

"""Returns a basic device report from the GET devices API."""

########################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
########################################################################################
# Created on 09/22/2021
# Updated on 05/12/2022
########################################################################################
# Software Information
########################################################################################
#
#   This script is used to generate a basic device report based on the GET Devices API
#   endpoint for all devices in a Kandji tenant.
#
########################################################################################
# License Information
########################################################################################
# Copyright 2022 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
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
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
########################################################################################

__version__ = "1.0.0"


# Standard library
import argparse
import csv
import pathlib
import sys
from datetime import datetime

# Try to import the module. If the module cannot be imported let the user know so that
# they can install it.
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

TODAY = datetime.today().strftime("%Y%m%d")

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}

# Report name
SCRIPT_NAME = "Device Report"
TODAY = datetime.today().strftime("%Y%m%d")

# Current working directory
HERE = pathlib.Path("__file__").parent


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
        prog="device_report",
        description=(
            "This tool is used to generate a device report based on the GET Devices "
            "API endpoint for all devices in a Kandji tenant."
        ),
        allow_abbrev=False,
    )

    parser.add_argument(
        "--platform",
        type=str,
        metavar='"Mac"',
        help="Enter a specific device platform type. This will limit the search "
        "results to only the specified platfrom. Examples: Mac, iPhone, iPad, AppleTV.",
        required=False,
    )

    parser.version = __version__
    parser.add_argument("--version", action="version", help="Show this tool's version.")
    # parser.add_argument("-v", "--verbose", action="store", metavar="LEVEL")

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
        print("Move along...\n")
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


def generate_report_payload(items):
    """Return the report payload."""
    report_payload = []
    # Loop over all Mac computers in Kandji
    for item in items:
        report_payload.append(item)
    return report_payload


def write_report(report_payload, report_name):
    """Write the report."""
    # write report to csv file
    with open(report_name, mode="w", encoding="utf-8") as report:

        out_fields = []

        for item in report_payload:
            for key in item.keys():
                if key not in out_fields:
                    out_fields.append(key)

        # find the serial_number field so that we can sort the report on that.
        def thingy(out_field):
            this = ""
            if out_field == "serial_number":
                this = out_field
            return this

        writer = csv.DictWriter(
            report, fieldnames=sorted(out_fields, key=thingy, reverse=True)
        )

        # Write headers to CSV
        writer.writeheader()

        # Loop over the item list sorted by last_check_in
        for item in report_payload:

            # Write row to csv file
            writer.writerow(item)


def main():
    """Run main logic."""
    # validate vars
    var_validation()
    # Return the arguments
    arguments = program_arguments()

    #  Main logic starts here

    print(f"\nRunning: {SCRIPT_NAME} ...")
    print(f"Version: {__version__}\n")
    print(f"Base URL: {BASE_URL}\n")

    # dict placeholder for params passed to api requests
    params_dict = {}

    # Report name
    if arguments.platform:
        report_name = f"{arguments.platform.lower()}_report_{TODAY}.csv"
        params_dict.update({"platform": f"{arguments.platform}"})
    else:
        report_name = f"devices_report_{TODAY}.csv"

    # Get all device inventory records
    print("Getting device inventory from Kandji...")
    device_inventory = get_devices(params=params_dict)
    print(f"Total records returned: {len(device_inventory)}\n")

    # list to hold all device details
    device_info_list = []

    # Get device details for each device
    for device in device_inventory:

        device_info_list.append(device)

    # Get the app names and app versions from the app details by passing a list of
    # device ids
    report_payload = generate_report_payload(device_info_list)

    print("Generating device report for the following devices ...")
    write_report(report_payload, report_name)

    print("Kandji report complete ...")
    print(f"Kandji report at: {HERE.resolve()}/{report_name} ")


if __name__ == "__main__":
    main()
