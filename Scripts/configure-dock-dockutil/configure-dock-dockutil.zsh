#!/bin/zsh

########################################################################################
# Created by Danny Hanes | support@kandji.io | Kandji, Inc.
########################################################################################
#
#   Created - 06/27/2023
#
########################################################################################
# Tested macOS Versions
########################################################################################
#
#   - 13.4
#
########################################################################################
# Software Information
########################################################################################
#
#   This script will download and install dockutil, an open source utilty used to configure
#   a users dock on the mac. Once installed, dockutil will remove all existing icons and add
#   the list of icons listed by the admin based on the configurations provided below.
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

# Script version
VERSION="1.0.0"

########################################################################################
################################# USER VARIABLES #######################################
########################################################################################

# Do you want to remove the existing dock icons before adding new ones (Y/N)
ERASE_DOCK="Y"

# Do you want to remove dockutil from the computer once complete (Y/N)
REMOVE_DOCKUTIL="Y"

# Do you want to keep the downloads folder in the dock (Y/N)
DOWNLOADS_FOLDER="Y"

# Complete path of applications to add to the dock, new line per application
APPLICATION_LIST=(
        "/Applications/Google Chrome.app"
        "/System/Applications/Music.app"
        "/System/Applications/Notes.app"
        "/System/Applications/Reminders.app"
        "/Applications/Kandji Self Service.app"
    )

# If an application has not yet been installed, do you want to skip that application, or 
# place a question mark icon in the dock? 
SKIP_MISSING="Y"

########################################################################################
################################# SCRIPT VARIABLES #####################################
########################################################################################

dockutilBinary="/usr/local/bin/dockutil"
dockutilURL="https://api.github.com/repos/kcrawford/dockutil/releases/latest"
dockutilInstaller="/var/tmp/dockutil.pkg"
dockutilTeamID="Z5J8CJBUWC"

installDockutil () {

    if [[ ! -f "$dockutilBinary" ]]; then
        /bin/echo "Downloading and installing dockutil..."
        url=$(/usr/bin/curl -s $dockutilURL | /usr/bin/grep "download_url" | /usr/bin/awk '{print $2}' | /usr/bin/tr -d '"')
        /usr/bin/curl -L -o "$dockutilInstaller" "$url"
        
        packageID=$(/usr/sbin/pkgutil --check-signature "${dockutilInstaller}" | sed -n -e 's/^.*Developer ID Installer: //p' | sed -e 's/.*(\(.*\)).*/\1/;s/,//g')

        if [[ "${packageID}" != "${dockutilTeamID}" ]]; then
            /bin/echo "Signature check failed..."
            /bin/echo "Expected Team ID was ${dockutilTeamID}; got ${packageID}"
            exit 1
        fi
        
        /usr/bin/sudo installer -pkg "$dockutilInstaller" -target /

        if [[ ! -f "$dockutilBinary" ]]; then
            /bin/echo "Installation failed, exiting..."
            exit 1
        else
            /bin/echo "Dockutil successfully installed"
        fi
    else
        /bin/echo "Dockutil already installed"
    fi
}

configureDock () {
    oldIFS=${IFS}
    IFS=','
    if [[ "$ERASE_DOCK" == "Y" ]]; then
        /bin/echo "Resetting the dock..."
        "$dockutilBinary" --remove all --no-restart --allhomes
    fi

    for app in ${APPLICATION_LIST[@]}; do
        if [[ ! -d $app ]] && [[ "$SKIP_MISSING" == "Y" ]]; then
            /bin/echo "$app does not exist; skipping"
        else
            "$dockutilBinary" --add "$app" --no-restart --allhomes
        fi
    done

    if [[ "$DOWNLOADS_FOLDER" == "Y" ]]; then
        "$dockutilBinary" --add '~/Downloads' --allhomes 
    fi
    
    /bin/sleep 1
    /usr/bin/killall Dock
    IFS="${oldIFS}"
}

cleanup () {

    if [[ "$REMOVE_DOCKUTIL" == "Y" && -f "$dockutilBinary" ]]; then
        /bin/echo "Removing dockutil..."
        rm "$dockutilBinary"
    fi
    
    rm "$dockutilInstaller"

}

installDockutil
configureDock
cleanup

exit 0