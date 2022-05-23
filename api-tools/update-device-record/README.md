# Update Device Record

**NOTE**: As with any script please be sure to test with a subset of devices.

### About

This script leverages the [Kandji API](https://api.kandji.io/#intro) along with a `CSV` input file to update one or more device inventory records.

An example input file can be found in this repo.

### Kandji API

- See the [Kandji API](https://support.kandji.io/api) support article to see how to generate an API Token
- The API permissions required to run this script are as follows.

    <img src="images/api_permissions.png" alt="drawing" width="1024"/>

### The following fields can be updated via the Kandji API

- **Blueprint** - Enter the Blueprint name in the input file as it appears in Kandji.
- **Asset tag**
- **User** - The assigned User can be updated if a Directory Services has been integrated with Kandji and the User exists in the Kandji console. The Kandji user ID Number must be used in the input file.

    Use the following steps to find the Kandji user ID number:

    1. Log in to the Kandji web app
    2. Go to the Users module
    3. Select a User
    4. Copy the ID out of the address bar. It should be similar to ".../users/all/`53`" where `53` is the Kandji user ID. (**NOTE**: This process will become easier in a future update)

### Dependencies

- This script relies on Python 3 to run. Python 3 can be installed directly as an [Auto App](https://updates.kandji.io/auto-app-python-3-214020), from [python.org](https://www.python.org/downloads/), or via [homebrew](https://brew.sh)

- Python dependencies can be installed individually below, or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

    ```
    python3 -m pip install requests
    python3 -m pip install pathlib
    ```

### Script Modification

- Update the `BASE_URL` variable to match your Kandji web app instance and update `TOKEN` information with your Bearer token.
- Both the `BASE_URL` and `TOKEN` can be found by logging into Kandji then navigate to `Settings > Access > API Token`. From there, you can copy the API URL and generate API tokens.

    ````python
    ########################################################################################
    # Initialize some variables
    # Kandji API base URL
    BASE_URL = "https://example.clients.us-1.kandji.io/api/v1/"
    # Kandji Bearer Token
    TOKEN = "api_token"
    ########################################################################################
    ```

### Running the Script

1. Copy the script and input file to a common location. i.e. Desktop
2. Add the serial numbers for which you would like to update records.
3. Enter the Blueprint ID, Asset Tag, and User if applicable.
4. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

5. Enter the following to run the script.

    `python3 update_device_record.py --input-file "/path/to/input_template.csv"`

    **NOTE**: You can enter the path to the input file manually or you can drag the file from your Finder window directly into the Terminal window.


### Extra

You can see additional help info by using the `--help` flag below.

`python3 update_device_record.py --help`


```
usage: update_device_record [-h] --input-file "/path/to/input_template.csv" [--version]

Update device inventory information with a CSV input file and the Kandji Enterprise API.

optional arguments:
  -h, --help            show this help message and exit
  --input-file "/path/to/input_template.csv"
                        Enter the path to the spreadsheet(CSV file) or drag the file into this
                        Terminal window. An example input file template can be found in this repo.
  --version             Show this tool's version.
```
