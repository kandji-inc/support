# Status Report

**NOTE**: As with any script please be sure to test test test.

### About

This script leverages the Kandji API to generate a CSV report containing the installation status of a specified library item or parameter.

### Kandji API

- The API permissions required to run the reporting script are as follows. Checkout the Kandji [Knowledge Base](https://support.kandji.io) for more information.

    <img src="images/api_permissions.png" alt="drawing" width="1024"/>

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

1. Copy the script to a common location. i.e. the Desktop folder.
1. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

1. Enter the following to run the script.

    `python3 status_report.py --item-name "Firefox"` or `python3 status_report.py --parameter-name "Set Computer Name"`

    **Example Script Output**

    ```
    python3 status_report.py --library-item "Homebrew"

    Version: 1.0.2
    Base URL: https://accuhive.api.kandji.io/api

    Getting device inventory from Kandji...
    Total records: 54

    Looking for the status of "homebrew" ...
    Found 46 devices with homebrew assigned ...
    Generating homebrew status report ...
    Kandji report complete ...
    Kandji report at: /Users/example/Desktop/device-status/homebrew_status_report_20230308.csv 
    ```

1. Once complete a report will be generated and placed in the directory where the script was executed.

    The name of the report is in the format `<item_name>_status_report_<todays_date>.csv`

    Example: `homebrew_status_report_20220901.csv`

### Extra

You can see additional help info by entering the following command in Terminal.

`python3 status_report.py --help`

```
usage: status_report [-h] [--library-item "Google Chrome"] [--parameter "Set Computer Name"] [--version]

Get the status report for a given library item or parameter leveraging the Kandji API.

options:
  -h, --help            show this help message and exit
  --library-item "Google Chrome"
                        Enter the name of the Kandji library item.
  --parameter "Set Computer Name"
                        Enter the name of the Parameter.
  --version             Show this tool's version.
```
