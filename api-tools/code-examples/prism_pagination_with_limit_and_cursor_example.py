#!/usr/bin/env python3

"""Prism API cursor pagination example using python."""

################################################################################################
#
#   DESCRIPTION
#
#       This script uses a combination of the limit and cursor parameters to
#       demonstrate the use of pagination to control the number of records returned per
#       Prism API call and how to call the next batch of application records until all
#       application records are returned.
#
#       param: limit
#
#       The limit parameter controls the maximum number of items that may be returned
#       for a single request. This parameter can be thought of as the page size. If no
#       limit is specified, the default limit is set to 300 records per request.
#
#       param: cursor
#
#       Opaque pagination token for retrieving the next page of results.
#        - This value is obtained from the `cursor` field of a previous response.
#        - The cursor encodes the current position in the result set based on the
#          underlying sort order.
#        - Clients must treat this value as opaque and should not attempt to parse or modify it.
#        - Cursors are only valid for the same query parameters and ordering.
#        - If not provided, the request returns the first page of results.
#
#       Note: Custom ordering is not currently supported.
#       Note: Cursor-based pagination provides consistent performance and avoids the
#             limitations of offset-based pagination for large datasets.
#
#   RESOURCES
#
#       In very simple terms, pagination is the act of splitting large amounts of data
#       into multiple smaller pieces. For example, whenever you go to the questions
#       page in Stack Overflow, you see something like this at the bottom
#
#       - https://realpython.com/python-api/#pagination
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Kandji, Inc.
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

import sys

import requests
from requests.adapters import HTTPAdapter

########################################################################################
######################### UPDATE VARIABLES BELOW #######################################
########################################################################################

SUBDOMAIN = ""  # bravewaffles, example, company_name

# us("") and eu - this can be found in the Kandji settings on the Access tab
REGION = ""

# Kandji Bearer Token (API Key from your tenant settings)
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

# API headers used in the requests
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}


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
            "\tPossible reason: It could be the endpoint is not correct."
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


def get_apps(params=None):
    """Return application inventory."""
    count = 0
    # limit - set the number of records to return per API call
    limit = 300
    # cursor - starts from the beginning of the collection and is used to retrieve the next batch of records until all records are returned
    cursor = ""
    # inventory
    data = []

    while True:
        # update params
        params.update(
            {"limit": f"{limit}", "cursor": f"{cursor}"}
        )

        # check to see if a platform was specified
        response = kandji_api(method="GET", endpoint="/v1/prism/apps", params=params)

        items = response.get("data", [])
        count += len(items)
        if len(items) == 0:
            break
        data.extend(items)

        cursor = response.get("cursor", "")
        if not cursor or cursor == "":
            break

    if len(data) < 1:
        print("No applications found...\n")
        sys.exit()

    return data


def main():
    """Do the main logic."""
    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # dict placeholder for params passed to api requests
    params_dict = {}

    # Get the total number of apps
    app_inventory = get_apps(params=params_dict)
    print(f"Total number of applications: {len(app_inventory)}")


if __name__ == "__main__":
    main()
