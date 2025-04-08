# Update Device Record

**NOTE**: Test Test Test--As with any script please be sure to test with a subset of devices.

## About

This script leverages the Kandji API along with a `CSV` input file (An example input file can be found in this repo) to update one or more device inventory records. Information for both existing enrolled devices and devices awaiting enrollment (aka ADE devices) can be updated using this script. 

The script will first try to look for and update enrolled device records. If an enrolled device record cannot be found, the script will attempt to look for  and update the device record in the "Awaiting enrollment" state (aka ADE devices not yet enrolled in Kandji). Additionally, the script will perform some light sanitization on the input template headers to ensure that they are in the proper format and have not been altered.

## Kandji API

The API permissions required to run the reporting script are as follows. Checkout the Kandji [Knowledge Base](https://support.kandji.io) for more information.

<img src="images/api_permissions.png" alt="drawing" width="1024"/>

## The following fields can be updated via the Kandji API

Attribute | Enrolled Devices | Devices Awaiting Enrollment (ADE) | Notes
:-- | :-- | :-- | :--
Blueprint assignment | ✅ | ✅ | Enter the Blueprint name in the input file as it appears in Kandji. The script will programatically lookup the blueprint ID based on the name provided and then use the ID to update the device assignment. If more than one blueprint is returned containing the specifice name, the script will try to find and exact match. If the blueprint cannot befound, blueprint assignment will not be updated.
Asset tag | ✅ | ✅ | The asset tag assignment can be cleared by passing a value of `null` for the asset tag. 
User assignment | ✅ | ❌ | The assigned User can be updated if a Directory Services has been integrated with Kandji and the User exists in the Kandji console. The Kandji user ID Number must be used in the input file. The user assignment can be cleared by passing a value of `null` for the user. <br><br> Use the following steps to find the Kandji user ID number: <ol><li>Log in to the Kandji web app</li><li>Go to the Users module</li><li>Select a user</li><li> Copy the ID out of the address bar. It should be similar to ".../users/all/`53`" where `53` is the Kandji user ID.</li></ol>(**NOTE**: This process will become easier in a future update)

## Dependencies

- This script relies on Python 3 to run. Python 3 can be installed directly as an [Auto App](https://support.kandji.io/kb/auto-apps-overview), from [python.org](https://www.python.org/downloads/), or via [Homebrew](https://brew.sh)

- Python dependencies can be installed individually below, or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

    ```
    python3 -m pip install requests
    python3 -m pip install pathlib
    ```

## Script Modification

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

## Running the Script

1. Copy the script and input file to a common location. i.e. Desktop
2. Add the serial numbers for which you would like to update records.
3. Enter the Blueprint ID, Asset Tag, and User ID number if applicable.
4. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

5. Enter the following to run the script.

    `python3 update_device_record.py --template "/path/to/input_template.csv"`
    
    **Example output**
    
    ```shell
    python3 update_device_record.py --template input_template_test.csv

    Version: 1.4.1
    Base URL: https://accihive.api.kandji.io/api
    
    Found input file: input_template_test.csv
    Checking file for duplicate serial_number entries...
    Total unique serial_numbers in the input file: 6
    
    Looking for C02J50A8G1HW in Kandji...
    Found device in enrolled devices.
    More than one blueprint was returned containing "_test_something". Will look through the results for an 
    exact match.
            _test_something
            _test_something_went_wrong
            _test_something_went_wrong_2
            _test_something_went_wrong_3
    Attempting to update device record...
    Request payload: "{\"blueprint_id\": \"ab102b9d-8e9c-420d-a498-f2a1123091c7\", \"asset_tag\": \"this_is_a_test\", \"user\": \"9564\"}"
    Device updated!
    
    Looking for GG7FF8QSQ1GH in Kandji...
    Found device in enrolled devices.
    "_tester_something" not found in Kandji. Will not attempt to update blueprint assignemnt. If the blueprint does
    exist, make sure that the name is entered correctly in the input csv.
    Attempting to update device record...
    Request payload: "{\"asset_tag\": \"this_is_a_test_02\", \"user\": \"9564\"}"
    Device updated!
    
    Looking for C02FL5YXQ6LC in Kandji...
    Found device in enrolled devices.
    More than one blueprint was returned containing "_test_something". Will look through the results for an 
    exact match.
            _test_something
            _test_something_went_wrong
            _test_something_went_wrong_2
            _test_something_went_wrong_3
    Attempting to update device record...
    Request payload: "{\"blueprint_id\": \"ab102b9d-8e9c-420d-a498-f2a1123091c7\", \"asset_tag\": \"this_is_a_test_03\", \"user\": \"9564\"}"
    Device updated!
    
    Looking for ZGNQQHVT0N in Kandji...
    Found device in enrolled devices.
    More than one blueprint was returned containing "_test_something". Will look through the results for an 
    exact match.
            _test_something
            _test_something_went_wrong
            _test_something_went_wrong_2
            _test_something_went_wrong_3
    Attempting to update device record...
    Request payload: "{\"blueprint_id\": \"ab102b9d-8e9c-420d-a498-f2a1123091c7\", \"asset_tag\": \"this_is_a_test_04\", \"user\": \"9564\"}"
    Device updated!
    
    Looking for FVHHFKF7Q6L4 in Kandji...
    Found device in enrolled devices.
    "_tester_something" not found in Kandji. Will not attempt to update blueprint assignemnt. If the blueprint does
    exist, make sure that the name is entered correctly in the input csv.
    Attempting to update device record...
    Request payload: "{\"asset_tag\": \"this_is_a_test_05\", \"user\": \"9564\"}"
    Device updated!
    
    Looking for ZGFRNNQGQD in Kandji...
    Found device in enrolled devices.
    More than one blueprint was returned containing "_test_something". Will look through the results for an 
    exact match.
            _test_something
            _test_something_went_wrong
            _test_something_went_wrong_2
            _test_something_went_wrong_3
    Attempting to update device record...
    Request payload: "{\"blueprint_id\": \"ab102b9d-8e9c-420d-a498-f2a1123091c7\", \"asset_tag\": \"this_is_a_test_06\", \"user\": \"9564\"}"
    Device updated!
    
    Finished ...
    ```

    **NOTE**: You can enter the path to the input file manually or you can drag the file from your Finder window directly into the Terminal window.


## Extra

You can see additional help info by using the `--help`.

`python3 update_device_record.py --help`


```
usage: python3 update_device_record [-h] --template "/path/to/input_template.csv" [--version]

Update device inventory information with a CSV file and the Kandji Enterprise API.

optional arguments:
  -h, --help            show this help message and exit
  --template "/path/to/input_template.csv"
                        Enter the path to the spreadsheet(CSV file) or drag the file into this
                        Terminal window. An example input file template can be found in this repo.
  --version             Show this tool's version.
```
