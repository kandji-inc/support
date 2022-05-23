#!/usr/bin/env python3

"""Update device inventory information using a csv input file and the Kandji API."""

###################################################################################################
# Created by Matt Wilson | Kandji, Inc | support@kandji.io
###################################################################################################
#
#   Created:  2021-06-03
#   Modified: 2021-08-18 - Matt Wilson
#   Modified: 2022-04-13 - Matt Wilson
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   - 12.3.1
#   - 11.6.5
#   - 10.15.7
#
###################################################################################################
# Software Information
###################################################################################################
#
#   This python3 script leverages the Kandji API along using a CSV input file to update one or more
#   device inventory records.
#
#   The following items can be updated:
#
#       - blueprint assignment
#       - asset tag
#       - user assignment
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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

__version__ = "1.1.0"


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
    """Return arguments."""
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
    """Load the CSV file for processing."""
    data = []
    with open(input_file, mode="r", encoding="utf-8-sig") as csv_file:
        reader = csv.DictReader(csv_file)
        for line in reader:
            data.append(line)
    return data


def remove_duplicates(data, search_key):
    """Remove duplicate entries.

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


def error_handling(resp, err_msg):
    """Handle the HTTP errors."""
    if resp == requests.codes["too_many_requests"]:
        print("You have reached the rate limit ...")
        print("Try again later ...")
        sys.exit(f"\t{err_msg}")

    if resp == requests.codes["not_found"]:
        print("We cannot find the one that you are looking for ...")
        print("Move along ...")

    if resp == requests.codes["unauthorized"]:
        # if HTTPS 401
        print("Check to make sure that the API token has the required permissions.")
        sys.exit(f"\t{err_msg}")


def kandji_api(method, endpoint, params=None, payload=None):
    """Make an API request and return data.

    Returns a JSON data object
    """
    data = None

    attempt = 0
    response_code = None

    while attempt < 6:

        try:
            # Make the api call to Kandji
            response = requests.request(
                method,
                BASE_URL + endpoint,
                params=params,
                data=payload,
                headers=HEADERS,
                timeout=30,
            )

            # Store the HTTP status code
            response_code = response.status_code

            # print(response.url)

            if response_code == requests.codes["ok"]:
                # HTTP Code 200 (successfull)

                if method == "PATCH":
                    print("Record updated!")

                data = response.json()
                break

            if response_code == requests.codes["created"]:
                # HTTP Code 201 (successfull)
                data = response.json()
                break

            if response_code == requests.codes["accepted"]:
                # HTTP Code 202 (successfull)
                data = response.json()
                break

            if response_code == requests.codes["no_content"]:
                # HTTP Code 204 (successfull)
                data = response.json()
                break

            # An error occurred so we need to report it
            response.raise_for_status()

        except requests.exceptions.RequestException as err:
            attempt += 1

            error_handling(resp=response_code, err_msg=err)

            if attempt == 5:
                print(err)
                print("Made 5 attempts ...")
                print("Exiting ...")

    return data


def create_record_update_payload(input_record):
    """Dynamically build the device update payload.

    This function looks at the device record information passed from the input file and looks to
    see which keys are populated. The JSON payload does not include empty keys.
    """
    payload = {}

    for key, value in input_record.items():

        # Here we are checking to see if we need to lookup the blueprint id in Kandji based on the
        # name provided in the input file.
        if key == "blueprint_name" and value != "":

            print(f"Looking for \"{input_record['blueprint_name']}\" blueprint ...")

            # API call to return blueprint records containing the provided name.
            blueprint_record = kandji_api(
                method="GET",
                endpoint="blueprints",
                params={"name": f"{input_record['blueprint_name']}"},
            )

            # Loop over the key value pairs returned in the result
            for record in blueprint_record["results"]:

                # ensure that the name returned matches the name we are looking for exactly.
                if input_record["blueprint_name"] == record["name"]:

                    # print("")
                    # print(blueprint_record)

                    # update the payload with the found blueprint id
                    payload.update([("blueprint_id", record["id"])])

            # sys.exit()

        # Here we are verifying that the value in the device record is not empty and that it is
        # not the serial_number. We want to check for empty values because the user, and asset_tag
        # keys cannot be empty in the in json payload sent to Kandji. If these keys are sent as
        # empty or NULL Kandji will return an error.
        if value != "" and key not in ["blueprint_name", "serial_number", "username"]:
            payload.update([(key, value)])

    return json.dumps(payload)


def main():
    """Run main logic."""
    # Return the arguments
    arguments = program_arguments()

    print("")

    # Validate program arguments

    if arguments.input_file:
        # Try to load the contents of the csv file.
        # If unable to do so let the user know by presenting the error.
        try:
            input_file_data = load_input_file(arguments.input_file)
            print(f"Found input file: {pathlib.Path(arguments.input_file)}")

            # Make sure that any duplicate serial numbers are removed from the list of device
            # records that need to be updated.
            input_file_data = remove_duplicates(input_file_data, "serial_number")

        except FileNotFoundError as err:
            print(f"There was an issue loading {arguments.input_file} ...")
            print("Make sure that the file exists at the sprecified path before trying again ...")
            sys.exit(err)

    #  Main logic starts here

    print("\nRunning Kandji Device Record Update ...")
    print(f"Version: {__version__}\n")
    print(f"Base URL: {BASE_URL}")

    for device in input_file_data:

        print("")
        print(f"Looking for {device['serial_number']} ...")

        # device record returned from kandji
        device_record = kandji_api(
            method="GET",
            endpoint="devices",
            params={"serial_number": f"{device['serial_number']}"},
        )

        # print(device_record)

        for attribute in device_record:

            if device["serial_number"].upper() == attribute["serial_number"].upper():

                print("Building request payload ...")

                # Build the payload
                payload = create_record_update_payload(input_record=device)

                print(f"Request payload: {payload}")
                print("Attempting to update device record...")

                # Update the device inventory records found in the input
                kandji_api(
                    method="PATCH",
                    endpoint=f"devices/{attribute['device_id']}",
                    params=None,
                    payload=payload,
                )

    print()

    print("Finished ...")


if __name__ == "__main__":
    main()
