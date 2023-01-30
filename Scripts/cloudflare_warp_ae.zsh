#!/usr/bin/env zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created on 2021-07-30
# Updated on 2022-06-09
# Updated on 2022-12.02
# Updated on 2023-01-25 - Matt Wilson
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.2
#   12.6.1
#   11.6.5
#
################################################################################################
# Software Information
################################################################################################
#
#   This Audit & Enfrce script checks for the presence of an app to see if it is
#   installed on a Mac. Optionally, a MINIMUM_ENFORCED_VERSION can be set, which tells
#   this script to compare an
#   installed app version to the minimum enforced app version set in the script the
#   isntalled version of the provided APP_NAME. If the app cannot be found an installed
#   version of "None" is returned.
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

# zsh has a built-in operator that can actually do float compares; just gotta load it
autoload is-at-least

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# App info
APP_NAME="Cloudflare WARP.app"

# If you would like to enforce a minimum version, be sure to update the
# MINIMUM_ENFORCED_VERSION variable with the version number that the audit script
# should enforce. (Example version number 1.5.207.0). If MINIMUM_ENFORCED_VERSION is
# left blank, the audit script will not check for a version and will only check for the
# presence of the app. MINIMUM_ENFORCED_VERSION="5.7.6 (1321)"
MINIMUM_ENFORCED_VERSION=""

# Change the PROFILE_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. The profile prefix below is associated with the settings
# profile Kandji provided configuration profile.
PROFILE_ID_PREFIX="io.kandji.cloudflare.EC275B21-ECA0"

# Service management profile prefix
# NOTE: this profile only contains managed backgroud settings for macOS 13+
# Change the SERVICE_MANAGEMENT_PREFIX variable to the profile prefix you want to wait
# on before running the installer.
SERVICE_MANAGEMENT_PREFIX="io.kandji.cloudflare.service-management"

########################################################################################
##################################### FUNCTIONS ########################################
########################################################################################

profile_search() {
    # Look for a profile
    # $1 - payload payload uuid
    /usr/bin/profiles show | grep "$1" | sed 's/.*\ //'
}

########################################################################################
###################################### MAIN LOGIC ######################################
########################################################################################

# The profiles variable will be set to an array of profiles that match the prefix in
# the PROFILE_ID_PREFIX variable
profiles=$(profile_search "$PROFILE_ID_PREFIX")

# If matching profiles are found exit 1 so the installer will run, else exit 0 to wait
if [[ ${#profiles[@]} -eq 0 ]]; then
    /bin/echo "No profiles with ID $PROFILE_ID_PREFIX were found ..."
    /bin/echo "Will check again at the next Kandji agent check in before moving on ..."
    exit 0
fi

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
if [[ ! -e "$installed_path" ]] || [[ "$APP_NAME" != "$(/usr/bin/basename "$installed_path")" ]]; then
    /bin/echo "$APP_NAME not installed. Starting installation process ..."
    exit 1
else
    /bin/echo "$APP_NAME installed at $installed_path"
fi

# Check to see if the script is configured to enforce a minimum version
if [[ -z $MINIMUM_ENFORCED_VERSION ]]; then
    /bin/echo "This A&E script is not configured to check for a Minimum Enforced Version ..."
else
    # Get the installed app version
    installed_version=$(/usr/bin/defaults read "$installed_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    # make sure we got a version number back
    if [[ -z "$installed_version" ]]; then
        /bin/echo "App version could not be determined. Reinstalling $APP_NAME ..."
        exit 1
    fi

    # Compare minimum enforced version to installed version using the zsh builtin operator is-at-least
    version_check="$(is-at-least "$MINIMUM_ENFORCED_VERSION" "$installed_version" && /bin/echo "greater than or equal to" || /bin/echo "less than")"

    if [[ $version_check == *"less"* ]]; then
        /bin/echo "Installed version \"$installed_version\" is $version_check min enforced version \"$MINIMUM_ENFORCED_VERSION\" ..."
        /bin/echo "Upgrading $APP_NAME ..."
        exit 1
    else
        /bin/echo "Installed version \"$installed_version\" is $version_check min enforced version \"$MINIMUM_ENFORCED_VERSION\" ..."
        /bin/echo "Nothing to do ..."
        exit 0
    fi
fi
