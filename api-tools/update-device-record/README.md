# Update Device Record

**NOTE**: As with any script please be sure to test with a subset of devices.

### About

This script leverages the [Kandji API](https://api.kandji.io/#intro) along with a `CSV` input file to update one or more device inventory records.

An [example](https://github.com/kandji-inc/solutions-engineering/blob/master/kandji-api/api-examples/kandji-update-device-record/input_template.csv) input file can be found in this repo.

### The following fields can be updated via the Kandji API

- **Blueprint** - Must enter the Blueprint ID in the input file.

    To find a Blueprint ID take the following steps:

    1. Log in to the Kandji web app
    2. Select the Blueprints module
    3. Open the Blueprint to assign
    4. Copy the ID out of the address bar. It should should similar to `e066b81d-xxxx-xxxx-xxxx-b9b302e16f7e`

- **Asset tag**

- **User** - The assigned User can be updated if a Directory Services has been integrated with Kandji and the User exists in the Kandji console. The Kandji user ID Number must be used in the input file.

    To find a Blueprint ID take the following steps:

    1. Log in to the Kandji web app
    2. Select the Users module
    3. Select a User
    4. Copy the ID out of the address bar. It should be similar to ".../users/all/`53`" where `53` is the Kandji user ID. (**NOTE**: This process will become easier in a future update)

### Dependencies

This script relies on Python 3 to run. Python 3 can be installed directly from [python.org](https://www.python.org/downloads/) or via [homebrew](https://brew.sh)

Python dependencies can be installed individually or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

- request module
- pathlib module

### Script Modification

- Update the `BASE_URL` variable to match your Kandji web app instance and update `TOKEN` information with your Bearer token.
- Both the `BASE_URL` and `TOKEN` can be found by logging into Kandji then navigate to `Settings > Access > API Token`. From there, you can copy the API URL and generate API tokens.

    ````python
    ########################################################################################
    # Initialize some variables
    # Kandji API base URL
    BASE_URL = "https://example.clients.us-1.kandji.io/api/v1/"
    # Kandji Bearer Token
    TOKEN = "your_api_key_here"
    ########################################################################################
    ```

### Running the Script

1. Copy the script and input file to a common location. i.e. Desktop
2. Add the serial numbers for which you would like to update records.
3. Enter the Blueprint ID, Asset Tag, and User if applicable.
4. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

5. Enter the following to run the script.

    `python update_device_record.py --input-file </path/to/input_template.csv>`

    **NOTE**: You can enter the path to the input file manually or you can drag the file from your Finder window directly into the Terminal window.


### Extra

You can see additional help info by entering the following command in Terminal.

`python update_device_record.py --help`

```
usage: update_device_record [-h] --input-file "/path/to/input_template.csv" [--version]

Update device inventory information with a CSV input file and the Kandji Enterprise API.

optional arguments:
  -h, --help            show this help message and exit
  --input-file "/path/to/input_template.csv"
                        Enter the path to the spreadsheet(CSV file) or drag the file into this Terminal window.
  --version             Show this tool's version.
```
