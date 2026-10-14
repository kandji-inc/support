# Blueprint Switcher

This script is designed to move Mac computers already enrolled in Iru from one Blueprint to another.

## Requirements
* This script ([`blueprint_switcher.zsh`](blueprint_switcher.zsh))
* An API token with the following permissions:
  * **List Blueprints** (`GET /blueprints`): Get a list of all Blueprints.
  * **Get Blueprint** (`GET /blueprints/{blueprint_id}`): Get a Blueprint by ID.
  * **Update a device** (`PATCH /devices/{device_id}`): Update the assigned user, Blueprint, or asset tag for the device.
  * **Device details** (`GET /devices/{device_id}/details`): Get the full details for a specific device.
  * **Device list** (`GET /devices`): Get a list of all devices.

This script does not require any additional script libraries or dependencies.
  
## Instructions
1. Generate an API token for this automation in the Iru tenant with the following privileges:
  * List Blueprints
  * Get Blueprint
  * Update a Device
  * Device details
  * Device List

2. Download the [`blueprint_switcher.zsh`](blueprint_switcher.zsh) script. Edit the script and add your **Iru subdomain**, the **API token** you generated in step 1, and the **blueprint name or UUID** you want the Mac assigned to in the `USER INPUT` section of the script.
```shell
##############################################################
# USER INPUT 
##############################################################

# Iru subdomain
subdomain="mycompany"

# Region (us and eu) - this can be found in Iru under Account Menu > Access
region="us"

# API Bearer Token
token="your-token-here"

# Blueprint name/UUID (This is the name of the Blueprint as it exists in Iru that you want to assign devices to).
assignBlueprint="MyBlueprint"
```

3. Create a new **Custom Script** Library item. Change the icon and name as desired, assign it to a Blueprint, and paste your code in.

4. Test and Validate before deploying to production.

## Icon
You can add your own image as the Library Item icon. Use an image that fits how you present this script in Self Service.

## Usage Examples

### Blueprint Switching via Self Service
In a situation where someone wants to assign all Mac computers to a default Blueprint and then have the end-user assign themselves to the appropriate department/role Blueprint via Self Service after they log in for the first time. (In cases where assignment via Identity Provider Group isn't available.)

This is also helpful for depot/warehouse scenarios where technicians may need to choose the intended purpose of a device (i.e. Kiosk Mac vs Caching Server) before shipping it to its final destination.

Create a Custom Script Library Item and enable it for Self Service, allowing the end-user or the IT admin configuring the Mac to click on the appropriate Department/Blueprint in Self Service to switch the enrolled Mac to that Blueprint.

### Dynamic Blueprint assignment
To assign a Mac to a Blueprint based on user group, department, job title, or another attribute, use conditional logic in the advanced Blueprint view.

See [Using Conditional Logic in Blueprints](https://docs.iru.com/en/endpoint/blueprints/assignment-maps/using-conditional-logic-in-blueprints) and [Advanced view](https://docs.iru.com/en/endpoint/blueprints/assignment-maps/creating-a-blueprint#advanced-view).

### Other
Any other scenario where you want to automate the switching of an enrolled Mac from one Blueprint to another. You can use it in a Library Item like in the examples above, where it will run locally on the Mac, or you can use the script on a VM for automation.
* One could leverage this script with some other logic to switch Blueprints based on any other available information (i.e. trigger after certain criteria are met using audit scripts, etc)

### New Device Enrollment Considerations
Running this script as part of an initial enrollment may interrupt agent runs in progress when it switches the Blueprint of a device.
If you’d like to switch Blueprints after a device initially enrolls into a default Blueprint, you can combine this script with [`installafterLiftoff`](https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff) to ensure the device changes Blueprints only after it has completed its initial enrollment.

## Troubleshooting
* **I'm getting an error**
  * Double-check that you're using a valid API token with the correction permissions and that your Iru subdomain is correct.
  * Check the output logs in the library item in Iru, or run `log show --style compact --process "logger" | grep "bp_switcher"` on the device that is running the script to view the logs.
