# Ventura Checker

## What it checks for
This script is designed to trigger an alert if a device is on macOS Ventura and matches specific criteria:
* Apple Silicon
* Enrolled via ADE
* User-based Activation Lock enabled
* Reduced Secure Boot settings
* Upgraded from a previous version of macOS to macOS Ventura.

## How to use
* Create a Custom Scripts Library item and add to appropriate Blueprints.
* Use Assignment Rules to scope the script to Apple Silicon devices.
* If you prefer your library items to have custom icons, you can find one in the `/images` folder here.
* Check your Alerts tab to find any devices that match the criteria listed above.

![Ventura Library Item](/Scripts/ventura-checker/images/venturacheck_libraryitem.png)

![Ventura Alert](/Scripts/ventura-checker/images/venturacheck_alert.png)