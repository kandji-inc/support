# Device Library Items Report

**NOTE**: As with any script please be sure to test with a subset of devices.

### About

This script leverages the [Kandji API](https://api.kandji.io/#intro) to generate a CSV report containing information about library items assigned to devices in the Kandji tenant.


### Kandji API

- See the [Kandji API KB](https://support.kandji.io/api) article to see how to generate an API Token
- The API permissions required to run the reporting script are as follows.

    <img src="images/api_permissions.png" alt="drawing" width="1024"/>



### Dependencies

- This script relies on Python 3 to run. Python 3 can be installed directly as an [Auto App](https://updates.kandji.io/auto-app-python-3-214020), from [python.org](https://www.python.org/downloads/), or via [homebrew](https://brew.sh)

- Python dependencies can be installed individually below, or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

    ```
    python3 -m pip install requests
    python3 -m pip install pathlib
    ```

### Script Modification

1. Open the script in a text editor such as BBEdit, Atom, or VSCode.
1. Update the `BASE_URL` variable to match your Kandji web app instance and update `TOKEN` information with your Bearer token.

    - Both the `BASE_URL` and `TOKEN` can be found by logging into Kandji then navigate to `Settings > Access > API Token`. From there, you can copy the API URL and generate API tokens.

        NOTE: The API token is only visible at the point of creation so be sure to copy it to a safe location.

    ```python
    ########################################################################################
    # Initialize some variables
    # Kandji API base URL
    BASE_URL = "https://example.clients.us-1.kandji.io/api/v1/"
    # Kandji Bearer Token
    TOKEN = "your_api_key_here"
    ########################################################################################
    ```

1. Save and close the script.

### Running the Script

1. Copy the script to a common location. i.e. the Desktop folder.
1. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

1. Enter the following command to run the script. In the example below `FileVault` is the Kandji library item name that we are searching for.

    `python3 device_library_items.py --item-name "FileVault"`

    **Example Script Output**

    ```
    python3 device_library_items.py --library-item "FileVault"

    Running: Library items Report ...
    Version: 1.0.0

    Base URL: https://example.clients.us-1.kandji.io/api/v1/

    Looking for devices with the "FileVault" library item assigned...
    Getting all device records from Kandji ...
    Total device records: 32
    Found 4 devices with FileVault assigned...
    Generating LIT report...
    Kandji report complete ...
    Kandji report at: /Users/example/hyper_lit_report_20220512.csv
    ```

1. Once complete a report will be generated and placed in the directory where the script was executed.

    The name of the report is in the format `<item_name>_library_item_report_<todays_date>.csv`

    Example: `filevault_lit_report_20210916.csv`


### Examples

- Generate a report containing Mac devices that have the app Hyper installed.

    `python3 device_library_items.py --item-name "Hyper" --platfrom "Mac"`

- Generate a report containing all library items scoped to all Mac devices.

    `python3 device_library_items.py --all-lit --platfrom "Mac"`

- Generate a report containing all library items scoped to all devices.

    `python3 device_library_items.py --all-lit`

- See additional help info by entering the following command in Terminal.

    `python3 device_library_items.py --help`

    ```
    usage: device_library_items [-h] [--platform "Mac"] [--library-item "Google Chrome"] [--all-lit] [--version]

    Get a report containing information for a given library item or all library items leveraging the Kandji API.

    options:
      -h, --help            show this help message and exit
      --platform "Mac"      Enter a specific device platform type. This will limit the search
                            results to only the specified platfrom. Examples: Mac, iPhone, iPad,
                            AppleTV. Ether the --library-item or --all-lit options must also be
                            specified if the --platform is used.
      --library-item "Google Chrome"
                            Enter the name of a specific Kandji library item. Cannot be used together
                            with the --all-lit option
      --all-lit             Use this option to return all library items for all devices. Cannot be
                            used together with the --library-item option
      --version             Show this tool's version.
    ```
