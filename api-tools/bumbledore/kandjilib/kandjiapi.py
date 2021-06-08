#!/usr/bin/env python3

"""kandjiapi.py
Module for interacting with the Kandji API.
"""

# Github: github.com/kandji-inc/solutions-engineering
# @captam3rica

# Standard library
import sys

# Third party libs
import requests


def get_all_devices(baseurl, headers):
    """Retrive all device inventory records from Kandji"""

    # The API endpont to target
    endpoint = "/v1/devices/?platform=Mac"

    # Initiate var that will be returned
    data = None

    try:
        # Make the api call to Kandji
        response = requests.get(baseurl + endpoint, headers=headers, timeout=10)

        # Store the HTTP status code
        response_status = response.status_code

        if response_status == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print("Something has gone wrong ...")
        print(f"ERROR: {error}")
        sys.exit()

    return data


def get_all_devices_os_version(baseurl, headers, os_version):
    """Retrive all Mac computer inventory records from Kandji based on the OS version
    provided"""

    # The API endpont to target
    endpoint = "/v1/devices/"

    payload = """{platform: Mac, os_version: %s}""" % os_version

    # Initiate var that will be returned
    data = None

    try:
        # Make the api call to Kandji
        response = requests.get(
            baseurl + endpoint, headers=headers, data=payload, timeout=10
        )

        # Store the HTTP status code
        response_status = response.status_code

        if response_status == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print("Something has gone wrong ...")
        print(f"ERROR: {error}")
        sys.exit()

    return data


def get_device_details(baseurl, headers, device_id):
    """Return device details for specific device."""

    # The API endpont to target
    endpoint = f"/v1/devices/{device_id}/details"

    # Initiate var that will be returned
    data = None

    try:
        # Make the api call to Kandji
        response = requests.get(baseurl + endpoint, headers=headers, timeout=10)

        # Store the HTTP status code
        response_status = response.status_code

        if response_status == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print("Something has gone wrong ...")
        print(f"ERROR: {error}")
        sys.exit()

    return data


def get_device_apps(baseurl, headers, device_id):
    """Return applicaitons installed for a specific device."""

    # The API endpont to target
    endpoint = f"/v1/devices/{device_id}/apps"

    # Initiate var that will be returned
    data = None

    try:
        # Make the api call to Kandji
        response = requests.get(baseurl + endpoint, headers=headers, timeout=10)

        # Store the HTTP status code
        response_status = response.status_code

        if response_status == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print("Something has gone wrong ...")
        print(f"ERROR: {error}")
        sys.exit()

    return data


def get_device_status(baseurl, headers, device_id):
    """Return applicaitons installed for a specific device."""

    # The API endpont to target
    endpoint = f"/v1/devices/{device_id}/status"

    # Initiate var that will be returned
    data = None

    try:
        # Make the api call to Kandji
        response = requests.get(baseurl + endpoint, headers=headers, timeout=10)

        # Store the HTTP status code
        response_status = response.status_code

        if response_status == requests.codes["ok"]:
            # HTTP Code 200 (successfull)
            data = response.json()

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print("Something has gone wrong ...")
        print(f"ERROR: {error}")
        sys.exit()

    return data
