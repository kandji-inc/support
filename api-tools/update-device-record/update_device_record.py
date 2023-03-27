#!/usr/bin/env python3

"""Update device inventory information using a csv input file and the Kandji API."""

################################################################################################
# Created by Matt Wilson | Kandji, Inc | support@kandji.io
################################################################################################
#
#   Created:  2021-06-03
#   Modified: 2023-02-08 - Matt Wilson
#
################################################################################################
# Software Information
################################################################################################
#
#   This python3 script leverages the Kandji API along using a CSV input file to update
#   one or more device inventory records.
#
#   The following items can be updated:
#
#       - blueprint assignment
#       - asset tag
#       - user assignment
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

__version__ = "1.3.1"


# Standard library
import argparse
import csv
import json
import pathlib
import sys

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
        prog="update_device_record",
        description=(
            "Update device inventory information with a CSV input file and the Kandji "
            "Enterprise API."
        ),
        allow_abbrev=False,
    )

    parser.add_argument(
        "--template",
        type=str,
        metavar='"/path/to/input_template.csv"',
        help="Enter the path to the spreadsheet(csv file) or drag the file into this"
        " Terminal window.",
        required=True,
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
    unique_records = []
    temp_list = []
    for line in data:
        if search_key in line.keys() and line[search_key] != "":
            value = line[search_key].strip()

        if value not in temp_list:
            unique_records.append(line)
            temp_list.append(value)
    return unique_records


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


def create_record_update_payload(_input):
    """Dynamically build the device update payload.

    This function looks at the device record information passed from the input file and
    looks to see which keys are populated. The JSON payload does not include empty
    keys.
    """
    payload = {}

    for key, value in _input.items():
        # Here we are checking to see if we need to lookup the blueprint id in Kandji
        # based on the name provided in the input file.
        if key == "blueprint_name" and value != "":
            print(f"Looking for \"{_input['blueprint_name']}\" blueprint ...")
            # API call to return blueprint records containing the provided name.
            blueprint_record = kandji_api(
                method="GET",
                endpoint="/v1/blueprints",
                params={"name": f"{_input['blueprint_name']}"},
            )

            if blueprint_record["count"] == 0:
                print(f"WARNING: {_input['blueprint_name']} not found...")
                print("WARNING: Check the name and try again...")
                break

            # Loop over the key value pairs returned in the result
            for record in blueprint_record["results"]:
                # ensure that the name returned matches the name we are looking for
                # exactly.
                if _input["blueprint_name"] == record["name"]:
                    # update the payload with the found blueprint id
                    payload.update([("blueprint_id", record["id"])])

        # Here we are verifying that the value in the device record is not empty and
        # that it is not the serial_number. We want to check for empty values because
        # the user, and asset_tag keys cannot be empty in the in json payload sent to
        # Kandji. If these keys are sent as empty or NULL Kandji will return an error.
        if value != "" and key not in ["blueprint_name", "serial_number", "username"]:
            payload.update([(key, value)])

    return json.dumps(payload)


def main():
    """Run main logic."""
    arguments = program_arguments()
    var_validation()

    print(f"\nVersion: {__version__}")
    print(f"Base URL: {BASE_URL}\n")

    # Validate program arguments
    if arguments.template:
        # Try to load the contents of the csv file.
        # If unable to do so let the user know by presenting the error.
        try:
            template_data = load_input_file(arguments.template)
            print(f"Found input file: {pathlib.Path(arguments.template)}")
            # Make sure that any duplicate serial numbers are removed from the list of
            # device records that need to be updated.
            print("Checking the input file for duplicate serial_number entries...")
            template_data = remove_duplicates(template_data, "serial_number")
            print(
                f"Total unique serial_numbers in the input file: "
                f"{len(template_data)}"
            )

        except FileNotFoundError as err:
            print(f"There was an issue loading {arguments.template}...")
            print(
                "Make sure that the file exists at the sprecified path before trying "
                "again..."
            )
            sys.exit(err)

    for device in template_data:
        print("")
        print(f"Looking for {device['serial_number']} ...")
        # device record returned from kandji
        device_record = kandji_api(
            method="GET",
            endpoint="/v1/devices",
            params={"serial_number": f"{device['serial_number']}"},
        )

        if len(device_record) < 1:
            print(f"WARNING: {device['serial_number']} not found...")
            break

        for attribute in device_record:
            if device["serial_number"].upper() == attribute["serial_number"].upper():
                print("Building request payload ...")
                # Build the payload
                payload = create_record_update_payload(input_record=device)
                if len(payload) < 3:
                    print("WARNING: Will not attempt to update record...")
                    break
                print(f"Request payload: {payload}")
                print("Attempting to update device record...")
                # Update the device inventory records found in the input
                kandji_api(
                    method="PATCH",
                    endpoint=f"/v1/devices/{attribute['device_id']}",
                    params=None,
                    payload=payload,
                )
    print()
    print("Finished ...")


if __name__ == "__main__":
    main()
