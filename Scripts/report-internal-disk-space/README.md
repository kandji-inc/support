# report_internal_disk_space.zsh

Reports free space, used space, and total size for the internal APFS data volume.

The script calls `/usr/sbin/system_profiler -json SPStorageDataType` and uses `/usr/bin/plutil` to read the JSON. It selects the volume mounted at `/System/Volumes/Data` when that volume is on an internal disk, converts the byte counts to gigabytes, and prints the result. Both commands are included with macOS.

## Requirements

- A Mac

## Deploy it as a Custom Script

Add a Custom Script Library Item in Iru Endpoint. Assign it to the Blueprints where you want to run it, paste this script into the **Audit Script** field, and select an **Execution Frequency**. For the rest of the Library Item settings, see [Custom Scripts Overview](https://docs.iru.com/en/endpoint/library/library-items-profiles/custom-scripts-overview).

The script result is recorded with the Library Item. Exit code 0 means the script printed the storage summary.

## Run it in Terminal

Open Terminal, then run the script by its path:

```bash
zsh /path/to/report_internal_disk_space.zsh
```

Replace `/path/to` with the folder where `report_internal_disk_space.zsh` is saved on the Mac.

Example output:

```text
Internal Disk Space
-------------------
Disk name:        Macintosh HD - Data
Mount point:      /System/Volumes/Data
Total disk size:  322.12 GB
Total used space: 231.25 GB
Total free space: 90.87 GB
```

Sizes are decimal gigabytes, the same unit macOS uses. One gigabyte in this script is 1,000,000,000 bytes.

The values may differ slightly from the used and available storage space shown in Apple's **Storage settings**. This script calculates values from the byte counts returned by `system_profiler` and rounds them to two decimal places. Available storage in Apple's Storage settings can include free space and purgeable disk caches.

If the internal data volume is not found, `system_profiler` returns no storage volumes, or `plutil` can't read the storage data, the script prints an error and exits. A `plutil` error includes the message `plutil` returned.

## How system_profiler is used

The script runs `/usr/sbin/system_profiler -json SPStorageDataType`. `Storage` is the name between `SP` and `DataType`. `plutil` then reads each volume's mount point, internal-disk flag, name, free space, and total size.

## License

Released under the MIT License.

Copyright 2026 Iru, Inc.

## Author

- GitHub: [@captam3rica](https://github.com/captam3rica)
