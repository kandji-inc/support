
# assign-user-prompt

This script is designed to prompt a macOS end user for their email address. It will then look up their email against a SCIM Directory Integration in Kandji, and if a viable match is found, assign that user to the device record.

![End user experience](images/aup-image1.png)
![End user success](images/aup-image2.png)

While the intended use of this script was to be deployed via Kandji Self Service, there is no reason that in couldn't be run in another context. For example, [after Liftoff completes](https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff).

## Prerequisites

1. Kandji API Token with Device Information Permissions. For more infomation about setting up an API token, see https://support.kandji.io/support/solutions/articles/72000560412-kandji-api
2. SCIM Directory Integration & Token. For more information about setting up a SCIM Integration and obtaining your token, see https://support.kandji.io/support/solutions/articles/72000560494-scim-directory-integration
3. JQ. The script will check for, download, and install JQ automatically in order to parse JSON. In the future, this script may be updated to leverage plutil and move away from the JQ depencency. 
 
## Prepare the Script
 
Simply fill in the variables section of the script with the appropriate information from your Kandji tenant. Add the script as a Custom Script library item and set your execution to Self Service. 

## Notes

By default, the SCIM API call is set to return 10,000 records. If your user directory is larger, you can increase this value in the script by modifying the `"$base_url/v1/scim/Users?count=10000"` to an appropriate number.
