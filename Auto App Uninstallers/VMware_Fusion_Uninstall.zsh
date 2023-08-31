#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
# Modified by Sean Burke | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 05/18/2022
# Updated on 08/30/2023
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Uninstaller script for VMWare Fusion
# NOTE: It is recommended you remove VMware from any Blueprints where this uninstaller is added
# NOTE: Failure to do so may result in VMware being reinstalled upon next Kandji agent check-in
# NOTE: If you have multiple versions of VMware Fusion installed on a device, running this
# script may adversely affect other installations
# Code will first kill any active VMware Fusion processes
# Next, if VMware Fusion application bundle exists in /Applications, it will be deleted
# Finally, iterates over all users with UID ≥ 500, populates their home directory paths,
# and confirms a user Library exists under the identified home directory by NFSHomeDirectory
# For users with valid user libraries, searches multiple paths for VMware pref folders/files
# If any are matched, they will be logged to stdout via echo and then recursively removed via rm
#
###################################################################################################
# License Information
###################################################################################################
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
###################################################################################################

# Modify below variable to reflect the versions desired for removal
versions_to_remove=(11 12)

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

##############################
########## VARIABLES #########
##############################

application_path="/Applications/VMware Fusion.app"
app_friendly_name="VMware Fusion"

###############
##### BODY ####
###############

# Populate array of users from DSCL with UID ≥500
dscl_users=($(/usr/bin/dscl /Local/Default -list /Users UniqueID | /usr/bin/awk '$2 >= 500 {print $1}'))

if [[ -e "${application_path}" ]]; then

    vmware_major_vers=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${application_path}"/Contents/Info.plist | /usr/bin/awk -F '.' '{print $1}')

    if [[ "${versions_to_remove[*]}" =~ ${vmware_major_vers} ]]; then

        # Kill App Processes
        /bin/echo "Killing any active ${app_friendly_name} processes..."
        /bin/ps aux | /usr/bin/grep -i "VMware Fusion.app" | /usr/bin/grep -v grep | /usr/bin/awk '{print $2}' | /usr/bin/xargs kill -9

        /bin/echo "Deleting application bundle for ${app_friendly_name}..."
        /bin/rm -f -R "${application_path}"

        for du in "${dscl_users[@]}"; do
            # Derive home directory value from DSCL attribute
            user_dir=$(/usr/bin/dscl /Local/Default -read "/Users/${du}" NFSHomeDirectory | /usr/bin/cut -d ":" -f2 | /usr/bin/xargs)

            # Confirm User Library dir exists
            if [[ -d "${user_dir}/Library" ]]; then
                /bin/echo "Valid user directory for ${du} at ${user_dir}"

                app_dirs=(
                    "${user_dir}/Library/Logs/VMware"
                    "${user_dir}/Library/Logs/VMware Fusion"
                    "${user_dir}/Library/Logs/VMware Fusion Applications Menu"
                    "${user_dir}/Library/Logs/VMware Graphics Service.log"
                    "${user_dir}/Library/Caches/com.vmware.fusion"
                    "${user_dir}/Library/Application Support/VMware Fusion"
                    "${user_dir}/Library/Application Support/VMware Fusion Applications Menu"
                    "${user_dir}/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.vmware.fusion.sfl*"
                    "${user_dir}/Library/Preferences/com.vmware.fusion.LSSharedFileList.plist"
                    "${user_dir}/Library/Preferences/com.vmware.fusion.LSSharedFileList.plist.lockfile"
                    "${user_dir}/Library/Preferences/com.vmware.fusionApplicationsMenu.helper.plist"
                    "${user_dir}/Library/Preferences/com.vmware.fusionApplicationsMenu.plist"
                    "${user_dir}/Library/Preferences/com.vmware.fusionDaemon.plist"
                    "${user_dir}/Library/Preferences/com.vmware.fusion.plist"
                    "${user_dir}/Library/Preferences/com.vmware.fusionDaemon.plist.lockfile"
                    "${user_dir}/Library/Preferences/com.vmware.fusionStartMenu.plist"
                    "${user_dir}/Library/Preferences/com.vmware.fusionStartMenu.plist.lockfile"
                    "${user_dir}/Library/Preferences/VMware Fusion"
                    "${user_dir}/Library/WebKit/com.vmware.fusion"
                    "${user_dir}/Library/Saved Application State/com.vmware.fusion.savedState"
                    "/Library/Application Support/VMware"
                    "/Library/Logs/VMware Fusion Services.log"
                    "/Library/Logs/VMware USB Arbitrator Service.log"
                    "/Library/Logs/VMware"
                    "/Library/Preferences/VMware Fusion"
                )

                # Iterate over array of the above user directories
                # If any paths are found, print match to stdout and delete them
                for dir in "${app_dirs[@]}"; do
                    if [[ -e "${dir}" ]]; then
                        /bin/echo "Removing ${dir}..."
                        /bin/rm -f -R "${dir}" 2>/dev/null
                    fi
                done
            fi
        done
        exit 0
    else
        /bin/echo "${app_friendly_name} was found, but is not a supported version for removal."
        exit 0
    fi
else
    /bin/echo "${app_friendly_name} not found, exiting."
    exit 0
fi
