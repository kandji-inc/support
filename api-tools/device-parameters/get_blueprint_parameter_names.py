#!/usr/bin/env python3

"""Returns a list of blueprints with the parameter names contained in those
blueprints."""

########################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
########################################################################################
# Created on 2022-02-18
# Updated on 2022-09-01
########################################################################################
# Software Information
########################################################################################
#
#   This script will generate a list of parameter IDs and associated names found in a
#   blueprint.
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


def return_device_parameter_id_and_name(data):
    """Return assigned device parameter IDs and names."""
    # create a dictionary containing "param_id", "param_name" as key value pairs
    data_dict = {}

    # Get the parameter IDs from the parameters assigned to devices
    for device in data:

        parameters = kandji_api("GET", f"/v1/devices/{device['device_id']}/parameters")

        # if the parameters list is populated
        if parameters["parameters"]:

            for param in parameters["parameters"]:
                # print(f"{param['item_id']} - {param['name']}")
                key_value = {f"{param['item_id']}": f"{param['name']}"}

                if param["item_id"] not in data_dict:
                    # print(f"Adding {key_value} to dictionary")
                    data_dict.update(key_value)

    return data_dict


def main():
    """Run main logic."""
    # validate vars
    var_validation()

    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # dict placeholder for params passed to api requests
    params_dict = {}

    # Get all device inventory records
    print("Getting device inventory from Kandji...")
    device_inventory = get_devices(params=params_dict)
    print(f"Total records returned: {len(device_inventory)}\n")

    # create a dictionary containing "param_id", "param_name" as key value pairs
    print("Checking device records for assigned parameters...")
    device_params_dict = return_device_parameter_id_and_name(data=device_inventory)

    # Get all blueprints
    print("Getting blueprints from Kandji...")
    blueprint_results = kandji_api("GET", "/v1/blueprints")["results"]
    print(f"Total blueprints: {len(blueprint_results)}")

    print("")
    print(
        "The below are a list of blueprints that have devices and parameters\n"
        "assigned. We pull in all devices and check to see if any have parameters\n"
        "assigned then pull the parameter ids and parameter names so that we can\n"
        "compare to the parameter ids that were found in the blueprint responses and\n"
        "assign a name to the parameter ID."
    )

    # loop over the bluprints returned in the results
    for blueprint in blueprint_results:
        # check to see if the params list is populated and that devices are assigned to
        # the blueprint before going further
        if blueprint["params"] and blueprint["computers_count"] > 0:

            print()
            print(f"Blueprint name: {blueprint['name']}")
            print(f"Total devices assigned: {blueprint['computers_count']}")
            print()

            # loop over each parameter found in the blueprint
            for param_id in blueprint["params"]:
                for key, value in device_params_dict.items():
                    if param_id == key:
                        print(f"\t{param_id} - {value}")
                        break


if __name__ == "__main__":
    main()
