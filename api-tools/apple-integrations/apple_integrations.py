#!/usr/bin/env python3

"""Interact with Apple integrations in Kandji."""

########################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
########################################################################################
# Created - 2022-07-08
########################################################################################
# Software Information
########################################################################################
#
# This script is used to work with ADE integrations in a Kandji tenant.
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
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CNNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
########################################################################################

__version__ = "0.0.1"


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
REGION = "us"  # us and eu - this can be found in the Kandji settings on the Access tab

# Kandji Bearer Token
TOKEN = "your_api_key_here"

########################################################################################
######################### DO NOT MODIFY BELOW THIS LINE ################################
########################################################################################

# Initialize some variables
# Kandji API base URL
BASE_URL = f"https://{SUBDOMAIN}.clients.{REGION}-1.kandji.io/api"

SCRIPT_NAME = "Apple integrations"
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
        prog="apple_integrations.py",
        description=(
            'Interact with Apple Integrations in a Kandji tenant. Use "--help" to see '
            "the able options."
        ),
        allow_abbrev=False,
    )

    # add grouped arguments that cannot be called together
    group_actions = parser.add_mutually_exclusive_group()

    group_actions.add_argument(
        "--public-key",
        action="store_true",
        help="Download the public key to use when adding MDM servers to ABM. The "
        "encoded information will be saved to a file on the Desktop with the .pem "
        " format. This file must be uploaded to ABM manually.",
        required=False,
    )

    group_actions.add_argument(
        "--ade-tokens",
        action="store_true",
        help="List information about the ADE integrations in a Kandji tenant.",
        required=False,
    )

    parser.add_argument(
        "--list-devices",
        type=str,
        metavar='"1411be7d-5e91-439f-8d93-2f5667c60d42"',
        help="List the devices associated with a given ADE token ID. You can use the"
        ' "--ade-tokens" option to get a list of available ADE token IDs.',
        required=False,
    )

    parser.version = __version__
    parser.add_argument("--version", action="version", help="Show this tool's version.")

    args = vars(parser.parse_args())
    if not any(args.values()):
        print()
        parser.error("No command options given. Use the --help flag for more details\n")

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


def download_public_key():
    """Download ADE public key."""
    # check to see if a platform was sprecified
    return kandji_api(method="GET", endpoint="/v1/integrations/apple/ade/public_key/")


def list_devices_associated_to_ade_token(ade_token, params=None):
    """Return list of ADE integrations."""
    # page - which page to return
    page = 1

    # ade devices
    data = []

    while True:
        params = {"page": f"{page}"}

        # check to see if a platform was sprecified
        response = kandji_api(
            method="GET",
            endpoint=f"/v1/integrations/apple/ade/{ade_token}/devices",
            params=params,
        )

        # breakout the response then append to the data list
        for record in response["results"]:
            data.append(record)

        if response["next"] is None:
            if len(data) < 1:
                print("No devices found...\n")
            break

        page += 1

    return data


def flatten(input_dict, separator=".", prefix=""):
    """Flatten JSON"""
    output_dict = {}

    for key, value in input_dict.items():

        if isinstance(value, dict) and value:

            deeper = flatten(value, separator, prefix + key + separator)
            output_dict.update({key2: val2 for key2, val2 in deeper.items()})

        elif isinstance(value, list) and value:

            for index, sublist in enumerate(value, start=1):

                if isinstance(sublist, dict) and sublist:

                    deeper = flatten(
                        sublist,
                        separator,
                        prefix + key + separator + str(index) + separator,
                    )

                    output_dict.update({key2: val2 for key2, val2 in deeper.items()})

                else:
                    output_dict[prefix + key + separator + str(index)] = value

        else:
            output_dict[prefix + key] = value

    return output_dict


def generate_report_payload(input_):
    """Create a JSON payload."""
    report_payload = []

    for attr in input_:

        # flattend = flatten_dictionary(dict_=attr)
        flattend = flatten(attr)

        report_payload.append(flattend)

    return report_payload


def write_report(input_, report_name):
    """Write report."""
    # write report to csv file
    with open(report_name, mode="w", encoding="utf-8") as report:

        out_fields = []

        # automatically loop over keys in the payload to pullout header fields
        for item in input_:
            for key in item.keys():
                if key not in out_fields:
                    out_fields.append(key)

        writer = csv.DictWriter(report, fieldnames=out_fields)

        # Write headers to CSV
        writer.writeheader()

        # Loop over the list sorted by serial_number
        for item in input_:
            writer.writerow(item)


def report_builder(input_, name_items):
    """Build report."""
    report_payload = generate_report_payload(input_=input_)

    # build report name
    if name_items:
        report_name = "_".join(name_items)
        report_name = f"{report_name}_report_{TODAY}.csv"
    else:
        report_name = f"apple_integrations_report_{TODAY}.csv"

    print("Generating report ...")
    write_report(input_=report_payload, report_name=report_name)

    print("Kandji report complete ...")
    print(f"Kandji report at: {HERE.resolve()}/{report_name} ")


def main():
    """Run main logic."""
    # validate vars
    var_validation()

    # Return the arguments
    arguments = program_arguments()

    print(f"\nVersion: {__version__}")
    print(f"Base URL: {BASE_URL}\n")

    # hold items used in report name
    report_name_items = []

    if arguments.public_key:
        # Get all device inventory records
        print("Getting ADE public key from Kandji...")
        print(
            "Copy the key below from '-----BEGIN CERTIFICATE-----' to "
            "'-----END CERTIFICATE-----' into a text file and save as '.pem' format."
        )
        print(
            "Once the file is created, upload it your ABM console when adding a new "
            "MDM server.\n"
        )
        public_key = download_public_key()
        print(public_key)

    if arguments.ade_tokens:
        # Get all device inventory records
        print("Getting ade integrations list from Kandji...")
        ade_integrations = kandji_api(
            method="GET", endpoint="/v1/integrations/apple/ade"
        )

        print("Getting token IDs...")
        count = 1
        for record in ade_integrations["results"]:

            print("")
            print(f"Token {count}:")
            print("  |")
            print(f"  +-- Token ID: {record['id']}")
            print(f"  +-- Server name: {record['server_name']}")
            print(f"  +-- Total devices: {record['device_counts']['total']}")
            print(f"  +-- Last sync: {record['last_device_sync']}")
            print(f"  +-- Expiration date: {record['access_token_expiry']}")
            print(f"  +-- Days left: {record['days_left']}")
            print(f"  +-- Default blueprint: {record['blueprint']['name']}")
            print("")
            count += 1

        # sys.exit()
        #
        # report_data = ade_integrations
        # report_name_items.append("token_list")
        # report_builder(input_=report_data, name_items=report_name_items)

    if arguments.list_devices:
        print(f'Getting devices associated with token ID "{arguments.list_devices}"...')
        report_data = list_devices_associated_to_ade_token(
            ade_token=arguments.list_devices
        )
        print(f"Total records: {len(report_data)}\n")

        print("Model \t\t\t\t Serial Number")
        print("----------------------------------------------")

        for record in report_data:
            print(
                f'{record["model"]} {(31 - len(record["model"]))*"."} '
                f'{record["serial_number"]}'
            )

        print("")
        report_name_items.append(arguments.list_devices)
        report_builder(input_=report_data, name_items=report_name_items)


if __name__ == "__main__":
    main()
