# Device actions

### About

This `python3` script leverages the Kandji API to send actions to one or more device in a Kandji instance. Please your this tools `--help` flag to see all avaialble options.

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

1. Copy this script to a common location. i.e. Desktops
2. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

3. Enter the following command in the Terminal window to see script options.

    - `python3 device_actions.py --help`

        ```
        usage: apple_integrations.py [-h] [--blankpush | --remote-desktop [on|off] | --restart | --shutdown | --update-inventory] [--serialnumber XX7FFXXSQ1GH | --platform Mac | --all-devices] [--version]

        Send device actions to one or more devices in a Kandji instance.
        
        options:
          -h, --help            show this help message and exit
          --blankpush           This action sends an MDM command to initiate a blank push. A Blank Push utilizes the same service that 
                                sends MDM profiles and commands. It's meant for verifying a connection to APNs, but it sometimes helps 
                                to get pending push notifications that are stuck in the queue to complete.
          --reinstall-agent     This action with send a command to reinstall the Kandji agent on a macOS device.
          --remote-desktop [on|off]
                                This action with send an MDM command to set macOS remote desktop to on or off remoted desktop for 
                                macOS. If Remote Management is already disabled on a device, sending the off option will result in a 
                                "Command is not allowed for current device" message to be returned from Kandji and the command will not 
                                be sent.
          --renew-mdm           This action sends an MDM command to re-install the existing root MDM profile for a given device ID. 
                                This command will not impact any existing configurations, apps, or profiles.
          --restart             This action sends an MDM command to remotely restart a device.
          --shutdown            This action sends an MDM command to shutdown a device.
          --update-inventory    This action sends a few MDM commands to start a check-in for a device, initiating the daily MDM 
                                commands and MDM logic. MDM commands sent with this action include: AvailableOSUpdates, 
                                DeviceInformation, SecurityInfo, UserList, InstalledApplicationList, ProfileList, and CertificateList.
          --serial-number XX7FFXXSQ1GH
                                Look up a device by its serial number and send an action to it.
          --platform Mac        Send an action to a specific device family in a Kandji instance. Example: Mac, iPhone, iPad.
          --all-devices         Send an action to all devices in a Kandji instance. If this option is used, you will see a prompt to 
                                comfirm the action and will be required to enter a code to continue.
          --version             Show this tool's version.
        ```

### Examples

- Send an action to one device.

    `python3 device_actions.py --blankpush --serialnumber XX7FFXXSQ1GH`
    
- Send an action to turn on Remote Desktop on a Mac.

    `python3 device_actions.py --remote-desktop on --serialnumber XX7FFXXSQ1GH`

- Send an action to all devices of a specific type

    `python3 device_actions.py --blankpush --platform iPhone`
    
- Send an action to all devices.

    **NOTE**: For this command to work you will be required to confirm and enter a code before the script will continue.

    `python3 device_actions.py --blankpush --all-devices`
    
    **Example output**
    
    ```
    Version: 0.0.1
    Base URL: https://accuhive.clients.us-1.kandji.io/api
    
    The blankpush command will go out to ALL devices in the Kandji instance...
    This is NOT reversable. Are you sure you want to do this? Type "Yes" to continue: Yes
    
            Code: 7261
            Please enter the code above: 7261
    
    Code verification complete.
    Getting device inventory from Kandji...
    ```

    
