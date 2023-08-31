#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 05/18/2022
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Uninstaller script for 1Password 7 (1PW7)
# NOTE: It is recommended you remove 1PW7 from any Blueprints where this uninstaller is added
# NOTE: Failure to do so may result in 1PW7 being reinstalled upon next Kandji agent checkin
# Code will first kill any active 1PW7 processes
# Next, if 1PW7 application bundle exists in /Applications, it will be deleted
# Finally, iterates over all users with UID ≥ 500, populates their home directory paths,
# and confirms a user Library exists under the identified home directory by NFSHomeDirectory
# For users with valid user libraries, searches 10 different paths for 1PW7 pref folders/files
# If any are matched, they will be logged to stdout via echo and then recursively removed via rm
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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

onepw_seven_path="/Applications/1Password 7.app"

###############
##### BODY ####
###############

# Populate array of users from DSCL with UID ≥500
dscl_users=($(/usr/bin/dscl /Local/Default -list /Users UniqueID | /usr/bin/awk '$2 >= 500 {print $1}'))

# Kill 1PW7 Processes
/bin/echo "Killing any active 1Password 7 processes..."
/bin/ps aux | /usr/bin/grep -i "1Password 7.app\|onepassword7" | /usr/bin/grep -v grep | /usr/bin/awk '{print $2}' | /usr/bin/xargs kill -9

if [[ -e "${onepw_seven_path}" ]]; then
    /bin/echo "Deleting application bundle for 1Password 7..."
    /bin/rm -f -R "${onepw_seven_path}"
fi

for du in "${dscl_users[@]}"; do
    # Derive home directory value from DSCL attribute
    user_dir=$(/usr/bin/dscl /Local/Default -read "/Users/${du}" NFSHomeDirectory | /usr/bin/cut -d ":" -f2 | /usr/bin/xargs)

    # Confirm User Library dir exists
    if [[ -d "${user_dir}/Library" ]]; then
        /bin/echo "Valid user directory for ${du} at ${user_dir}"

        onepw_dirs=(
            "${user_dir}/Library/Application Scripts/com.agilebits.onepassword7-launcher"
            "${user_dir}/Library/Application Scripts/com.agilebits.onepassword7"
            "${user_dir}/Library/Application Scripts/com.agilebits.onepassword7.1PasswordSafariAppExtension"
            "${user_dir}/Library/Group Containers/2BUA8C4S2C.com.agilebits"
            "${user_dir}/Library/Containers/com.agilebits.onepassword7"
            "${user_dir}/Library/Containers/com.agilebits.onepassword7-launcher"
            "${user_dir}/Library/Containers/com.agilebits.onepassword7.1PasswordSafariAppExtension"
            "${user_dir}/Library/Containers/2BUA8C4S2C.com.agilebits.onepassword7-helper"
            "${user_dir}/Library/Preferences/com.agilebits.onepassword7.plist"
            "${user_dir}/Library/Preferences/Application Support/com.agilebits.onepassword7"
        )

        # Iterate over array of the above user directories
        # If any paths are found, print match to stdout and delete them
        for dir in "${onepw_dirs[@]}"; do
            if [[ -e "${dir}" ]]; then
                /bin/echo "Removing ${dir}..."
                /bin/rm -f -R "${dir}" 2>/dev/null
            fi
        done
    fi
done

exit 0
