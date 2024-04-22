#!/usr/bin/env python3

"""Update device inventory information using a csv input file and the Kandji API."""

################################################################################################
# Created by Matt Wilson | Kandji, Inc | support@kandji.io
################################################################################################
#
#   Created:  2021-06-03
#   Modified: 2024-04-12 - Brian Goldstein
#
################################################################################################
# Software Information
################################################################################################
#
#   This python3 script leverages the Kandji API along using a CSV input file to update
#   one or more device inventory records. Information for both existing enrolled devices
#   and devices awaiting enrollment (aka ADE devices) can be updated using this script.
#
#   The following items can be updated:
#
#       - blueprint assignment
#       - asset tag
#       - user assignment
#
#   See the README in this repo for more information.
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

__version__ = "1.5.1"


# Standard library
import argparse
import csv
import json
import pathlib
import sys

# 3rd party imports

try:
    import requests
except ImportError:
    sys.exit(
        "Looks like you need to install the requests module. Open a Terminal and run "
        "python3 -m pip install requests."
    )

from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

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


def var_validation():
    """Validate variables."""
    if SUBDOMAIN in ["", "accuhive"]:
        print(
            "\nPlease update the SUBDOMAIN varialble with your Kandji tenant subdomain."
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
            "no longer\n"
            '\t\t\t enrolled in Kandji or the device is in the "Awaiting enrollment"\n'
            "\t\t\t state.\n"
        )
    # 422
    elif resp_code == requests.codes["unprocessable"]:
        print(
            "The server understands the content type of the request entity (hence a 415 "
            "Unsupported Media Type status code is inappropriate), and the syntax of "
            "the request entity is correct (thus a 400 Bad Request status code is "
            "inappropriate) but was unable to process the contained instructions. For "
            "example, this error condition may occur if a JSON request body contains "
            "well-formed (i.e., syntactically correct), but semantically erroneous, "
            "JSON instructions."
        )
    # 429
    elif resp_code == requests.codes["too_many_requests"]:
        print("You have reached the rate limit ...")
        print("Try again later ...")
        sys.exit(f"\t{err_msg}")
    # 500
    elif resp_code == requests.codes["internal_server_error"]:
        print(
            "The server encountered an unexpected condition that prevented it from "
            "fulfilling the request...."
        )
        print(err_msg)
    # 502
    elif resp_code == requests.codes["bad_gateway"]:
        print(
            "The server, while acting as a gateway or proxy, received an invalid "
            "response from an inbound server it accessed while attempting to fulfill "
            "the request."
        )
    # 503
    elif resp_code == requests.codes["service_unavailable"]:
        print("Unable to reach the service. Try again later...")
        sys.exit()
    else:
        print("Something really bad must have happened...")
        print(err_msg)


def kandji_api(method, endpoint, params=None, payload=None):
    """Make an API request and return data.

    method   - an HTTP Method (GET, POST, PATCH, DELETE).
    endpoint - the API URL endpoint to target.
    params   - optional parameters can be passed as a dict.
    payload  - optional payload is passed as a dict and used with PATCH and POST
               methods.
    Returns a JSON data object.
    """
    retries = Retry(
        total=3,
        backoff_factor=0.3,
        allowed_methods=["GET", "PUT", "POST", "DELETE"],
        status_forcelist=[500, 502, 503, 504],
    )
    attom_adapter = HTTPAdapter(max_retries=retries)
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


def get_ade_devices():
    """Return ADE device records."""
    # inventory
    data = []

    # set starting page number for pagination
    page = 1

    while True:
        params = {"page": f"{page}"}

        # check to see if a platform was specified
        response = kandji_api(
            method="GET",
            endpoint="/v1/integrations/apple/ade/devices",
            params=params,
        )

        # append results to the data list
        data += response.get("results")

        if response.get("next") is None:
            break  # no more pages to return

        page += 1

    if len(data) < 1:
        print("No ADE devices found...\n")
        sys.exit()

    return data


def get_blueprint(bp_name):
    """Return blueprint records containing the provided name."""
    bp_record = kandji_api(
        method="GET",
        endpoint="/v1/blueprints",
        params={"name": f"{bp_name}"},
    )

    if bp_record["count"] == 0:
        bp_record = ""  # return empty blueprint record

    elif bp_record["count"] == 1 and bp_name == bp_record.get("results")[0]["name"]:
        bp_record = bp_record["results"][0]

    else:
        print(
            f'More than one blueprint was returned containing "{bp_name}". Will '
            "look through the results for an exact match."
        )

        for record in bp_record["results"]:
            print(f"\t{record.get('name')}")

        count = 0

        total_bp_count = bp_record["count"]

        for record in bp_record["results"]:
            if bp_name == record["name"]:
                bp_record = record
                break

            count += 1

            if count == total_bp_count:
                bp_record = ""  # return empty blueprint record

    return bp_record


