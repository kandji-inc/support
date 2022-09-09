# API Tools

Tools that can be used to interact with the [Kandji API](https://support.kandji.io/support/solutions/articles/72000560412-kandji-api). Bee sure to checkout the README docs specific to each script for more detail.

### app-install-report

app-install-report leverages the Kandji API to generate a CSV report containing a list of every macOS application recorded by the Kandji Web App. You can also search for a specific app by name. The information includes any application found in the "/Applications" directory on a Mac computer, the application version, and the number of Mac computers that have a particular version of the app installed.

### apple-integrations

Us this script to interact with Apple Integations API endpoints in a Kandji tenant.

**Note**: At present, this tool has the ability to read information about the Kandji public key used with ABM, existing ADE tokens in Kandji, and devices associated with a given ADE token.

### bumbledore

This command line tool allows the user to interact with Kandji(🐝) via the Kandji API. Right now this tool can pull device details against the Devices API endpoint.

### code-examples

This is a folder containing example scripts used throughout the other api-tools.

### device-actions

This command line utility leverages the Kandji API to send device actions to one or more devices in a Kandji tenant.

### devices-details-report

This python3 script leverages the Kandji API to generate reports based on the GET all devices API and GET device details endpoints for devices in a Kandji tenant.

### device-library-items

This script leverages the Kandji API to generate a CSV report containing information about a specific library item or all library items scoped to devices in the Kandji tenant.

### devices-report

This script is used to generate a basic device report based on the GET Devices API endpoint for all devices in a Kandji tenant.

### device-parameters

These `python3` scripts leverage the Kandji API to interact with and generate reports from the device parameters endpoint.

### device-status

Generate device reports from the device status API.

### update-device-record

update-device-record leverages the Kandji API along with a CSV input file to update one or more device inventory records. At present, a device the blueprint, asset tag, and assigned user can be updated using this script.

The full API documentation can be found at [https://api.kandji.io](https://api.kandji.io/).
