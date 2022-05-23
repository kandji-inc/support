#!/usr/bin/env python3

"""bumbledore.py
A tool to work with the Kandji API.
"""

# Github: github.com/kandji-inc/solutions-engineering
# @captam3rica

# https://api.kandji.io


__version__ = "0.0.1"


# Standard library
import argparse
import sys

# Local libs
from kandjilib import kandjiapi
from kandjilib import tomlinit


# Initialize some variables
# Pulls from
TOML_DATA = tomlinit.parse_toml_file(tomlinit.TOML_FILE)
MDM_VENDOR = tomlinit.mdm_vendor(TOML_DATA)
BASE_URL = tomlinit.base_url(TOML_DATA)
HEADERS = tomlinit.build_api_headers(TOML_DATA)


# Name of this tool
SCRIPT_NAME = sys.argv[0]


def prog_args():
    """Return arguments"""

    parser = argparse.ArgumentParser(
        prog=SCRIPT_NAME,
        description="A tool to manipulate information in Kandji via the Enterprise API.",
        allow_abbrev=False,
    )

    parser.add_argument(
        "--device-os",
        type=str,
        metavar='"11.3.1"',
        help="Returns devices with the specified OS.",
        required=False,
    )

    parser.add_argument(
        "--device-details",
        action="store_true",
        help="Returns detailed device inventory from Kandji.",
        required=False,
    )

    parser.add_argument(
        "--device-apps",
        action="store_true",
        help=(
            "Prints a unique list of apps and app versions along with number of "
            "installations per app."
        ),
        required=False,
    )

    parser.add_argument(
        "--device-status",
        action="store_true",
        help=(
            "Returns the full status (parameters and library items) for a specified " "Device ID."
        ),
        required=False,
    )

    parser.add_argument(
        "--report",
        type=str,
        metavar='"report_name.csv"',
        help="(comming soon) Enter a path where the report can be created. If a path is not specified"
        " the report will be generated in the current directory.",
        required=False,
    )

    parser.add_argument("--version", action="version", help="Show this tools version.")
    parser.add_argument("-v", "--verbose", action="store", metavar="LEVEL")

    return parser.parse_args()


def app_names_versions(device_ids):
    """Return the app name and app version information from device app info"""

    # List of all apps
    data = []

    # Loop over all Mac computers in Kandji
    for device_id in device_ids:
        device_apps = kandjiapi.get_device_apps(BASE_URL, HEADERS, device_id)

        # Loop over each app in the Kandji "apps" list and append to data dict
        for app in device_apps["apps"]:

            # Create a dictionary containing the application name and version
            app_dict = {"app_name": app["app_name"], "version": app["version"]}

            # Append to data dict
            data.append(app_dict)

    return data


def main():
    """Run main logic"""

    # Return the arguments
    arguments = prog_args()

    # MDM vendor we are using
    print("")
    print(f"MDM Vendor: {MDM_VENDOR}")
    print(f"Base URL: {BASE_URL}")
    print("")

    # Get all device inventory records
    kandji_device_inventory = kandjiapi.get_all_devices(BASE_URL, HEADERS)

    # List of device guids using list comprehension
    kandji_device_ids = [device["device_id"] for device in kandji_device_inventory]

    if arguments.device_os:
        # Print device detailed information based on provided OS version
        for device_id in kandji_device_ids:
            print(kandjiapi.get_all_devices_os_version(BASE_URL, HEADERS, arguments.device_os))

    if arguments.device_details:
        # Print device detailed information
        for device_id in kandji_device_ids:
            print(kandjiapi.get_device_details(BASE_URL, HEADERS, device_id))

    if arguments.device_apps:
        # Print a list of installed apps, their versions, and number of installs per app

        # List of all apps
        all_apps = app_names_versions(kandji_device_ids)

        # This header variable just makes formatting easier in the print statement
        output_header = "{:<25s}{:^20s}{:^20s}".format("App Name", "App Version", "Installs")

        # Formatting for the print statement
        print("All Installed Apps")
        print("-" * len(output_header))
        print(f"{output_header}")
        print("-" * len(output_header))

        # List of unique apps
        unique_apps = []

        # Loop over the all_apps list
        # If the app is not in the
        for app in all_apps:
            if app not in unique_apps:
                print(
                    "{:<25s}{:^20s}{:^20s}".format(
                        f"{app['app_name']}",
                        f"{app['version']}",
                        f"{all_apps.count(app)}",
                    )
                )
                unique_apps.append(app)

    if arguments.device_status:
        # Loop over all devices in Kandji and print the status information
        for device_id in kandji_device_ids:
            all_status_items = kandjiapi.get_device_status(BASE_URL, HEADERS, device_id)

            print(all_status_items["library_items"])
            print(all_status_items["parameters"])

    # if arguments.create_report:
    #     # Create a report
    #     print("This will create a report containing ...")
    #     print("computer_name    guid    serial_number   blueprint   username")


if __name__ == "__main__":
    main()
