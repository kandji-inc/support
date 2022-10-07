#!/bin/zsh

########################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
########################################################################################
# Created - 2022-02-09
# Updated - 2022-07-19
########################################################################################
# Tested macOS Versions
########################################################################################
#
#   12.4
#   11.6.6
#   10.15.7
#
########################################################################################
# Software Information
########################################################################################
#
# This Audit and Enforce script is used to ensure that a specific Bitdefender
# configuration profile is installed and ensure that Bitdefender is running properly
# after installation.
#
# Configuration profiles are included with the Bitdefender deployment instructions
# found in the Kandji Knowledge Base.
#
########################################################################################
# License Information
########################################################################################
# Copyright 2022 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
########################################################################################
# CHANGELOG
########################################################################################
#
#   1.0.0
#       - Original Script
#
#   1.0.1
#       - Code refactor
#           - Added PROCESS_LABELS variable with array of LaunchDaemons to check
#             against depending on which version of BitDefender is being deployed
#			- Added f_LOCATE_DAEMON fuction to locate the appropriate LaunchDaemon for
#             in installed version of BitDefender
#			- Added f_IDENTIFY_PROCESS fuction to determine the appropriate process
#             identifier to ensure BitDefender is running depending on deployed version
#			- Added logic if either of the defined LaunchDaemons are not located to
#             reinstall the Bitdefender app.
#
#   1.0.2
#       - Removed hidden space chars.
#
########################################################################################

# Script version
VERSION="1.0.2"

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Change the PROFILE_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. The profile prefix below is associated with the Notifications
# payload in the Kandji provided configuration profile.
PROFILE_ID_PREFIX="io.kandji.bitdefender.D0DF2C14"

# Make sure that the app name matches the name of the app that will be installed. This
# script will dynamically search for the app in the Applications folder. So there is no
# need to define an app path. The app must install in the /Applications, "/System/
# Applications", or /Library up to 3 sub-directories deep.
APP_NAME="Endpoint Security for Mac.app"

# This is the name of the LaunchDaemon as it exists in /Library/LaunchDaemons
LAUNCH_DAEMONS=(
    "com.bitdefender.epsecurity.BDLDaemonApp"
    "com.epsecurity.bdldaemon"
)

########################################################################################
########################### FUNCTIONS - DO NOT MODIFY BELOW ############################
########################################################################################

# Fuction to determine the appropriate LaunchDaemon based on installed version of
# BitDefender
f_LOCATE_DAEMON() {
    for DAEMON in ${LAUNCH_DAEMONS[@]}; do
        if [[ -e "/Library/LaunchDaemons/${DAEMON}.plist" ]]; then
            echo "${DAEMON}"
        fi
    done
}

# Fuction to determine the appropriate process identifier based on installed version of
# BitDefender
f_IDENTIFY_PROCESS() {
    if [[ $1 == "com.bitdefender.epsecurity.BDLDaemonApp" ]]; then
        echo $1
    else
        echo "com.epsecurity.Daemon"
    fi
}

########################################################################################
###################################### MAIN LOGIC ######################################
########################################################################################

# The profiles variable will be set to an array of profiles that match the prefix in
# the PROFILE_ID_PREFIX variable
profiles=$(/usr/bin/profiles show | grep "$PROFILE_ID_PREFIX" | sed 's/.*\ //')

# If matching profiles are found exit 1 so the installer will run, else exit 0 to wait
if [[ ${#profiles[@]} -eq 0 ]]; then
    echo "No profiles with ID $PROFILE_ID_PREFIX were found ..."
    echo "Will check again at the next Kandji agent check in before moving on ..."
    exit 0
fi

echo "Profile prefix $PROFILE_ID_PREFIX present ..."

# Look for the app defined in APP_NAME
# This command looks in /Applications, /System/Applications, and /Library for the
# existance of the app defined in $APP_NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name $APP_NAME 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e $installed_path ]] || [[ $APP_NAME != "$(/usr/bin/basename $installed_path)" ]]; then
    echo "\"$APP_NAME\" not installed. Starting installation process ..."
    exit 1

else
    # Get the installed app version
    installed_version=$(/usr/bin/defaults read "$installed_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    # see if a version was returned otherwise just return the install path
    if [[ $? -eq 0 ]]; then
        /bin/echo "\"$APP_NAME\" version $installed_version is installed at \"$installed_path\"..."
    else
        /bin/echo "\"$APP_NAME\" is installed at \"$installed_path\"..."
    fi
fi

# Get appropriate LaunchDaemon process
process_daemon=$(f_LOCATE_DAEMON)

# verify that a process was returned otherwise reinstall the app.
if [[ -z ${process_daemon} ]]; then
    echo "Unable to locate Agent ..."
    echo "Re installing \"$APP_NAME\""
    exit 1
fi

# get the correct process for the version of BitDefender
process_label=$(f_IDENTIFY_PROCESS "${process_daemon}")

# Get the PID
process_id=""
loop_counter=0

# Loop until the PID is found or we have checked the status 5 times
while [[ "$process_id" == "" ]] && [[ "$loop_counter" -lt 6 ]]; do

    # Get the PID
    process_id="$(/bin/launchctl list | /usr/bin/grep $process_label | /usr/bin/cut -f 1)"

    # If no PID is returned, try to reload the process.
    if [[ -z "$process_id" ]] || [[ "$process_id" == "-" ]]; then

        if [[ "$process_id" == "-" ]]; then
            echo "Agent is loaded but not running..."
            echo "Attempting to start..."
            /bin/launchctl start "$process_label"
        else
            echo "Agent not loaded..."
            echo "Attempting to reload..."
            /bin/launchctl load "/Library/LaunchDaemons/$process_daemon.plist"
        fi

        # Get the PID
        process_id="$(/bin/launchctl list | /usr/bin/grep $process_label | /usr/bin/cut -f 1)"

        # Check to see if the agent loaded successfully
        if [[ -n "$process_id" ]]; then
            echo "$process_label($process_id) agent loaded successfully .."

        else
            echo "Failed to load $process_label agent..."
            echo "Will try again..."

            /bin/sleep 3

            # Increment counter
            ((loop_counter++))

            if [[ "$loop_counter" -gt 5 ]]; then
                echo "Unable to load the agent successfully..."
                echo "Re installing \"$APP_NAME\""
                exit 1
            fi
        fi
    else
        # Agent is running
        echo "$process_label($process_id) is running..."
    fi
done

# Everything checks out
echo "\"$APP_NAME\" appears to be running properly..."
echo "Nothing to do ..."

exit 0
