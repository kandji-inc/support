#!/usr/bin/env python3

"""API pagination example using python."""

#
#   DESCRIPTION
#
#       This script uses a combination of the limit and offset parameters to demonstrate the use
#       of pagination to control the number of records returned per API call and how to call the
#       next batch of device records until all device records are returned.
#
#       param: limit
#
#       The limit parameter controls the maximum number of items that may be returned for a single
#       request. This parameter can be thought of as the page size. If no limit is specified, the
#       default limit is set to 300 records per request.
#
#       param: offset
#
#       The offset parameter controls the starting point within the collection of resource
#       results. For example, if you have a total of 35 device records in your Kandji instance
#       and you specify limit=10, you can retrieve the entire set of results in 3 successive
#       requests by varying the offset value: offset=0, offset=10, and offset=20. Note that the
#       first item in the collection is retrieved by setting a zero offset.
#
#   RESOURCES
#
#       In very simple terms, pagination is the act of splitting large amounts of data into
#       multiple smaller pieces. For example, whenever you go to the questions page in Stack
#       Overflow, you see something like this at the bottom
#
#       - https://realpython.com/python-api/#pagination
#

import requests


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


def kandji_api(method, endpoint, params=None):
    """Make an API GET request and return data.

    Returns a JSON data object
    """
    # Make the api call to Kandji
    response = requests.request(
        method, BASE_URL + endpoint, params=params, headers=HEADERS, timeout=30
    )

    # print the url to show how limit and offset are incremented after each call.
    print(response.url)

    # HTTP Code 200 (successfull)
    return response.json()


def get_device_count():
    """Return total number of devices.

    Utilize the default offset to continue making requests for devices until the response lenth is
    zero meaning no more records were returned.
    """
    count = 0

    # limit - set the number of records to return per API call
    limit = 5

    # offset - set the starting point within a list of resources
    offset = 0

    # Loop while true incrementing offset by the default limit until the response length is zero
    # meaning no more device records were returned.
    while True:
        response = kandji_api(
            method="GET", endpoint="devices", params={"offset": f"{offset}", "limit": f"{limit}"}
        )
        count += len(response)
        offset += limit
        if len(response) == 0:
            break

    return count


def main():
    """Do the main logic."""
    print("")
    print(f"Base URL: {BASE_URL}")
    print("")

    # Get the total number of devices
    device_count = get_device_count()

    print("")
    print(f"Total number of devices: {device_count}")
    print("")


if __name__ == "__main__":
    main()
