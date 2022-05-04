#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created - 06/09/2021
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.3.1
#   11.6.5
#   10.15.7
#
###################################################################################################
# Software Information
###################################################################################################
#
# This Audit and Enforce script is used to ensure that the Watchman client is installed and
# running properly. This script is designed to be used as an Audit and Enforce script in a Custom
# App Library item. No modification needed.
#
# Instructions and dependency files can be found in the Kandji knowledge base and support github.
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

# Make sure that the app app file name matches the name that will be installed. This script will
# dynamically search for the name /Applications, "/System/Applications", or /Library up to 3 sub-
# directories deep. So there is no need to define an explicit app path.
NAME="MonitoringClient"

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

# Look for the file defined in NAME and return the full path
# This command looks in /Applications, /System/Applications, and /Library for the existance of the
# app defined in $NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library -maxdepth 3 -name $NAME 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e "${installed_path}/RunClient" ]] || [[ $NAME != "$(/usr/bin/basename $installed_path)" ]]; then

    /bin/echo "$NAME/RunClient not found. Starting installation process ..."
    exit 1

else

    # make sure the clientsettings file exists
    if [[ -f "$installed_path/ClientSettings.plist" ]]; then
        # Get the version of the installed watchman client.
        installed_version=$(/usr/bin/defaults read "$installed_path/ClientSettings.plist" Client_Version 2>/dev/null)

        # make sure we got a version number back
        if [[ $? -eq 0 ]]; then
            /bin/echo "$NAME installed with version $installed_version ..."
            /bin/echo "Install path \"${installed_path}\""
        else
            /bin/echo "$NAME is installed at \"$installed_path\"..."
        fi

        # Get the monitoring client status and report back.
        warning_status="$(/usr/bin/defaults read /Library/MonitoringClient/ClientData/UnifiedStatus.plist CurrentWarning)"

        # Report issue status
        if [[ "$warning_status" -eq 0 ]]; then
            /bin/echo "Monitoring client UnifiedStatus: No issues"
        else
            /bin/echo "Monitoring client UnifiedStatus reported an issue..."
            /bin/echo" UnifiedStatus: $warning_status"
        fi

    else
        /bin/echo "Unable to find Monitoring client settings file..."
    fi
fi

exit 0
