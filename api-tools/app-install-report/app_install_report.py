#!/usr/bin/env python3

"""app_install_report.py
Return a report of all apps, app versions, number of installationss, device name, and serial
numbers where the, app is installed from a specified Kondji instance.
"""

###################################################################################################
# Created by Matt Wilson | Senior Solutions Engineer | Kandji, Inc | Solutions | se@kandji.io
###################################################################################################
#
# Created:  2021.06.03
# Modified: 2021.09.16
#
###################################################################################################
# Software Information
###################################################################################################
#
# This python3 script leverages the Kandji API to generate a CSV report containing a list of every
# installed application recorded by the Kandji Web App. The information includes application name,
# the application version, the device name, and the device serial numbers.
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2021 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
###################################################################################################

__version__ = "1.1.1"


# Standard library
import csv
from datetime import datetime
import pathlib
import sys

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


###################################################################################################
######################### UPDATE VARIABLES BELOW ##################################################
###################################################################################################


# Initialize some variables
# Kandji API base URL
BASE_URL = "https://example.clients.us-1.kandji.io/api/v1/"
# Kandji Bearer Token
TOKEN = "api_token_here"


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
REPORT_NAME = f"app_install_report_{datetime.today().strftime('%Y%m%d')}.csv"

# Current working directory
HERE = pathlib.Path("__file__").parent


def get_all_devices():
    """Retrive all device inventory records from Kandji"""

    # The API endpont to target
    endpoint = "devices/?limit=10000"

    # Initiate var that will be returned
    data = None

    attempt = 0
    response_code = None

    while response_code is not requests.codes["ok"] and attempt < 6:

        try:
            # Make the api call to Kandji
            response = requests.get(BASE_URL + endpoint, headers=HEADERS, timeout=30)

            # Store the HTTP status code
            response_code = response.status_code

            if response_code == requests.codes["ok"]:
                # HTTP Code 200 (successfull)
                data = response.json()
                break

            # An error occurred so we need to report it
            response.raise_for_status()

        except requests.exceptions.RequestException as error:
            attempt += 1

            if requests.codes["unauthorized"]:
                # if HTTPS 401
                print(
                    "Check to make sure that the API token has the proper permissions to access the"
                    " Application list ..."
                )
                sys.exit(f"\t{error}")

            if attempt == 5:
                print(error)
                print("Made 5 attempts ...")
                print("Exiting ...")

    return data


def get_device_apps(device_id):
    """Return all application details for a specific device id."""

    # The API endpont to target
    endpoint = f"devices/{device_id}/apps"

    # Initiate var that will be returned
    data = None

    try:

        # Make the api call to Kandji
        response = requests.get(BASE_URL + endpoint, headers=HEADERS, timeout=30)

        # Store the HTTP status code
        response_status = response.status_code

        if response_status == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:

        if requests.codes["unauthorized"]:
            # if HTTPS 401
            print(
                "Check to make sure that the API token has the proper permissions to access the"
                " Application list ..."
            )
            sys.exit(f"\t{error}")

        sys.exit(f"{error}")

    return data


def create_report_payload(devices):
    """Create a JSON payload"""

    # list of apps
    data = []

    # Loop over all Mac computers in Kandji
    for device in devices:
        device_apps = get_device_apps(device["device_id"])

        # Loop over each app in the Kandji "apps" list and append to data dict
        for app in device_apps["apps"]:
            # Create a dictionary containing the application name, version, and
            # associated serial number.
            apps_dict = {
                "device_name": device["device_name"],
                "serial_number": device["serial_number"],
                "platform": device["platform"],
                "app_name": app["app_name"],
                "version": app["version"],
            }

            data.append(apps_dict)

    return data


def write_report(app_list):
    """Write app report"""

    # write report to csv file
    with open(REPORT_NAME, mode="w", encoding="utf-8") as report:
        out_fields = ["Device name", "Serial number", "Platform", "App name", "Version"]
        writer = csv.DictWriter(report, fieldnames=out_fields)

        # Write headers to CSV
        writer.writeheader()

        # Loop over the app list sorted by app_name
        for app in sorted(app_list, key=lambda k: k["app_name"]):

            # Write row to csv file
            writer.writerow(
                {
                    "Device name": app["device_name"],
                    "Serial number": app["serial_number"].upper(),
                    "Platform": app["platform"],
                    "App name": app["app_name"],
                    "Version": app["version"],
                }
            )


def main():
    """Run main logic"""

    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # Get all device inventory records
    kandji_device_inventory = get_all_devices()

    print(f"Total device records: {len(kandji_device_inventory)}")

    # A list of dictionaries containing device ids and their serial numbers
    device_list = [
        {
            "device_id": device["device_id"],
            "device_name": device["device_name"],
            "serial_number": device["serial_number"],
            "platform": device["platform"],
        }
        for device in kandji_device_inventory
    ]

    # create the report payload
    report_payload = create_report_payload(device_list)

    print("Generating Kandji app install report ...")
    write_report(report_payload)

    print("Kandji app report complete ...")
    print(f"Kandji app report at: {HERE.resolve()}/{REPORT_NAME} ")


if __name__ == "__main__":
    main()
