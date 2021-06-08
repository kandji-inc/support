#!/usr/bin/env python3

"""kandji_update_device_record.py
Update device inventory information with a csv input file and the Kandji Enterprise API.
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
# This python3 script leverages the Kandji API along with a CSV input file to update one or more
# device inventory records.
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
import argparse
import csv
import json
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

# Current working directory
HERE = pathlib.Path("__file__").parent


def program_arguments():
    """Return arguments"""

    parser = argparse.ArgumentParser(
        prog="kandji_update_device_record",
        description=(
            "Update device inventory information with a CSV input file and the Kandji Enterprise "
            "API."
        ),
        allow_abbrev=False,
    )

    parser.add_argument(
        "--input-file",
        type=str,
        metavar='"/path/to/input_template.csv"',
        help="Enter the path to the spreadsheet(csv file) or drag the file into this"
        " Terminal window.",
        required=True,
    )

    parser.version = __version__
    parser.add_argument("--version", action="version", help="Show this tool's version.")
    # parser.add_argument("-v", "--verbose", action="store", metavar="LEVEL")

    return parser.parse_args()


def load_input_file(input_file):
    """Load the CSV file for processing"""
    data = []
    with open(input_file, mode="r") as csv_file:
        reader = csv.DictReader(csv_file)
        for line in reader:
            data.append(line)
    return data


def remove_duplicates(data, search_key):
    """Parse the input file received and only return unique entries back as a list based on the
    search_key provided.

    Args:
        data: JSON data returned from input file.
        search_key: Column in the file where we want to look for duplicate entries.
                    Example: serial_number.
    Return: list of unique values
    """
    print(f"Checking the input file for duplicate {search_key} entries ...")
    unique_records = []
    temp_list = []

    for line in data:

        if search_key in line.keys() and line[search_key] != "":
            value = line[search_key].strip()

        if value not in temp_list:
            unique_records.append(line)
            temp_list.append(value)

    print(f"Total unique {search_key}s in the input file: {len(unique_records)}")

    return unique_records


def get_all_devices():
    """Retrive all device inventory records from Kandji"""

    # The API endpont to target
    endpoint = "devices/?limit='10000'"

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


def generate_device_update_payload(input_record):
    """Dynamically build the device update payload

    This function looks at the device record information passed from the input file and looks to
    see which keys are populated. The JSON payload does not include empty keys."""

    payload = {}

    for key, value in input_record.items():
        # Here we are verifying that the value in the device record is not empty and that it is
        # not the serial_number. We want to check for empty values because the blueprint_id, user,
        # and asset_tag keys cannot be empty in the in the json payload sent to Kandji. If these
        # keys are sent as empty or NULL Kandji will return an error.
        if value != "" and key not in ["serial_number", "blueprint_name", "username"]:
            payload.update([(key, value)])

    return json.dumps(payload)


def update_device_inventory_record(payload, device_id):
    """Update information about a device, such as the assigned blueprint, user, and Asset Tag."""

    attempt = 0
    response_code = None

    while response_code is not requests.codes["ok"] and attempt < 6:

        try:
            response = requests.patch(
                BASE_URL + f"devices/{device_id}/",
                headers=HEADERS,
                data=payload,
                timeout=30,
            )

            # Store the HTTP status code
            response_code = response.status_code

            if response_code is requests.codes["ok"]:
                # HTTP Code 200 (successfull)
                print("Device record updated ...")

            else:
                # An error occured that we need to report
                response.raise_for_status()

        except requests.exceptions.RequestException as error:
            print(f"Error: {error}")
            attempt += 1
            if attempt == 5:
                print("Failed to update device ...")


def main():
    """Run main logic"""

    # Return the arguments
    arguments = program_arguments()

    # Validate program arguments

    if arguments.input_file:
        # Try to load the contents of the csv file.
        # If unable to do so let the user know by presenting the error.
        try:
            input_file_data = load_input_file(arguments.input_file)
            print(f"Found: {pathlib.Path(arguments.input_file)}")

            # Make sure that any duplicate serial numbers are removed from the list of device
            # records that need to be updated.
            input_file_data = remove_duplicates(input_file_data, "serial_number")

        except FileNotFoundError as error:
            print(f"There was an issue loading {arguments.input_file} ...")
            print(
                "Make sure that the file exists at the sprecified path before trying again ..."
            )
            sys.exit(error)

    #  Main logic starts here

    print("\nRunning Kandji Device Record Update ...")
    print(f"Version: {__version__}\n")
    print(f"Base URL: {BASE_URL}\n")

    # Get all device inventory records
    kandji_device_inventory = get_all_devices()

    # Hold any serial numbers that could not be found so that we can let the user know to check on
    # these.
    not_found = []

    for device in input_file_data:

        for record in kandji_device_inventory:

            if device["serial_number"] == record["serial_number"]:
                print(f"Attempting to update record for {device['serial_number']} ...")

                # Build the payload
                payload = generate_device_update_payload(input_record=device)

                print(f"Created JSON Payload: {payload} ...")

                # Call the Kandji API to update the device inventory records found in the input
                # file
                update_device_inventory_record(payload, record["device_id"])

                break

            # If the device could not be found in Kandji update the list so that we can
            # display a report to the user once the script completes.
            if device["serial_number"] not in not_found:
                not_found.append(device["serial_number"])

    print()

    # If the list contains any items, we want to display those items to the end-user.
    # In this case we want to display any serial numbers in the input file that could
    # not be found in Kandji
    if len(not_found) > 0:
        print("Device serial numbers not found in Kandji:")
        for device in not_found:
            print(device)

    print("\nFinished ...")


if __name__ == "__main__":
    main()
