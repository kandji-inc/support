
# assign-passport-user

This script is designed to automatically look for the IdP user who signed in with Passport and assign that user to the device record in Kandji. It will look up the IdP user in your Kandji SCIM Directory Integration, and if a match is found, assign that user to the device record.

## Prerequisites

1. [Kandji API Token](https://support.kandji.io/support/solutions/articles/72000560412-kandji-api) with Update a device and Device list permissions.
<img src="images/api-permissions.png" width="800"></img>
2. [SCIM Directory Integration and Token](https://support.kandji.io/support/solutions/articles/72000560494-scim-directory-integration)
3. [jq](https://jqlang.github.io/jq). The script will check for, download, and install jq automatically for JSON parsing. If the script installs jq it will also delete it before exiting.
 
## Prepare the Script
 
1. Open the script in a text editor such as BBEdit or VSCode.
2. Update the `subdomain` variable to match your Kandji subdomain, `region` to match your tenant region (us or eu), `scimToken` with the SCIM token generated when creating your Kandji SCIM integration, and `apiToken` with your Kandji API bearer token.

```Shell
################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# Set your Kandji subdomain (example: for "beekeepr.kandji.io", enter "beekeepr")
subdomain="subdomain"

# Set your region (example: "us" or "eu")
region="us"

# Kandji SCIM API token
scimToken="SCIM token goes here"

# Kandji API token
apiToken="API token goes here"

```
3. Save and close the script.
4. In Kandji, create a new Custom Script.
5. Set a title and assign it to the correct Blueprint(s)
6. Set the execution frequency to Run once per device
7. Paste your modified assign-passport-user.zsh script in the body of the script
8. Click Save
