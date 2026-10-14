
# assign-user-prompt

This script is designed to prompt a macOS end user for their email address. It will then look up their email against your Iru tenant user directory, and if a viable match is found, assign that user to the device record. By default, the script will search your full user directory. If you wish to only search a specific directory, please use the INTEGRATION_ID variable.

The script shows a dialog titled **Computer Assignment**. The prompt says: "Your computer needs to be assigned to you in Iru. Please enter your email address:" The field is prefilled with `you@company.com`, and the buttons are **Cancel** and **Submit**.

After a successful assignment, the script shows: "Thank you! Your computer has been assigned to you in Iru." The only button is **OK**.

While the intended use of this script was to be deployed via Iru Self Service, there is no reason that in couldn't be run in another context. For example, [after Liftoff completes](https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff).

## Prerequisites

1. [Iru API token](https://docs.iru.com/en/endpoint/api/iru-api-overview#generate-an-api-token) with these permissions:
   * **List users** (`GET /api/v1/users`): Get a list of users.
   * **Update a device** (`PATCH /api/v1/devices/{device_id}`): Update the assigned user, Blueprint, or asset tag for the device.
   * **Device list** (`GET /api/v1/devices`): Get a list of all devices.
2. [User Directory Integration](https://docs.iru.com/en/endpoint/getting-started/foundation/user-directory-integration)
3. [jq](https://jqlang.github.io/jq). The script will check for, download, and install jq automatically for JSON parsing. If the script installs jq it will also delete it before exiting.
 
## Prepare the Script
 
1. Open the script in a text editor such as BBEdit or VSCode.
1. Update the User Input variables:
    1. Set `SUBDOMAIN` to your Iru tenant subdomain.
    1. Set `REGION` to match your tenant region (us or eu).
    1. Set `TOKEN` to your Iru API token.
    1. Optional: Set `INTEGRATION_ID` to UUID of the user directory integration you want to search.

    ```Shell
    ##############################################################################
    ############################# USER INPUT #####################################
    ##############################################################################
    
    # Set SUBDOMAIN to the first part of your API URL. Example: for "accuhive.api.kandji.io", enter "accuhive".
    SUBDOMAIN="subdomain"

    # Set your region (example: "us" or "eu")
    REGION="us"

    # Iru API token
    TOKEN="API token goes here"

    # User Directory Integration UUID (leave blank to search all integrations)
    INTEGRATION_ID=""
    ```
1. Save and close the script.
1. In Iru, create a new Custom Script Library Item.
1. Set a title and assign it to the Blueprint(s) you want the item to be a part of.
1. Set the execution frequency to "Run on-demand from Self Service" or your desired execution frequency.
1. Paste your modified assign-user-prompt.zsh script in the "Audit Script" section.
1. Click Save.


