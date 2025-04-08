#!/bin/zsh

################################################################################################
# Created by Matt Wilson, Noah Anderson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created on 2021-08-09
# Updated on 2024-04-25
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   14.4.1
#   13.6.6
#   12.7.4
#
################################################################################################
# Software Information
################################################################################################
#
#   This Audit & Enforce script checks for the presence of an app to see if it is
#   installed on a Mac. Optionally, a MINIMUM_ENFORCED_VERSION can be set, which tells
#   this script to compare an installed app version to the minimum enforced app version
#   set in the script the isntalled version of the provided APP_NAME. If the app cannot
#   be found an installed version of "None" is returned.
#
################################################################################################
# License Information
################################################################################################
#
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
#
################################################################################################

# Script version
# shellcheck disable=SC2034
VERSION="0.5.1"

# zsh has a built-in operator that can actually do float compares; just gotta load it
autoload is-at-least

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################
# Make sure that the app name matches the name of the app that will be installed. This
# script will dynamically search for the app in the Applications folder. So there is no
# need to define an app path. The app must install in the /Applications, "/System/
# Applications", or /Library up to 3 sub-directories deep.
APP_NAME="Microsoft Excel.app"

# If you would like to enforce a minimum version, be sure to update the
# MINIMUM_ENFORCED_VERSION variable with the version number that the audit script
# should enforce. (Example version number 1.5.207.0). If MINIMUM_ENFORCED_VERSION is
# left blank, the audit script will not check for a version and will only check for the
# presence of the app.
# MINIMUM_ENFORCED_VERSION="5.7.6 (1321)"
MINIMUM_ENFORCED_VERSION="3.2.0"

################################################################################################
###################################### MAIN LOGIC ##############################################
################################################################################################

# Look for the app defined in APP_NAME
/bin/echo "Auditing $APP_NAME..."

# This command looks in /Applications, /System/Applications, and /Library for the
# existance of the app defined in $APP_NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name "$APP_NAME" 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e $installed_path ]] || [[ $APP_NAME != "$(/usr/bin/basename "$installed_path")" ]]; then
    /bin/echo "$APP_NAME not installed. Starting installation process ..."
    exit 1
else
    /bin/echo "$APP_NAME installed at $installed_path"
fi

# Check to see if the script is configured to enforce a minimum version
if [[ -z $MINIMUM_ENFORCED_VERSION ]]; then
    /bin/echo "This A&E script is not configured to check for a Minimum Enforced Version ..."
    /bin/echo "Nothing to do ..."
    exit 0
fi

# Get the installed app version
installed_version=$(/usr/bin/defaults read "$installed_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

# make sure we got a version number back
if [[ $? -ne 0 ]]; then
    /bin/echo "App version could not be determined. Reinstalling $APP_NAME ..."
    exit 1
fi

# Compare minimum enforced version to installed version using the zsh builtin operator
# is-at-least
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
