#!/usr/bin/env python3

"""Returns returns parameters IDs assigned to blueprints in Kandji."""

########################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
########################################################################################
# Created on 2022-02-18
# Updated on 2022-09-01
########################################################################################
# Software Information
########################################################################################
#
#   This script will generate a list of parameter IDs found in a blueprint.
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

__version__ = "0.0.2"


# Standard library
import sys

try:
    import requests
except ImportError as import_error:
    print(import_error)
    sys.exit(
        "Looks like you need to install the requests module. Open a Terminal and run  "
        "python3 -m pip install requests."
    )

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
if REGION == "us":
    BASE_URL = f"https://{SUBDOMAIN}.clients.{REGION}-1.kandji.io/api"
else:
    BASE_URL = f"https://{SUBDOMAIN}.clients.{REGION}.kandji.io/api"

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}


def var_validation():
    """Validate variables."""
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


def get_all_blueprints():
    """Return a list of enrolled devices."""
    # The API endpont to target
    endpoint = "/v1/blueprints"
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
                    "Check to make sure that the API token has the proper permissions "
                    "to access the devices endpoint ..."
                )
                sys.exit(f"\t{error}")

            if attempt == 5:
                print(error)
                print("Made 5 attempts ...")
                print("Exiting ...")

    return data


def main():
    """Run main logic."""
    # validate vars
    var_validation()

    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # Get all blueprints
    blueprint_data = get_all_blueprints()
    blueprint_list = blueprint_data["results"]

    print(f"Total blueprints: {len(blueprint_list)}")

    # loop over the bluprints returned in the results
    for blueprint in blueprint_list:
        # check to see if the params list is populated before going further
        if blueprint["params"]:

            print()
            print(f"Blueprint name: {blueprint['name']}")
            print(f"\tAssigned macOS devices: {blueprint['computers_count']}")

            # loop over each parameter found in the blueprint
            for param in blueprint["params"]:

                # print the param id
                print(f"\tParameter ID: {param}")


if __name__ == "__main__":
    main()
