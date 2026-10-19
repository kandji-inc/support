#!/bin/zsh

################################################################################################
# Created by @captam3rica
# Maintained by Iru, Inc. | support@iru.com
################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Iru, Inc.
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

# Report free, used, and total space for the internal data volume.
# Calls macOS system_profiler with SPStorageDataType, then reads the volume
# mounted at /System/Volumes/Data on an internal disk. plutil parses the JSON.

bytes_to_gb() {
    /usr/bin/awk -v bytes="$1" 'BEGIN { printf "%.2f", bytes / 1000000000 }'
}

plist_value() {
    printf '%s' "$storage_json" | /usr/bin/plutil -extract "$1" raw -o - - 2>/dev/null
}

storage_json=$(/usr/sbin/system_profiler -json SPStorageDataType 2>/dev/null)
if [[ -z "$storage_json" ]]; then
    printf '%s\n' "system_profiler did not return storage information."
    exit 1
fi

if ! volume_count=$(printf '%s' "$storage_json" | /usr/bin/plutil -extract SPStorageDataType raw -o - - 2>&1); then
    printf '%s\n' "plutil could not read the storage data: $volume_count"
    exit 1
fi
if [[ -z "$volume_count" || "$volume_count" == "0" ]]; then
    printf '%s\n' "system_profiler did not return any storage volumes."
    exit 1
fi

for (( index = 0; index < volume_count; index++ )); do
    mount_point=$(plist_value "SPStorageDataType.${index}.mount_point")
    internal_disk=$(plist_value "SPStorageDataType.${index}.physical_drive.is_internal_disk")
    if [[ "$mount_point" != "/System/Volumes/Data" || "$internal_disk" != "yes" ]]; then
        continue
    fi

    disk_name=$(plist_value "SPStorageDataType.${index}._name")
    free_bytes=$(plist_value "SPStorageDataType.${index}.free_space_in_bytes")
    total_bytes=$(plist_value "SPStorageDataType.${index}.size_in_bytes")
    if [[ -z "$disk_name" || -z "$free_bytes" || -z "$total_bytes" ]]; then
        printf '%s\n' "Storage data is missing a disk name or size."
        exit 1
    fi

    total_gb=$(bytes_to_gb "$total_bytes")
    free_gb=$(bytes_to_gb "$free_bytes")
    used_gb=$(bytes_to_gb $(( total_bytes - free_bytes )))

    printf '%s\n' "Internal Disk Space"
    printf '%s\n' "-------------------"
    printf '%-18s%s\n' "Disk name:" "$disk_name"
    printf '%-18s%s\n' "Mount point:" "$mount_point"
    printf '%-18s%s GB\n' "Total disk size:" "$total_gb"
    printf '%-18s%s GB\n' "Total used space:" "$used_gb"
    printf '%-18s%s GB\n' "Total free space:" "$free_gb"
    exit 0
done

printf '%s\n' "No internal data volume was found at /System/Volumes/Data."
exit 1
