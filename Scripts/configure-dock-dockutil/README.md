# configure-dock-dockutil

This script is designed to to configure a users dock using the Open-source tool, [dockutil](https://github.com/kcrawford/dockutil). You can add icons to an existing dock, or remove all of the current icons and replace them with a layout of your choosing. This script will download, install, and utilize [dockutil](https://github.com/kcrawford/dockutil) to configure the users dock. Once the script has configured a users dock, the default behavior is to uninstall dockutil. This option can be changed with the `REMOVE_DOCKUTIL` variable listed below. 

## Prepare the Script
You will need to make a few changes to the script in order to add the applications you want to the dock. Once done, you can copy this script directly into your Custom Script Library item. 

#### Variables
| Key | Response | Description |
| --- | --- | --- |
| `ERASE_DOCK` | `Y/N` | Do you want to remove all existing icons (`Y`) from the dock before adding new icons, or leave the current icons in place (`N`)? |
| `REMOVE_DOCKUTIL` | `Y/N` | Do you want to uninstall dockutil (`Y`) once done, or do you want to leave it behind (`N`) and use it again later? |
| `DOWNLOADS_FOLDER` | `Y/N` | Do you want to leave the downloads folder in the dock (`Y`) or remove it (`N`)? |
| `APPLICATION_LIST` | `"/Application Path/Application Name.app"` | Each new icon must be added on a new line using the same format in the example. Be sure to include quotes. 
| `SKIP_MISSING` | `Y/N` | If an application is missing, do you want to skip it (`Y`) and continue with the rest of the applications, or place a question mark (`?`) icon in the users dock before continuing.|
| `INSTALL_AFTER_LIFTOFF` | `Y/N` | If you are using this with [installAfterLiftoff.zsh](https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff) then choose yes. |
| `TRIGGER` | `COMPLETE/QUIT` | Do you want the script to run when Liftoff reaches the COMPLETE screen, or Liftoff has been QUIT? |

## Notes
* This script can be paired with [installAfterLiftoff.zsh](https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff) in order to ensure that it runs after all applications have been installed. 
* If using [installAfterLiftoff.zsh](https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff), please note that you can skip the "Audit Script Modification" instruction as this script already includes to required adjustments. 