#!/bin/zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 06/09/2021
# Updated - 2024-03-06 - Joe Borner
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   14.3.1
#   13.6.4
#   12.7.3
#
################################################################################################
# Software Information
################################################################################################
#
# This post install script is used to install Sophos Endpoint. 
#
# Configuration profiles and an audit script are included with the Sophos Endpoint deployment
# instructions found in the Kandji Knowledge Base.
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

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# Unzip directory defined in Kandji
UNZIP_LOCATION="/var/tmp"

################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##################################
################################################################################################

# Locate the Sophos Installer.app in the $UNZIP_LOCATION
SOPHOS_INSTALLER_APP=$(
    /usr/bin/find "$UNZIP_LOCATION" -maxdepth 2 \
        -name 'Sophos Installer.app' 2&>/dev/null
)

# Locate the 'Sophos Installer Components' folder in the $UNZIP_LOCATION
SOPHOS_INSTALLER_COMPONENTS=$(/usr/bin/find "$UNZIP_LOCATION" -maxdepth 2 \
    -name 'Sophos Installer Components' 2&>/dev/null)

# Locate the 'Sophos Installer' binary in the $SOPHOS_INSTALLER_APP
SOPHOS_INSTALLER=$(/usr/bin/find "$SOPHOS_INSTALLER_APP" -maxdepth 4 \
    -name 'Sophos Installer' 2&>/dev/null)

# Locate the 'com.sophos.bootstrap.helper' file in the $SOPHOS_INSTALLER_APP
SOPHOS_BOOTSTRAP_HELPER=$(/usr/bin/find "$SOPHOS_INSTALLER_APP" -maxdepth 4 \
    -name 'com.sophos.bootstrap.helper' 2&>/dev/null)

# Confirm the 'Sophos Installer' binary and 'com.sophos.bootstrap.helper' file have been
# found
if [[ -n "$SOPHOS_INSTALLER" && -n "$SOPHOS_BOOTSTRAP_HELPER" ]]; then
    /bin/echo "Setting permissions on installers ..."
    /bin/chmod a+x "$SOPHOS_INSTALLER"
    /bin/chmod a+x "$SOPHOS_BOOTSTRAP_HELPER"
    /usr/bin/xattr -cr "$SOPHOS_INSTALLER_APP"
else
    if [[ -n "$SOPHOS_INSTALLER_APP" ]]; then
        rm -fR "$SOPHOS_INSTALLER_APP"
    fi

    if [[ -n $SOPHOS_INSTALLER_COMPONENTS ]]; then
        rm -fR "$SOPHOS_INSTALLER_COMPONENTS"
    fi
    /bin/echo "Failed to locate the Sophos Installer ..."
    exit 1
fi

/bin/echo "Running Sophos Installer ..."

# Execute the Sophos Install binary
"$SOPHOS_INSTALLER" --install
EXIT_STATUS=$?

/bin/echo "Removing installer and component files ..."

if [[ -d $(/usr/bin/dirname "$SOPHOS_INSTALLER_APP") &&
$(/usr/bin/dirname "$SOPHOS_INSTALLER_APP") != "$UNZIP_LOCATION" ]]; then
    /bin/rm -fR "$(/usr/bin/dirname "$SOPHOS_INSTALLER_APP")"
fi

if [[ -d $(/usr/bin/dirname "$SOPHOS_INSTALLER_COMPONENTS") &&
$(/usr/bin/dirname "$SOPHOS_INSTALLER_COMPONENTS") != "$UNZIP_LOCATION" ]]; then
    /bin/rm -fR "$(/usr/bin/dirname "$SOPHOS_INSTALLER_COMPONENTS")"
fi

# Exit based on status of the install
exit $EXIT_STATUS
