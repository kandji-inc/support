
# enable-remote-management

This script is designed to automatically toggle on Remote Management for any macOS endpoint it is run on. This could be used to enable Remote Desktop for all devices in a particular blueprint, or could be executed via Self Service for a user-centric approach.

![macOS Sharing Pane](images/remote_mgmt.png)

## Prerequisites

1. Iru API token with Update Device, Device List, and Remote Desktop permissions. For more infomation about setting up an API token, see [Iru API token](https://docs.iru.com/en/endpoint/api/iru-api-overview#generate-an-api-token)
2. JQ. The script will check for, download, and install JQ automatically in order to parse JSON. At the end of the script, JQ will be removed.
 
## Prepare the Script
 
Simply fill in the variables section of the script with the appropriate information from your Iru tenant. Add the script as a Custom Script library item and choose your execution frequency.

## Notes

For more information about Remote Desktop on macOS, see: https://docs.iru.com/en/endpoint/devices/device-actions/turn-on-remote-desktop
