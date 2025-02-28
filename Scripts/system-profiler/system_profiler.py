#!/usr/bin/env python

"""system_profiler.py
A wrapper module to do system_profiler queries using python"""

# github: @captam3rica

import json
import subprocess


def convert_bytes(bytes_in):
    """Convert bytes to another size unit"""
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    i = 0
    double_bytes = bytes_in

    while bytes_in >= 1024 and i < len(units) - 1:
        double_bytes = bytes_in / 1024.0
        i = i + 1
        bytes_in = bytes_in / 1024

    return f"{round(double_bytes, 2)} {units[i]}"


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

    try:
        # Use subprocess to shellout and pull system_profiler info
        out = subprocess.check_output(cmd, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"Error running system_profiler command: {e}")
        return None

    try:
        # Serialize the data
        data = json.loads(out)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON data: {e}")
        return None

    return data.get(f"SP{data_type}DataType", [])


def main():
    """Run main logic"""

    # Get the storage data information
    storage_data = system_profiler(data_type="Storage")

    if not storage_data:
        print("Error retrieving storage data. Exiting.")
        return

    for attribute in storage_data:
        # Loop over each storage device returned

        if (
            attribute.get("mount_point") == "/System/Volumes/Data"
            and attribute.get("physical_drive", {}).get("is_internal_disk") == "yes"
        ):

            # find the amount of free space remaining to determine if storage is
            # getting full.
            free_space = convert_bytes(attribute.get("free_space_in_bytes", 0))
            total_space = convert_bytes(attribute.get("size_in_bytes", 0))
            total_space_used = round(
                float(attribute.get("size_in_bytes", 0) - attribute.get("free_space_in_bytes", 0)) / (1024**3), 2)

            if total_space_used >= 1099511627776:
                total_space_used_size = "TB"
            else:
                total_space_used_size = "GB"

            print(f"Name of disk: {attribute.get('_name', '')}")
            print(f"Mount point: {attribute.get('mount_point', '')}")
            print(f"Total used space: -{total_space_used} {total_space_used_size}")
            print(f"Total free space: {free_space}")
            print(f"Total disk size: {total_space}")


if __name__ == "__main__":
    main()
