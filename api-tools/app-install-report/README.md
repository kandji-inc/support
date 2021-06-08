# App Installation Report

### About

This `python3` script leverages the [Kandji API](https://api.kandji.io/#intro) to generate a `CSV` report containing a list of every macOS application recorded by the Kandji Web App. The information includes any application found in the **Applications** directory on a Mac computer, the application version, and the number of Mac computers that have a particular version of the app installed.

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

1. Copy this script to a common location. i.e. Desktop
2. Launch a Terminal window and navigate to your Desktop using the following command.

    `cd ~/Desktop`

3. Enter the following to run the script.

    `python app_install_report.py`

4. A file with the name `app_install_report_<YYYYMMDD>.csv` will be generated in the current directory.

### Example Output

Below is an example of what he `CSV` output might look like. Click [here](https://github.com/kandji-inc/solutions-engineering/blob/master/kandji-api/api-examples/kandji-app-install-report/kandji_app_install_report_20210525.csv) to see an example `csv` ouput file.

app_name | version | install_count
:-- | :-- | :-- |
Activity Monitor | 10.14 | 2
AirPort Utility | 6.3.9 | 2
App Store	| 3.0	| 2
Atom |	1.54.0	| 1
Atom	| 1.56.0	| 1
Audio MIDI Setup	| 3.5	| 2
