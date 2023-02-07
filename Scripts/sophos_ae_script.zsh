#!/bin/zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 06/09/2021
# Updated - 2022-01-30 - Matt Wilson
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   12.3
#   11.6.2
#   10.15.7
#
################################################################################################
# Software Information
################################################################################################
#
# This Audit and Enforce script is used to ensure that a specific Bitdefender configuration
# profile is installed and ensure that Bitdefender is running properly after installation.
#
# Configuration profiles are included with the Bitdefender deployment instructions found in the
# Kandji Knowledge Base.
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

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# This is the profile ID that contains all settings.
# This prefix exists in the KEXT and kextless version of the settings profile
PAYLOAD_ID_PREFIX="io.kandji.sophos.EA69037E"

# Service management profile prefix
# NOTE: this profile only contains managed backgroud settings for macOS 13+
# Change the SERVICE_MANAGEMENT_PREFIX variable to the profile prefix you want to wait
# on before running the installer.
SERVICE_MANAGEMENT_PREFIX="io.kandji.sophos.service-management"

# App info
APP_NAME="Sophos Endpoint.app"

################################################################################################
##################################### FUNCTIONS ################################################
################################################################################################

profile_search() {
    # Look for a profile
    # $1 - payload payload uuid
    /usr/bin/profiles show | grep "$1" | sed 's/.*\ //'
}

################################################################################################
###################################### MAIN LOGIC ##############################################
################################################################################################

# All of the main logic be here ... modify at your own risk.

# Look for the app defined in APP_NAME
/bin/echo "Auditing $APP_NAME..."

# The profiles_list variable will be set to an array of profiles that match the prefix
# in the PAYLOAD_ID_PREFIX variable
profiles_list=$(profile_search "$PAYLOAD_ID_PREFIX")

# Check to see if the profile ID prefix defined in $PAYLOAD_ID_PREFIX. If not found the script
# will exit and check again at next agent checkin.
if [[ ${#profiles_list[@]} -eq 0 ]]; then
    /bin/echo "Settings profile not found ..."
    /bin/echo "Waiting until the profile is installed before proceeding ..."
    /bin/echo "Will check again at the next Kandji agent check-in ..."
    exit 0
fi

/bin/echo "$APP_NAME Settings profile is installed ..."

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
# existance of the app defined in $APP_NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name "$APP_NAME" 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e $installed_path ]] || [[ $APP_NAME != "$(/usr/bin/basename "$installed_path")" ]]; then
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

exit 0
