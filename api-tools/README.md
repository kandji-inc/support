# API Tools

Tools that can be used to interact with the [Kandji API](https://support.kandji.io/kb/kandji-api). Be sure to checkout the README docs specific to each script for more detail.

### Tool descriptions

Name | Description
:--- | :---
`installed-apps` | This script leverages the Kandji API to generate a CSV report containing a list of every macOS application recorded by the Kandji Web App. You can also search for a specific app by name. The information includes any application found in the "/Applications" directory on a Mac computer, the application version, and the number of Mac computers that have a particular version of the app installed.
`apple-integrations` | Us this script to interact with Apple Integations API endpoints in a Kandji tenant. **Note**: At present, this tool has the ability to read information about the Kandji public key used with ABM, existing ADE tokens in Kandji, and devices associated with a given ADE token.
`bumbledore` | This command line tool allows the user to interact with Kandji(🐝) via the Kandji API. Right now this tool can pull device details against the Devices API endpoint.
`code-examples` | This is a folder containing example scripts used throughout the other api-tools.
`device-actions` | This command line utility leverages the Kandji API to send device actions to one or more devices in a Kandji tenant.
`device-details` | This script leverages the Kandji API to generate reports based on the GET all devices API and GET device details endpoints for devices in a Kandji tenant.
`device-library-items` | This script leverages the Kandji API to generate a CSV report containing information about a specific library item or all library items scoped to devices in the Kandji tenant.
`devices-report` | This script is used to generate a basic device report based on the GET Devices API endpoint for all devices in a Kandji tenant.
`device-parameters` | These scripts leverage the Kandji API to interact with and generate reports from the device parameters endpoint.
`device-secrets` | List and generate reports from the device secrets API. Filevault PRK, Activation lock bypass code, and unlock PIN.
`device-status` | Generate device reports from the device status API.
`update-device-record` | update-device-record leverages the Kandji API along with a CSV input file to update one or more device inventory records. At present, a device the blueprint, asset tag, and assigned user can be updated using this script.

The full API documentation can be found at [https://api.kandji.io](https://api.kandji.io/).

### Dependencies

- Many of these scripts rely on Python 3 to run. Python 3 can be installed directly as an [Auto App](https://support.kandji.io/kb/auto-apps-overview), from [python.org](https://www.python.org/downloads/), or via [homebrew](https://brew.sh)

- Python dependencies can be installed individually below, or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

    ```shell
    python3 -m pip install requests
    python3 -m pip install pathlib
    ```

### Script Modification

1. Open the script in a text editor such as BBEdit or VSCode.
1. Update the `SUBDOMAIN` variable to match your Kandji subdomain, the Kandji tenant `REGION`, and update `TOKEN` information with your Bearer token.

    - The `BASE_URL`, `REGION`, and `TOKEN` can be found by logging into Kandji then navigate to `Settings > Access > API Token`. From there, you can copy the information out of the API URL and generate API tokens.
    - For US-based tenants the `REGION` can either be `us` or left as an empty string (`""`)

        *NOTE*: The API token is only visible at the point of creation so be sure to copy it to a safe location.

        ```python
        ########################################################################################
        ######################### UPDATE VARIABLES BELOW #######################################
        ########################################################################################

        SUBDOMAIN = "accuhive"  # bravewaffles, example, company_name

        # us("") and eu - this can be found in the Kandji settings on the Access tab
        REGION = ""

        # Kandji Bearer Token
        TOKEN = ""
        ```

1. Save and close the script.
