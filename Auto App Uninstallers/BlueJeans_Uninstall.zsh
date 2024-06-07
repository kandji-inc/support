#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 06/07/2024
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Uninstaller script for BlueJeans
# Code will first locate install(s) of BlueJeans by bundle identifier
# Kills any active BlueJeans processes
# Next, if BlueJeans application bundle exists in /Applications, it will be deleted
# Finally, iterates over all users with UID ≥ 500, populates their home directory paths,
# and confirms a user Library exists under the identified home directory by NFSHomeDirectory
# For users with valid user libraries, searches multiple paths for BlueJeans pref folders/files
# If any are matched, they will be logged to stdout via echo and then recursively removed via rm
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2024 Kandji, Inc.
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

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

##############################
########## VARIABLES #########
##############################

application_bundle_id="com.bluejeansnet.Blue"
app_friendly_name="BlueJeans"

###############
##### BODY ####
###############

# Populate array of users from DSCL with UID ≥500
dscl_users=($(/usr/bin/dscl /Local/Default -list /Users UniqueID | /usr/bin/awk '$2 >= 500 {print $1}'))

# Find via bundle ID using mdfind; sort to bring shortest path (if multiple) to top and assign
application_path=$(/usr/bin/mdfind "kMDItemCFBundleIdentifier == '${application_bundle_id}'" | /usr/bin/sort | /usr/bin/head -1)
if [[ -z ${application_path} ]]; then
    # Search /Applications for app bundle dir structures, match on BID from Info.plists and assign matching app (if any)
    info_plist_path=$(/usr/bin/find /Applications -maxdepth 4 -path "*\.app/Contents/Info.plist" -print0 -exec /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "{}" \; 2>/dev/null | /usr/bin/grep -a "${application_bundle_id}" | /usr/bin/sed -n "s/${application_bundle_id}$//p")
    # Shell built-in to lop off two sub dirs
    application_path=${info_plist_path%/*/*}
fi
if [[ -z ${application_path} ]]; then
    application_path="/Applications/BlueJeans.app"
fi

if [[ -d "${application_path}" ]]; then

    echo "Located installed ${app_friendly_name} at ${application_path}..."
    # Kill App Processes
    echo "Killing any active ${app_friendly_name} processes..."
    /usr/bin/lsappinfo info $(/usr/bin/lsappinfo find bundleid=${application_bundle_id}) -only pid | /usr/bin/cut -d '=' -f2 | /usr/bin/xargs kill -9

    # Remove App from Dock
    /usr/local/bin/kandji dock --remove ${application_bundle_id}

    echo "Deleting application bundle for ${app_friendly_name}..."
    /bin/rm -f -R "${application_path}"

    for du in "${dscl_users[@]}"; do
        # Derive home directory value from DSCL attribute
        user_dir=$(/usr/bin/dscl /Local/Default -read "/Users/${du}" NFSHomeDirectory | /usr/bin/cut -d ":" -f2 | /usr/bin/xargs)

        # Confirm User Library dir exists
        if [[ -d "${user_dir}/Library" ]]; then
            echo "Valid user directory for ${du} at ${user_dir}"

            lagents=(
                "${user_dir}/Library/LaunchAgents/com.bluejeansnet.BlueJeansHelper.plist"
                "${user_dir}/Library/LaunchAgents/com.bluejeansnet.BlueJeansMenu.plist"
            )

            app_dirs=(
                "${user_dir}/Library/Application Support/com.bluejeansnet.Blue"
                "${user_dir}/Library/Application Support/BlueJeans"
                "${user_dir}/Library/Caches/com.bluejeansnet.Blue"
                "${user_dir}/Library/HTTPStorages/com.bluejeansnet.Blue"
                "${user_dir}/Library/Logs/BlueJeans"
                "${user_dir}/Library/Preferences/com.bluejeansnet.Blue.plist"
                "${user_dir}/Library/Saved Application State/com.bluejeansnet.Blue.savedState"
            )

            # Locate active launch procs under user context, bootout if found
            /bin/launchctl print ${application_bundle_id} 2>&1  | /usr/bin/grep gui | /usr/bin/xargs -I {} /bin/launchctl bootout "{}"
            # Iterate over array of the above LaunchAgents 
            # If any are found, print match to stdout then unload and remove
            for lagent in "${lagents[@]}"; do
                if [[ -f "${lagent}" ]]; then
                    echo "Removing ${lagent}..."
                    /bin/rm -f "${lagent}" 2>/dev/null
                fi
            done

            # Iterate over array of the above user directories
            # If any paths are found, print match to stdout and delete them
            for dir in "${app_dirs[@]}"; do
                if [[ -e "${dir}" ]]; then
                    echo "Removing ${dir}..."
                    /bin/rm -f -R "${dir}" 2>/dev/null
                fi
            done
        fi
    done
    exit 0
else
    echo "${app_friendly_name} not found, exiting."
    exit 0
fi
