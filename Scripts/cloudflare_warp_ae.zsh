#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | se@kandji.io | Kandji, Inc. | Solutions Engineering
###################################################################################################
# Created - 07/30/2021
# Updated - 10/22/2021
###################################################################################################
# Software Information
###################################################################################################
# This script is designed to check if an application is present. If the app is present, the
# script will check to see if a minimum version is being enforced. If a minimum app version is not
# being enforced, the script will only check to see if the app is installed or not.
###################################################################################################
# License Information
###################################################################################################
# Copyright 2021 Kandji, Inc.
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

# Script version
VERSION="1.1.0"

# zsh has a built-in operator that can actually do float compares; just gotta load it
autoload is-at-least

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################
# If you would like to enforce a minimum version, be sure to update the MINIMUM_ENFORCED_VERSION
# variable with the version number that the audit script should enforce. (Example version number
# 1.5.207.0). If MINIMUM_ENFORCED_VERSION is left blank, the audit script will not check for a
# version and will only check for the presence of the Cloudflare WARP app at the defined APP_PATH.
# MINIMUM_ENFORCED_VERSION="5.7.6 (1321)"
MINIMUM_ENFORCED_VERSION="1.6.27.0"

###################################################################################################

# Make sure that the application matches the name of the app that will be installed.
# This script will dynamically search for the application in the Applications folder. So
# there is no need to define an application path. The app must either install in the
# Applications folder or up to 3 sub-directories deep.
#   For example /System/Applications/Utilities/Terminal.app
# APP_NAME="zoom.us.app"
APP_NAME="Cloudflare WARP.app"

# Change the PROFILE_PAYLOAD_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. If the profile is not found, this audit and enforce script will exit 00
# and do nothing until the next kandji agent check-in.
PROFILE_PAYLOAD_ID_PREFIX="io.kandji.cloudflare.C59FD676"

###################################################################################################
###################################### FUNCTIONS ##################################################
###################################################################################################

app_search() {
    # Search for an app. If found return the path to the app otherwise return "None"
    #
    #   The application must exist on the local Mac and the name of the app must match the
    #   application that is passed to the function. If any of these conditions are not met the
    #   function will return of "None"
    #
    # $1 - Is the name of the application.
    local app_name="$1"
    local app_path=""

    # Uses the find binary to look for the app inside of the /Applications and /System/
    # Applications directories up to 2 levels deep.
    app_path="$(/usr/bin/find /Applications /System/Applications -maxdepth 2 -name $app_name)"

    # Check to see if the app is installed.
    if [[ ! -e "$app_path" ]] || [[ "$app_name" != "$(/usr/bin/basename $app_path)" ]]; then
        # If the previous command returns true and the returned object exists and the app name
        # that we are looking for is exactly equal to the app name found by the find command.
        app_path="None"
    fi

    # Return the value of app_path
    echo "$app_path"
}

return_installed_app_version() {
    # Return the currently installed application version
    local path="$1"
    local inst_vers=""

    inst_vers=$(/usr/bin/defaults read "$path/Contents/Info.plist" CFBundleShortVersionString)

    if [[ "$?" -ne 0 ]]; then
        #statements
        inst_vers="None"
    fi

    echo "$inst_vers"
}

sanitize_app_version_number() {
    # Make sure the app version number is in a form that can be used for comparison
    #
    # version_number: $1 is the first parameter passed to the function. It represents an
    #                 Application's version number. The version number can be obtained
    #                 programatically or manually passed to this function.
    local version_number="$1"
    local santized_version

    # rem ( with: s/[`(]//g'
    # rem ) with: s/[`)]//g'
    santized_version="$(echo $version_number | /usr/bin/sed -e 's/[[:space:]]//g' -e 's/[`(]/./g' -e 's/[`)]//g' -e 's/[`-]/./g')"

    echo "$santized_version"
}

vers_check() {
    # is-at-least is a zsh built-in for float math
    # returns exit 0 for true, exit 1 for false, so we can use || OR separators here
    is-at-least "$1" "$2" && echo "greater than or equal to" || echo "less than"
}

###################################################################################################
###################################### MAIN LOGIC #################################################
###################################################################################################

# All of the main logic be here ... modify at your own risk.

# The profiles variable will be set to an array of profiles that match the prefix in
# the PROFILE_PAYLOAD_ID_PREFIX variable
profiles=$(/usr/bin/profiles show | grep "$PROFILE_PAYLOAD_ID_PREFIX" | sed 's/.*\ //')

# If the PROFILE_PAYLOAD_ID_PREFIX is not found, exit 0 to wait for the next agent run.
if [[ ${#profiles[@]} -eq 0 ]]; then
    echo "no profiles with ID $PROFILE_PAYLOAD_ID_PREFIX were found ..."
    echo "Waiting until the profile is installed before proceeding ..."
    echo "Will check again at the next Kandji agent check-in ..."
    exit 0
else
    echo "$APP_NAME Settings profile($PROFILE_PAYLOAD_ID_PREFIX) is installed ..."
fi

# Look for the app
app_install_path="$(app_search $APP_NAME)"

# Check to make sure that the app is installed on the system before doing anything else.
if [[ "$app_install_path" == "None" ]]; then
    echo "$APP_NAME not installed ..."
    echo "Starting installation process ..."
    exit 1
else
    echo "$APP_NAME is installed at $app_install_path"
fi

# Check to see if the script is configured to enforce a minimum version
if [[ -z "$MINIMUM_ENFORCED_VERSION" ]]; then
    echo "This A&E script is not configured to check for a Minimum Enforced Version ..."
    echo "Nothing to do ..."
    exit 0
fi

# Get the installed version
installed_version="$(return_installed_app_version $app_install_path)"

# Make sure that the installed app version can be found before moving on.
if [[ "$installed_version" == "None" ]]; then
    echo "App version could not be determined for $APP_NAME"
    echo "Starting installation process ..."
    exit 1
fi

# Make the version number have the same dot format (x.x.x.x.n) for comparisons sake.
installed_app_vers_sanitized="$(sanitize_app_version_number $installed_version)"
min_enforced_app_vers_sanitized="$(sanitize_app_version_number $MINIMUM_ENFORCED_VERSION)"

# Compare minimum enforced version to installed version
version_check="$(vers_check $min_enforced_app_vers_sanitized $installed_app_vers_sanitized)"

if [[ "$version_check" == *"less"* ]]; then
    echo "$APP_NAME version \"$installed_version\" is installed and is $version_check min enforced version \"$MINIMUM_ENFORCED_VERSION\" ..."
    echo "Upgrading $APP_NAME ..."
    exit 1
else
    echo "$APP_NAME version \"$installed_version\" is installed and is $version_check min enforced version \"$MINIMUM_ENFORCED_VERSION\" ..."
    echo "Nothing to do ..."
    exit 0
fi
