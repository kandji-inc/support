#!/usr/bin/env python3

"""API pagination example using python."""

#
#   DESCRIPTION
#
#       This script uses a combination of the limit and offset parameters to
#       demonstrate the use of pagination to control the number of records returned per
#       API call and how to call the next batch of device records until all device
#       records are returned.
#
#       param: limit
#
#       The limit parameter controls the maximum number of items that may be returned
#       for a single request. This parameter can be thought of as the page size. If no
#       limit is specified, the default limit is set to 300 records per request.
#
#       param: offset
#
#       The offset parameter controls the starting point within the collection of
#       resource results. For example, if you have a total of 35 device records in your
#       Kandji instance and you specify limit=10, you can retrieve the entire set of
#       results in 3 successive requests by varying the offset value: offset=0,
#       offset=10, and offset=20. Note that the first item in the collection is
#       retrieved by setting a zero offset.
#
#   RESOURCES
#
#       In very simple terms, pagination is the act of splitting large amounts of data
#       into multiple smaller pieces. For example, whenever you go to the questions
#       page in Stack Overflow, you see something like this at the bottom
#
#       - https://realpython.com/python-api/#pagination
#

import sys

import requests
from requests.adapters import HTTPAdapter

# Initialize some variables

# Kandji API base URL
BASE_URL = "https://example.clients.us-1.kandji.io/api/v1/"

# Kandji Bearer Token
TOKEN = "api_token"

# API headers used in the requests
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}


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


def main():
    """Do the main logic."""
    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # dict placeholder for params passed to api requests
    params_dict = {}

    # Get the total number of devices
    device_inventory = get_devices(params=params_dict)
    print(f"Total number of devices: {len(device_inventory)}")


if __name__ == "__main__":
    main()
