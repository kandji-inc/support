# Install After Liftoff

### About
This script can be used to trigger the execution of Library Items when Liftoff advances to the Complete Screen or is quit.  This can be useful for some security platforms that aggresively disrupt the network connectivity during install or require user interaction to complete.


### Considerations
If the execution of the library item does not need to happen immediately after Liftoff completes, it is advisable to keep it simple and put the snippet in the [Audit Script Modification section](#audit-script-modification) in your audit and enforce script and avoid using this custom script.


### Instructions
1. Download the [installAfterLiftoff.zsh](https://github.com/kandji-inc/support/blob/main/Scripts/install-after-liftoff/installAfterLiftoff.zsh) script
2. Edit the script variables (see [Script Modification](#script-modification) below)
3. Add the modified script to Kandji as a [Custom Script](https://support.kandji.io/kb/custom-scripts-overview) set to `Run once per device`
4. Modify the audit script of Custom Scripts or Custom Apps being triggered by Install After Liftoff (see [Audit Script Modification](#audit-script-modification) below)

### Script Modification
1. Update the `libraryItemList` variable with the display name or UUID of the Library Item(s) that you want to trigger. Place each item on a new line, in quotes.
2. By default, Install After Liftoff will run when Liftoff is quit. If you want it to run when Liftoff advances to the Complete Screen, change `startAtLiftoffQuit` to `false`.

```Shell
################################################################################################
########################################## VARIABLES ###########################################
################################################################################################
# List of Library Items that you want to execute
# You may use the Library Item display name, such as "Zscaler Connector" or the Library Item UUID
# such as "ad06b6ad-b90c-4308-b932-3c223b9e8880".
libraryItemList=(
        "Zscaler Connector"
        "VLC"
        "fb36e3c6-e748-40e8-b69d-15ece20a01d5"
    )

# By default, the install(s) will start once Liftoff has been quit. If you'd rather have the 
# install(s) start once Liftoff advances to the Complete Screen, change to this to "false".
startAtLiftoffQuit="true"
```

### Audit Script Modification
To ensure your Library Item does not install during Liftoff, you need to add a check to the beginning of your existing audit script for each Library Item being executed by Install After Liftoff.

- If you set the variable `startAtLiftoffQuit` to `true`, please include the following code snippet in each Library Item's Aduit Script in order for it to be skipped while Liftoff is running. The exit 0 will cause it to display as Completed in Liftoff to avoid user confusion. 

      if pgrep "Liftoff" > /dev/null; then
        echo "Liftoff is running, aborting process..."
        exit 0
      else
        echo "Liftoff is not running, continuing process..."
      fi

- If you set the variable `startAtLiftoffQuit` to `false`, please include the following code snippet in each Library Item's Aduit Script in order for it to be skipped while Liftoff has not advanced to the complete screen. The exit 0 will cause it to display as Completed in Liftoff to avoid user confusion. 

      if [[ -f /Library/LaunchAgents/io.kandji.Liftoff.plist ]] ; then
        echo "Liftoff has not completed yet, aborting process..."
        exit 0
      else
        echo "Liftoff is complete, continuing process..."
      fi

- For Library Items with an execution/installation set to `Run/Install on-demand from Self Service` no audit script changes are necessary.