#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created - 2021-10-12
#   Updated - 2022-04-21
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.3
#   11.6.2
#   10.15.7
#
###################################################################################################
# Software Information
###################################################################################################
#
# This Audit and Enforce script is used to ensure that a specific FortiClient configuration
# profile is installed and ensure that FortiClient is running properly after installation.
#
# A Settings Configuration profiles is included with the FortiClient deployment instructions found
# in the Kandji Knowledge Base.
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
###################################### VARIABLES ##################################################
###################################################################################################

# Change the PROFILE_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. The profile prefix below is associated with the Notifications payload in
# the Kandji provided configuration profile.
PROFILE_ID_PREFIX="io.kandji.forticlient.E23F522E-D2FF"

# Make sure that the app name matches the name of the app that will be installed. This script will
# dynamically search for the app in the Applications folder. So there is no need to define an app
# path. The app must install in the /Applications, "/System/Applications", or /Library up to 3 sub-
# directories deep.
APP_NAME="FortiClient.app"

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

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
# This command looks in /Applications, /System/Applications, and /Library for the existance of the
# app defined in $APP_NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name $APP_NAME 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e $installed_path ]] || [[ $APP_NAME != "$(/usr/bin/basename $installed_path)" ]]; then
    echo "$APP_NAME not installed. Starting installation process ..."
    exit 1

else
    # Get the installed app version
    installed_version=$(/usr/bin/defaults read "$installed_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    # make sure we got a version number back
    if [[ $? -eq 0 ]]; then
        /bin/echo "$APP_NAME version $installed_version is installed at \"$installed_path\"..."
    else
        /bin/echo "$APP_NAME is installed at \"$installed_path\"..."
    fi
fi
