# bumbledore

### Description

This commandline tool allows the user to interact with the Kandji(🐝) via the [Enterprise API](https://api.kandji.io).

Right now this tool can pull device details against the Devices API endpoint.

### Dependencies

- This script relies on Python 3 to run. Python 3 can be installed directly as an [Auto App](https://updates.kandji.io/auto-app-python-3-214020), from [python.org](https://www.python.org/downloads/), or via [homebrew](https://brew.sh)

- Python dependencies can be installed individually below, or with the included `requirements.txt` file using the following command from a Terminal: `python3 -m pip install -r requirements.txt`

```
python3 -m pip install requests
python3 -m pip install pathlib
python3 -m pip install toml
```

### --help output

```
python bumbledore.py --help
usage: bumbledore.py [-h] [--device-os "11.3.1"] [--device-details] [--device-apps] [--device-status] [--version] [-v LEVEL]

A tool to manipulate information in Kandji via the Enterprise API.

optional arguments:
  -h, --help            show this help message and exit
  --device-os "11.3.1"  Returns devices with the specified OS.
  --device-details      Returns detailed device inventory from Kandji.
  --device-apps         Prints a unique list of apps and app versions along with number of installations per app.
  --device-status       Returns the full status (parameters and library items) for a specified Device ID.
  --version             Show this tools version.
  -v LEVEL, --verbose LEVEL
```

### Todo

✅ Add ability to query for devices on a specific macOS version.  
🔲 Allow remports to be generated via CSV if the `--report` flag is added to a base command.  
🔲 Move the commandline args function to its own module in the kandjlib package
