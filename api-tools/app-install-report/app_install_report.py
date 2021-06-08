#!/usr/bin/env python3

"""kandji_app_install_report.py
Return a report of all apps, app versions, and number of installationss from a
specified Kondji instance.
"""

###################################################################################################
# Created by Matt Wilson | Senior Solutions Engineer
#
# Kandji, Inc | Solutions | se@kandji.io
###################################################################################################
#
# Created: 06/03/2021 Modified:
#
###################################################################################################
# Software Information
###################################################################################################
#
# This python3 script leverages the Kandji API to generate a CSV report containing a list of every
# macOS application recorded by the Kandji Web App. The information includes any application found
# in the Applications directory on a Mac computer, the application version, and the number of Mac
# computers that have a particular version of the app installed.
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

__version__ = "1.0.0"


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
except ImportError as error:
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
TOKEN = "api_token"


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
REPORT_NAME = "app_install_report_" + datetime.today().strftime("%Y%m%d") + ".csv"

# Current working directory
HERE = pathlib.Path("__file__").parent


def get_all_devices():
    """Retrive all device inventory records from Kandji"""

    # The API endpont to target
    endpoint = "devices/?limit='10000'?platform=Mac"

    # Initiate var that will be returned
    data = None

    try:
        # Make the api call to Kandji
        response = requests.get(BASE_URL + endpoint, headers=HEADERS, timeout=10)

        # Store the HTTP status code
        response_code = response.status_code

        if response_code == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()
        else:
            # An error occurred so we need to report it
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        sys.exit(error)

    return data


def get_device_apps(device_id):
    """Return all application details for a specific device id."""

    # The API endpont to target
    endpoint = f"devices/{device_id}/apps"

    # Initiate var that will be returned
    data = None

    # Make the api call to Kandji
    response = requests.get(BASE_URL + endpoint, headers=HEADERS, timeout=10)

    # Store the HTTP status code
    response_status = response.status_code

    if response_status == requests.codes["ok"]:
        # HTTP Code 200 (successfull)
        data = response.json()

    else:
        print("Somthing bad happened ...")
        sys.exit()

    return data


def app_names_versions(devices):
    """Return the app name and app version information from device app info"""

    # List of all apps
    all_apps = []

    # Loop over all Mac computers in Kandji
    for device in devices:
        device_apps = get_device_apps(device["device_id"])

        # Loop over each app in the Kandji "apps" list and append to data dict
        for app in device_apps["apps"]:
            # Create a dictionary containing the application name, version, and
            # associated serial number.
            apps_dict = {
                "app_name": app["app_name"],
                "version": app["version"],
            }

            all_apps.append(apps_dict)

    return all_apps


def return_unique_apps(app_list):
    """Return a list of unique apps and the number of times that app is installed"""

    unique_app_list = []
    install_count = []

    for app in app_list:

        if app not in unique_app_list:

            unique_app_list.append(app)
            install_count.append(
                {
                    "app_name": app["app_name"],
                    "version": app["version"],
                    "install_count": app_list.count(app),
                }
            )

            print(app, app_list.count(app))

    return install_count


def write_report(app_list):
    """Write app report"""

    # write report to csv file
    with open(REPORT_NAME, mode="w", encoding="utf-8") as report:
        out_fields = ["app_name", "version", "install_count"]
        writer = csv.DictWriter(report, fieldnames=out_fields)

        # Write headers to CSV
        writer.writeheader()

        # Loop over the app list sorted by app_name
        for app in sorted(app_list, key=lambda k: k["app_name"]):

            # Write row to csv file
            writer.writerow(
                {
                    "app_name": app["app_name"],
                    "version": app["version"],
                    "install_count": app["install_count"],
                    # "serial_numbers": app["serial_number"],
                }
            )


def main():
    """Run main logic"""

    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # Get all device inventory records
    kandji_device_inventory = get_all_devices()

    # A list of dictionaries containing device ids and their serial numbers
    devices = [
        {"device_id": device["device_id"], "serial_number": device["serial_number"]}
        for device in kandji_device_inventory
    ]

    # Get the app names and app versions from the app details by passing a list of device ids
    app_list = app_names_versions(devices)

    # A list of unique apps and the number of Mac devices they are installed on.
    unique_apps = return_unique_apps(app_list)

    print("Generating Kandji app report ...")
    write_report(unique_apps)

    print("Kandji app report complete ...")
    print(f"Kandji app report at: {HERE.resolve()}/{REPORT_NAME} ")


if __name__ == "__main__":
    main()