def create_record_update_payload(_input, enrollment_status):
    """Dynamically build the device update payload.

    This function looks at the device record information passed from the input file and
    looks to see which keys are populated. The JSON payload does not include empty
    keys.
    """
    payload = {}

    for key, value in _input.items():
        # just in case there are any leading or trailing spaces in the headers.
        key = key.strip()

        # Here we are checking to see if we need to lookup the blueprint id in Kandji
        # based on the name provided in the input file.
        if key == "blueprint_name" and value != "":
            # API call to return blueprint records containing the provided name.
            blueprint_record = get_blueprint(bp_name=value)

            if blueprint_record:
                # update the payload with the blueprint id
                if enrollment_status == "enrolled":
                    # enrolled device
                    payload.update([("blueprint_id", blueprint_record["id"])])
                else:
                    # device awaiting enrollment
                    payload.update([("blueprint", blueprint_record["id"])])
            else:
                print(
                    f'"{value}" not found in Kandji. Will not '
                    "attempt to update blueprint assignemnt. If the blueprint does "
                    "exist, make sure that the name is entered correctly in the input "
                    "csv."
                )

        # Here we are verifying that the value in the device record is not null or empty.
        # If the value is null, we will clear the user or asset tag on the device record.
        # We want to check for empty values because the user, and asset_tag keys cannot 
        # be empty strings in the in json payload sent to Kandji. If these keys are sent
        # as an empty string Kandji will return an error.
        if value != "" and key in ["asset_tag", "user"]:
            payload.update([(key, value)])
        if value == "null" and key in ["asset_tag", "user"]:
            value = None
            payload.update([(key, value)])
    return payload

    return payload


def update_device_record(device, enrollment_status, payload):
    """Update a device record in Kandji."""
    if enrollment_status == "enrolled":
        kandji_api(
            method="PATCH",
            endpoint=f"/v1/devices/{device['device_id']}",
            params=None,
            payload=payload,
        )

    # updated ade device record
    else:
        kandji_api(
            method="PATCH",
            endpoint=f"/v1/integrations/apple/ade/devices/{device['id']}",
            params=None,
            payload=payload,
        )

    print("Device updated!")


def main():
    """Run main logic."""
    var_validation()
    arguments = program_arguments()

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
            print("Checking file for duplicate serial_number entries...")
            template_data = remove_duplicates(template_data, "serial_number")
            print(
                f"Total unique serial_numbers in the input file: "
                f"{len(template_data)}"
            )

        except FileNotFoundError as err:
            print(f"There was an issue loading {arguments.template}...")
            print(
                "Make sure that the file name is accurate and that it exists at the"
                "sprecified path before trying again..."
            )
            sys.exit(err)

    for device in template_data:
        print("")
        print(f"Looking for {device['serial_number']} in Kandji...")

        # look for device in kandji
        kandji_device = kandji_api(
            method="GET",
            endpoint="/v1/devices",
            params={"serial_number": f"{device['serial_number']}"},
        )

        # device found in enrolled devices
        if (
            isinstance(kandji_device, list)
            and kandji_device
            and len(kandji_device) == 1
        ):
            kandji_device = kandji_device[0]

            if (
                device["serial_number"].lower()
                == kandji_device["serial_number"].lower()
            ):
                print("Found device in enrolled devices.")

                enrollment_status = "enrolled"

        # look for device in devices awaiting enrollment
        else:
            for ade_device in get_ade_devices():
                if (
                    device["serial_number"].lower()
                    == ade_device["serial_number"].lower()
                ):
                    print("Found in devices awaiting enrollment.")
                    kandji_device = ade_device
                    enrollment_status = "awaiting_enrollment"

        # if the device record is not found in the tenant
        if not kandji_device:
            print(
                f"Unable to find {device.get('serial_number')} in Kandji. Ensure that "
                "the serial number is entered in the csv file correctly. If this is an "
                "ADE device, ensure that it is assigned to this Kandji tenant in AxM."
            )

        if kandji_device:
            # Build the payload
            payload = create_record_update_payload(
                _input=device, enrollment_status=enrollment_status
            )

            if payload:
                payload = json.dumps(payload)

                print("Attempting to update device record...")
                print(f"Request payload: {json.dumps(payload)}")

                update_device_record(
                    device=kandji_device,
                    enrollment_status=enrollment_status,
                    payload=payload,
                )

            else:
                print("Payload is empty. Will not attempt to update the device record.")

    print()
    print("Finished ...")


if __name__ == "__main__":
    main()
