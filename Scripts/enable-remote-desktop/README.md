
# enable-remote-desktop

This script is designed to automatically toggle on Remote Desktop for any macOS endpoint it is run on. This could be used to enable Remote Desktop for all devices in a particular blueprint, or could be executed via Self Service for a user-centric approach.

![macOS Sharing Pane](https://github.com/kandji-inc/support-stage/blob/e8240dc972de28412129acd61b729fa4cc612d60/Scripts/enable-remote-desktop/images/Screenshot%202023-07-17%20at%209.36.00%20PM.png)

## Prerequisites

1. Kandji API Token with Update Device, Device List, and Remote Desktop permissions. For more infomation about setting up an API token, see https://support.kandji.io/support/solutions/articles/72000560412-kandji-api
2. JQ. The script will check for, download, and install JQ automatically in order to parse JSON. At the end of the script, JQ will be removed.
 
## Prepare the Script
 
Simply fill in the variables section of the script with the appropriate information from your Kandji tenant. Add the script as a Custom Script library item and choose your execution frequency.

## Notes

For more information about Remote Desktop on macOS, see: https://support.kandji.io/support/solutions/articles/72000590260-turn-on-remote-desktop
