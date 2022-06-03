#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
# Created - 2022-03-04
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.2.1
#   11.6.2
#   11.5.2
#
###################################################################################################
# Software Information
###################################################################################################
#
#   This Audit and Enforce script is used to ensure that any app is installed and  running
#   properly after installation.
#
#   To use this script simply define the name of the app as it would appear on the Mac. This
#   script will then search the Mac to ensure that the app is installed. If the app is not found
#   then the script will exit and kick off the installation process. If the app is installed, the
#   script will try to determine and report on the installed version of the app and then exit.
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

# Script version
VERSION="1.0.0"

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

# Make sure that the app name matches the name of the app that will be installed. This script will
# dynamically search for the app in the Applications folder. So there is no need to define an app
# path. The app must install in the /Applications, "/System/Applications", or /Library up to 3 sub-
# directories deep.
APP_NAME="app_name_here"

###################################################################################################
###################################### MAIN LOGIC #################################################
###################################################################################################

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

exit 0
