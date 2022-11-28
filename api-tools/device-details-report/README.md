# Devices Details Report

### About

This `python3` script leverages the Kandji API to generate reports device details endpoint for devices in a Kandji tenant.

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

1. Open the script in a text editor such as BBEdit, Atom, or VSCode.
1. Update the `SUBDOMAIN` variable to match your Kandji subdomain, the Kandji tenant `REGION`, and update `TOKEN` information with your Bearer token.

    - The `BASE_URL`, `REGION`, and `TOKEN` can be found by logging into Kandji then navigate to `Settings > Access > API Token`. From there, you can copy the information out of the API URL and generate API tokens.

        *NOTE*: The API token is only visible at the point of creation so be sure to copy it to a safe location.

        ```python
        ##############################################################################################
        ######################### UPDATE VARIABLES BELOW #############################################
        ##############################################################################################

        SUBDOMAIN = "accuhive"  # bravewaffles, example, company_name
        REGION = "us"  # us and eu - this can be found in the Kandji settings on the Access tab within
                       # the API URL.

        # Kandji Bearer Token
        TOKEN = "your_api_key_here"
        ```
1. Save and close the script.

### Running the Script

1. Copy this script to a common location. i.e. Desktop
2. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

3. Enter the following command in the Terminal window to see script options.

    - `python3 device_details_report.py --help`

        ```
        usage: device_details_report [-h] [--user-activation-lock on|off | --ade-eligible yes|no | --auto-enrolled yes|no | --filevault on|off | --prk-escrowed yes|no | --kandji-agent yes|no | --recovery-lock on|off | --remote-desktop on|off | --all] [--platform "Mac"]
                             [--version]

        Get a report containing information from the device details API.

        options:
          -h, --help            show this help message and exit
          --user-activation-lock on|off
                                Return devices were user-based activation lock is either on or
                                off. If user-based activation lock is on this means that the user
                                has signed into iCloud with a personal Apple ID.
          --ade-eligible yes|no
                                Return devices that are either ADE eligible(yes) via Apple
                                Business Manager or not(no).
          --auto-enrolled yes|no
                                Return devices that were either automatically enrolled(yes) via
                                Automated Device Enrollment and Apple Business Manager or not(no).
          --filevault on|off    Return macOS devices where FileVault is on or off
          --prk-escrowed yes|no
                                Return macOS devices where FileVault PRK has either been
                                escrowed(yes) or not(no).
          --kandji-agent yes|no
                                Return macOS devices where the Kandji agent is or is not installed.
          --recovery-lock on|off
                                Return macOS devices where recovery lock is either on or off.
          --remote-desktop on|off
                                Return macOS devices where remote desktop is either on or off.
          --all                 Just give me everything for all devices. No filters please...
          --platform "Mac"      Enter a specific device platform type. This will limit the search
                                results to only the specified platform. Examples: Mac, iPhone,
                                iPad, AppleTV.
          --version             Show this tool's version.
        ```

4. If the `device_details_report.py` script is executed, a csv file with will be generated in the current directory, which, in this example would be the `Desktop`.

### Examples

- Generate a report containing devices that have user activation lock turned on.

    `python3 device_details_report.py --user-activation-lock on`

- Generate a report containing all Mac computers with a FileVault PRK escrowed.

    `python3 device_details_report.py --platform "Mac" --prk-escrowed yes`

- Generate a report containing all details for all devices. No filtering applied.

    `python3 device_details_report.py --all`
