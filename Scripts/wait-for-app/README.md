# Wait for app

You can use this function to wait for a specific application before continuing on with the rest of the script.

For example you can wait for Self Service to be installed and then try to open it automatically.

```shell
# How long to wait in seconds before quitting
# Example -- 300 Checks * 5 seconds between each check = 1500 seconds or 15 minutes
TOTAL_CHECKS=300

# The app that you are looking for
APP_NAME="Kandji Self Service.app"
```
