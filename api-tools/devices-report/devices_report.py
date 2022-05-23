#!/usr/bin/env python3

"""Returns a basic device report from the GET devices API."""

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
# Created on 09/22/2021
# Updated on 05/12/2022
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.3.1
#   11.6.5
#
###################################################################################################
# Software Information
###################################################################################################
#
#   This script is used to generate a basic device report based on the GET Devices API endpoint for
#   all devices in a Kandji tenant.
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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
###################################################################################################

__version__ = "1.0.0"


# Standard library
import argparse
import csv
import pathlib
import sys

from datetime import datetime

# 3rd party imports

# Try to import the module. If the module cannot be imported let the user know so that they can
# install it.
try:
    import requests
except ImportError as import_error:
    sys.exit(
        "Looks like you need to install the requests module. Open a Terminal and run python3 -m "
        "pip install requests."
    )

from requests.adapters import HTTPAdapter

###################################################################################################
######################### UPDATE VARIABLES BELOW ##################################################
###################################################################################################


# Initialize some variables
# Kandji API base URL
BASE_URL = "https://example.clients.us-1.kandji.io/api/v1/"
# Kandji Bearer Token
TOKEN = "your_api_key_here"


###################################################################################################
######################### DO NOT MODIFY BELOW THIS LINE ###########################################
###################################################################################################

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


def program_arguments():
    """Return arguments."""
    parser = argparse.ArgumentParser(
        prog="device_report.py",
        description=(
            "This tool is used to generate a device report based on the GET Devices API "
            "endpoint for all devices in a Kandji tenant..."
        ),
        allow_abbrev=False,
    )

    parser.add_argument(
        "--platform",
        type=str,
        metavar='"Mac"',
        help="Enter a specific device platform type. This will limit the search results to only"
        " the specified platfrom. Examples: Mac, iPhone, iPad, AppleTV.",
        required=False,
    )

    parser.version = __version__
    parser.add_argument("--version", action="version", help="Show this tool's version.")
    # parser.add_argument("-v", "--verbose", action="store", metavar="LEVEL")

    return parser.parse_args()


def error_handling(resp, err_msg):
    """Handle the HTTP errors."""
    # 400
    if resp == requests.codes["bad_request"]:
        print("This request does not look right...")
        print(f"\t{err_msg}")
    # 401
    elif resp == requests.codes["unauthorized"]:
        print("Make sure that you have the required permissions to access this data.")
        print("Depending on the API platform this could mean that access has just been blocked.")
        sys.exit(f"\t{err_msg}")
    # 403
    elif resp == requests.codes["forbidden"]:
        print("The api key may be invalid or missing.")
        sys.exit(f"\t{err_msg}")
    # 404
    elif resp == requests.codes["not_found"]:
        print("We cannot find the one that you are looking for ...")
        print("Move along ...")
        print(f"\t{err_msg}")
    # 429
    elif resp == requests.codes["too_many_requests"]:
        print("You have reached the rate limit ...")
        print("Try again later ...")
        sys.exit(f"\t{err_msg}")
    # 500
    elif resp == requests.codes["internal_server_error"]:
        print("The service is having a problem...")
        sys.exit(err_msg)
    # 503
    elif resp == requests.codes["service_unavailable"]:
        print("Unable to reach the service. Try again later...")
    else:
        print("Something really bad must have happened...")
        print(err_msg)
        sys.exit()


def kandji_api(method, endpoint, params=None, payload=None):
    """Make an API request and return data.

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
            data = response.json()
        # if the request is successful exeptions will not be raised
        response.raise_for_status()

    except requests.exceptions.RequestException as err:
        error_handling(resp=response.status_code, err_msg=err)
        data = "Not found"

    return data


def get_device_inventory(args):
    """Return device inventory."""
    # check to see if a platform was sprecified
    if args.platform:
        device_inventory = kandji_api(
            method="GET",
            endpoint="devices",
            params={"limit": "100000", "platform": f"{args.platform}"},
        )

        if len(device_inventory) < 1:
            print(f"No {args.platform} devices found...\n")
            sys.exit()

    else:
        device_inventory = kandji_api(method="GET", endpoint="devices", params={"limit": "100000"})

    return device_inventory


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

        writer = csv.DictWriter(report, fieldnames=sorted(out_fields, key=thingy, reverse=True))

        # Write headers to CSV
        writer.writeheader()

        # Loop over the item list sorted by last_check_in
        for item in report_payload:

            # Write row to csv file
            writer.writerow(item)


def main():
    """Run main logic."""
    # Return the arguments
    arguments = program_arguments()

    #  Main logic starts here

    print(f"\nRunning: {SCRIPT_NAME} ...")
    print(f"Version: {__version__}\n")
    print(f"Base URL: {BASE_URL}\n")

    if "example" in BASE_URL:
        print(f"\tThe subdomain in {BASE_URL} needs to be updated...\n")
        sys.exit()

    if "your_api_key_here" in TOKEN:
        print(f'\tThe TOKEN should not be "{TOKEN}"...\n')
        sys.exit()

    # Report name
    if arguments.platform:
        report_name = f"{arguments.platform.lower()}_report_{TODAY}.csv"
    else:
        report_name = f"devices_report_{TODAY}.csv"

    # Get all device inventory records
    print("Getting all device records from Kandji ...")

    # Get all device inventory records
    device_inventory = get_device_inventory(args=arguments)

    print(f"Total device records: {len(device_inventory)}")

    # list to hold all device details
    device_info_list = []

    # Get device details for each device
    for device in device_inventory:

        device_info_list.append(device)

    # Get the app names and app versions from the app details by passing a list of device ids
    report_payload = generate_report_payload(device_info_list)

    print("Generating device report for the following devices ...")
    write_report(report_payload, report_name)

    print("Kandji device report complete ...")
    print(f"Kandji report at: {HERE.resolve()}/{report_name} ")


if __name__ == "__main__":
    main()
