#!/usr/bin/env python

"""system_profiler.py
A wrapper module to do system_profiler queries using python"""

# github: @captam3rica

import json
import subprocess


def convert_bytes(bytes_in):
    """Convert bytes to another size unit"""
    i = 0
    double_bytes = bytes_in

    while bytes_in >= 1024:
        double_bytes = bytes_in / 1024.0
        i = i + 1
        bytes_in = bytes_in / 1024

    return str(round(double_bytes, 2))


def system_profiler(data_type):
    """Return system_profiler information based on data type passed.
    A wrapper funtion for system_profiler macOS binary

    Args:
        data_type: The data type from which to pull system information.

            Examples: Storage, Hardware, Printer, Logs. DeveloperTools, Network

            For more datatypes run "man system_profiler" from a Terminal window
    """
    cmd = [
        "/usr/sbin/system_profiler",
        "-json",
        f"SP{data_type}DataType",
    ]

    # Use subprocess to shellout and pull system_profiler info
    with subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as proc:
        out, err = proc.communicate()

    # Serialize the data
    data = json.loads(out)

    return data[f"SP{data_type}DataType"]


def main():
    """Run main logic"""

    # Get the storage data information
    storage_data = system_profiler(data_type="Storage")

    for attribute in storage_data:
        # Loop over each storage device returned

        if (
            attribute["mount_point"] == "/System/Volumes/Data"
            and attribute["physical_drive"]["is_internal_disk"] == "yes"
        ):

            # find the amount of free space remaining to determine if storage is
            # getting full.
            free_space = convert_bytes(attribute["free_space_in_bytes"])
            total_space = convert_bytes(attribute["size_in_bytes"])
            total_space_used = round(float(total_space) - float(free_space), 2)

            print(f"Name of disk: {attribute['_name']}")
            print(f"Mount point: {attribute['mount_point']}")
            print(f"Total used space: {total_space_used} GB")
            print(f"Total free space: {free_space} GB")
            print(f"Total disk size: {total_space} GB")


if __name__ == "__main__":
    main()
