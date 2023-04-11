# App Installation Report

**NOTE**: As with any script please be sure to test with a subset of devices.

### About

This `python3` script leverages the Kandji API to generate a `CSV` report containing devices with a specific app installed or all devices with all installed apps.

### Kandji API

- The API permissions required to run the reporting script are as follows. Checkout the Kandji [Knowledge Base](https://support.kandji.io) for more information.

    <img src="images/api_permissions_required.png" alt="drawing" width="1024"/>

### Dependencies

- This script relies on Python 3 to run. Python 3 can be installed directly as an [Auto App](https://updates.kandji.io/auto-app-python-3-214020), from [python.org](https://www.python.org/downloads/), or via [homebrew](https://brew.sh)

- Python dependencies can be installed individually below, or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

    ```
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

### Running the Script

1. Copy this script to a common location. i.e. Desktop
2. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

3. Enter the following command in the Terminal window to run the script.

    `python3 installed_apps.py --name "Atom"`  

    **Example output**

    ```sh
    Version: 1.3.1

    Base URL: https://accuhive.api.kandji.io/api

    Looking for devices with "Atom" installed...
    Getting device inventory from Kandji...
    Total records returned: 54
    Looking for installed apps...
    Found 7 devices with "Atom" installed...
    Generating Kandji app install report ...
    Kandji app report complete ...
    Kandji app report at: /Users/example/installed-apps/atom_app_install_report_20230307.csv
    ```

4. If the `installed_apps.py` script is executed, a file with the name `hyper_installed_apps_<YYYYMMDD>.csv` will be generated in the current directory, which, in this case would the `Desktop`.

### Examples

- To see `--help` information, use

    ```shell
    python installed_apps.py --help
    
    usage: installed_apps [-h] [--name "Atom"] [--version]

    Generates a report containing devices with a specific app installed or a report containing all installed apps.

    options:
    -h, --help     show this help message and exit
    --name "Atom"  Enter a specific app name. This will limit the search results to only the specified app. Example: --name "Kandji Self Service"
    --version      Show this tool's version.
    ```

- To return all apps installed on all devices, use.

    `python3 installed_apps.py`

- To return all devices with "Kandji Self Service" installed, use.

    `python3 installed_apps.py --name "Kandji Self Service"`
