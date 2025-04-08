#!/bin/zsh

########################################################################################
# Created by Danny Hanes | support@kandji.io | Kandji, Inc.
########################################################################################
#
#   Created - 2023-06-27 [v1.0.0]
#   Updated - 2023-10-13 [v1.0.1]
#           - Tested on 13.4.1
#   Updated - 2024-08-27 [v1.2.0]
#           - Updated to run as the user instead of root
#           - Tested on 14.5 & 14.6.1
#           - New function for installAfterLiftoff support
#
########################################################################################
# Tested macOS Versions
########################################################################################
#
#   - 13.4
#   - 13.4.1
#   - 14.0
#   - 14.5
#   - 14.6.1
#
########################################################################################
# Software Information
########################################################################################
#
#   This script will download and install dockutil, an open source utilty used to configure
#   a users dock on the mac. Once installed, dockutil will remove all existing icons and add
#   the list of icons listed by the admin based on the configurations provided below.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2023 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
################################################################################################

# Script version
# VERSION="1.2.0"

########################################################################################
######################## INSTALL AFTER LIFTOFF VARIABLES ###############################
########################################################################################

# If you plan to use installAfterLiftoff.zsh, then set the variables below and skip
# the "Audit Script Modification" step of the documentation. 

# Set INSTALL_AFTER_LIFTOFF to Y if you are using installAfterLiftoff.zsh
INSTALL_AFTER_LIFTOFF="Y"

# Do you want the script to run when Liftoff reaches the COMPLETE screen, or Liftoff has been QUIT?
TRIGGER="COMPLETE"

########################################################################################
################################# USER VARIABLES #######################################
########################################################################################

# Do you want to remove the existing dock icons before adding new ones (Y/N)
ERASE_DOCK="Y"

# Do you want to remove dockutil from the computer once complete (Y/N)
REMOVE_DOCKUTIL="Y"

# Do you want to keep the downloads folder in the dock (Y/N)
DOWNLOADS_FOLDER="Y"

# Complete path of applications to add to the dock, new line per application
APPLICATION_LIST=(
        "/Applications/Google Chrome.app"
        "/System/Applications/Music.app"
        "/System/Applications/Notes.app"
        "/System/Applications/Reminders.app"
        "/Applications/Kandji Self Service.app"
    )

# If an application has not yet been installed, do you want to skip that application, or 
# place a question mark icon in the dock? 
SKIP_MISSING="Y"

########################################################################################
################################# SCRIPT VARIABLES #####################################
########################################################################################

dockutilBinary="/usr/local/bin/dockutil"
dockutilURL="https://api.github.com/repos/kcrawford/dockutil/releases/latest"
dockutilInstaller="/var/tmp/dockutil.pkg"
dockutilTeamID="Z5J8CJBUWC"
version=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F '.' '{print $1}')
currentUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')
userHome=$(/usr/bin/dscl . -read /users/${currentUser} NFSHomeDirectory | /usr/bin/cut -d " " -f 2)
plist="${userHome}/Library/Preferences/com.apple.dock.plist"
uid=$(/usr/bin/id -u "${currentUser}")

########################################################################################
####################### FUNCTIONS - DO NOT MODIFY BELOW ################################
########################################################################################


logging(){
    # Set logging - Send logs to stdout as well as Unified Log
    # Usage: logging "LEVEL" "Message..."
    # Use 'log show --process "logger"'to view logs activity.
  script_id="assign_user_passport"
  timestamp=$(/bin/date +"%m-%d-%Y %H:%M:%S")
  
  echo "${timestamp} ${1}: ${2}"
  /usr/bin/logger "${script_id}: [${1}] ${2}"
}

runAsUser() {  
	if [[ "${currentUser}" != "loginwindow" ]]; then
		/bin/launchctl asuser "$uid" /usr/bin/sudo -u "${currentUser}" "$@"
        logging "INFO" "Running as the user: $currentUser"
	else
		logging "INFO" "No logged in user."
		exit 1
	fi
}

liftoffCheck () {

    if [[ "$INSTALL_AFTER_LIFTOFF" == "Y" && "$TRIGGER" == "COMPLETE" ]]; then
        logging "INFO" "Script will run after Liftoff completes."
        if [[ -f /Library/LaunchAgents/io.kandji.Liftoff.plist ]]; then
            logging "INFO" "Liftoff is still running..."
            exit 0
        fi
    elif [[ "$INSTALL_AFTER_LIFTOFF" == "Y" && "$TRIGGER" == "QUIT" ]]; then
        logging "INFO" "Script will run after Liftoff closes"
        if pgrep "Liftoff" > /dev/null; then
            logging "INFO" "Liftoff is running, aborting process..."
            exit 0
        fi
    else
        logging "INFO" "Script is configured to run immediately."
    fi

}

installDockutil () {

    if [[ ! -f "$dockutilBinary" ]]; then
        logging "INFO" "Downloading and installing dockutil..."
        url=$(/usr/bin/curl -s $dockutilURL | /usr/bin/grep "download_url" | /usr/bin/awk '{print $2}' | /usr/bin/tr -d '"')
        /usr/bin/curl -L -o "$dockutilInstaller" "$url"
        
        packageID="$(/usr/sbin/pkgutil --check-signature "${dockutilInstaller}" | sed -n -e 's/^.*Developer ID Installer: //p' | sed -e 's/.*(\(.*\)).*/\1/;s/,//g')"

        if [[ "${packageID}" != "${dockutilTeamID}" ]]; then
            logging "ERROR" "Signature check failed..."
            logging "INFO" "Expected Team ID was ${dockutilTeamID}; got ${packageID}"
            exit 1
        fi
        
        /usr/bin/sudo installer -pkg "$dockutilInstaller" -target /

        if [[ ! -f "$dockutilBinary" ]]; then
            logging "ERROR" "Installation failed, exiting..."
            exit 1
        else
            logging "INFO" "Dockutil successfully installed"
        fi
    else
        logging "INFO" "Dockutil already installed"
    fi
}

configureDock () {
    oldIFS=${IFS}
    IFS=','
    if [[ "$ERASE_DOCK" == "Y" ]]; then
        logging "INFO" "Resetting the dock..."
        runAsUser "$dockutilBinary" --remove all --no-restart ${plist}
    fi

    for app in ${APPLICATION_LIST[@]}; do
    
        if [[ $app == "/Applications/Safari.app" ]] && [[ $version -gt 12 ]]; then
            app="/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        fi
        
        if [[ ! -d $app ]] && [[ "$SKIP_MISSING" == "Y" ]]; then
            logging "INFO" "$app does not exist; skipping"
        else
            runAsUser "${dockutilBinary}" --add "$app" --no-restart ${plist}
        fi
    done

    if [[ "$DOWNLOADS_FOLDER" == "Y" ]]; then
        runAsUser "${dockutilBinary}" --add ${userHome}/Downloads --no-restart ${plist}
    fi
    
    /bin/sleep 1
    /usr/bin/killall Dock
    IFS="${oldIFS}"
}

cleanup () {

    if [[ "$REMOVE_DOCKUTIL" == "Y" && -f "$dockutilBinary" ]]; then
        logging "INFO" "Removing dockutil..."
        rm "$dockutilBinary"
    fi
    
    rm "$dockutilInstaller"

}

liftoffCheck
installDockutil
configureDock
cleanup

exit 0