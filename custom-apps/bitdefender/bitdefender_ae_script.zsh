#!/bin/zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2022-02-09
# Updated - 2025-05-08
################################################################################################
# Tested macOS Versions
################################################################################################
#
#    15.4.1
#    14.7.5
#    13.7.5
#    12.7.6
#
################################################################################################
# Software Information
################################################################################################
#
# This Audit and Enforce script is used to ensure that a specific Bitdefender
# configuration profile is installed and ensure that Bitdefender is running properly
# after installation.
#
# Configuration profiles are included with the Bitdefender deployment instructions
# found in the Kandji Knowledge Base.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2025 Kandji, Inc.
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
# shellcheck disable=SC2034
VERSION="1.1.0"

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Change the PAYLOAD_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. The profile prefix below is associated with the Notifications
# payload in the Kandji provided configuration profile.
PAYLOAD_ID_PREFIX="io.kandji.bitdefender.D0DF2C14"

# Service management profile prefix
# NOTE: this profile only contains managed backgroud settings for macOS 13+
# Change the SERVICE_MANAGEMENT_PREFIX variable to the profile prefix you want to wait
# on before running the installer.
SERVICE_MANAGEMENT_PREFIX="io.kandji.bitdefender.service-management"

# App info
# App name
APP_NAME="Endpoint Security for Mac.app"

# This is the name of the LaunchDaemon as it exists in /Library/LaunchDaemons
LAUNCH_DAEMONS=(
    "com.bitdefender.epsecurity.BDLDaemonApp"
    "com.epsecurity.bdldaemon"
)

########################################################################################
########################### FUNCTIONS - DO NOT MODIFY BELOW ############################
########################################################################################

profile_search() {
    # Look for a profile
    # $1 - payload payload uuid
    /usr/bin/profiles show | grep "$1" | sed 's/.*\ //'
}

# Fuction to determine the appropriate LaunchDaemon based on installed version of
# BitDefender
f_locate_daemon() {
    for DAEMON in ${LAUNCH_DAEMONS[@]}; do
        if [[ -e "/Library/LaunchDaemons/${DAEMON}.plist" ]]; then
            echo "${DAEMON}"
        fi
    done
}

# Fuction to determine the appropriate process identifier based on installed version of
# BitDefender
f_identify_process() {
    if [[ $1 == "com.bitdefender.epsecurity.BDLDaemonApp" ]]; then
        echo $1
    else
        echo "com.epsecurity.Daemon"
    fi
}

########################################################################################
###################################### MAIN LOGIC ######################################
########################################################################################

# All of the main logic be here ... modify at your own risk.

# Look for profile without KEXT payload
# The profiles_list variable will be set to an array of profiles that match the prefix
# in the PAYLOAD_ID_PREFIX variable
profiles_list=$(profile_search "$PAYLOAD_ID_PREFIX")

# Check to see if the profile ID prefix defined in $PAYLOAD_ID_PREFIX or
# $KEXT_PAYLOAD_ID_PREFIXis installed. If both lists are empty, exit 0 to wait for the
# next agent run.
if [[ ${#profiles_list[@]} -eq 0 ]]; then
    /bin/echo "Settings profile not found ..."
    /bin/echo "Waiting until the profile is installed before proceeding ..."
    /bin/echo "Will check again at the next Kandji agent check-in ..."
    exit 0
fi

/bin/echo "$APP_NAME Settings profile with prefix ($PAYLOAD_ID_PREFIX) is installed ..."

# macOS Version
osvers_major="$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F '.' '{print $1}')"

# macOS Ventura(13.0) or newer - this is for the managed background settings profile.
if [[ "${osvers_major}" -ge 13 ]]; then
    # The profiles variable will be set to an array of profiles that match the prefix in
    # the SERVICE_MANAGEMENT_PREFIX variable
    profiles=$(profile_search "$SERVICE_MANAGEMENT_PREFIX")

    # If matching profiles are found exit 1 so the installer will run, else exit 0 to
    # wait
    if [[ ${#profiles[@]} -eq 0 ]]; then
        /bin/echo "No profiles with ID $SERVICE_MANAGEMENT_PREFIX were found ..."
        /bin/echo "Will check again at the next Kandji agent check in before moving on ..."
        exit 0
    fi

    /bin/echo "Profile prefix $SERVICE_MANAGEMENT_PREFIX present ..."
fi

# This command looks in /Applications, /System/Applications, and /Library for the
# existence of the app defined in $APP_NAME. It will also exclude anything in
# StagedExtensions as this is where KEXT are staged
installed_path="$(/usr/bin/find /Applications /System/Applications /Library \
    -not -path '*StagedExtensions*' -maxdepth 3 -name $APP_NAME 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e "$installed_path" ]] || [[ "$APP_NAME" != "$(/usr/bin/basename "$installed_path")" ]] && [[ -n "$(/usr/bin/dirname "$installed_path")" ]]; then
    /bin/echo "$APP_NAME not installed. Starting installation process ..."
    exit 1

else
    # Get the installed app version
    installed_version=$(/usr/bin/defaults read "$installed_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    # make sure we got a version number back
    if [[ -n "$installed_version" ]]; then
        /bin/echo "$APP_NAME version $installed_version is installed at \"$installed_path\"..."
    else
        /bin/echo "$APP_NAME is installed at \"$installed_path\"..."
    fi
fi

# Get appropriate LaunchDaemon process
process_daemon=$(f_locate_daemon)

# verify that a process was returned otherwise reinstall the app.
if [[ -z ${process_daemon} ]]; then
    /bin/echo "Unable to locate Agent ..."
    /bin/echo "Re installing \"$APP_NAME\""
    exit 1
fi

# get the correct process for the version of BitDefender
process_label=$(f_identify_process "${process_daemon}")

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
            /bin/echo "Agent is loaded but not running..."
            /bin/echo "Attempting to start..."
            /bin/launchctl start "$process_label"
        else
            /bin/echo "Agent not loaded..."
            /bin/echo "Attempting to reload..."
            /bin/launchctl load "/Library/LaunchDaemons/$process_daemon.plist"
        fi

        # Get the PID
        process_id="$(/bin/launchctl list | /usr/bin/grep $process_label | /usr/bin/cut -f 1)"

        # Check to see if the agent loaded successfully
        if [[ -n "$process_id" ]]; then
            /bin/echo "$process_label($process_id) agent loaded successfully .."

        else
            /bin/echo "Failed to load $process_label agent..."
            /bin/echo "Will try again..."

            /bin/sleep 3

            # Increment counter
            ((loop_counter++))

            if [[ "$loop_counter" -gt 5 ]]; then
                /bin/echo "Unable to load the agent successfully..."
                /bin/echo "Re installing \"$APP_NAME\""
                exit 1
            fi
        fi
    else
        # Agent is running
        /bin/echo "$process_label($process_id) is running..."
    fi
done

# Everything checks out
/bin/echo "\"$APP_NAME\" appears to be running properly..."
/bin/echo "Nothing to do ..."

exit 0
