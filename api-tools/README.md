# API Tools

Tools that can be used to interact with the Kandji API.

### app-install-report

app-install-report leverages the Kandji API to generate a CSV report containing a list of every macOS application recorded by the Kandji Web App. The information includes any application found in the "/Applications" directory on a Mac computer, the application version, and the number of Mac computers that have a particular version of the app installed.

### bumbledore

This commandline tool allows the user to interact with the Kandji(🐝) via the Kandji API. Right now this tool can pull device details against the Devices API endpoint.

### update-device-record

update-device-record leverages the Kandji API along with a CSV input file to update one or more device inventory records. At present, a device the blueprint, asset tag, and assigned user can be updated using this script.

The full API documentation can be found at [https://api.kandji.io](https://api.kandji.io/).