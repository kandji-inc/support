#!/bin/zsh

################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 09/13/2022
#   Updated - 02/14/2025
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - 15.3.1
#   - 14.5
#   - 13.6.7
#   - 12.7.5
#
################################################################################################
# Software Information
################################################################################################
#
#   This script will create a shortcut on the active user's desktop based on the values set in
#   the variables section. The script supports http, https, smb, ftp, and vnc URIs. If the ICON 
#   variable is left blank, the script will use a generic icon.
#
#   To avoid user prompts, please create a Privacy Profile granting the Kandji Agent access to
#   Finder Apple Events.
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
VERSION="1.0.3"

################################################################################################
########################################## VARIABLES ###########################################
################################################################################################

# The address that you want the shortcut to open.
HOSTNAME="https://kandji.io"

# The name that will display to users.
DISPLAYNAME="My Favorite MDM"

# Full path to the icon to be used for the shortcut.  A blank variable will use the default icon
# for the URI type.
# example: ICON="/Library/Kandji/Kandji Agent.app/Contents/Resources/AppIcon.icns"
ICON=""

################################################################################################
############################### MAIN LOGIC - DO NOT MODIFY BELOW ###############################
################################################################################################

# Validate that the user supplied the required variables
if [ -z "${HOSTNAME}" ]; then
    echo "HOSTNAME variable is empty, please set and try again."
    exit 1
fi
if [ -z "${DISPLAYNAME}" ]; then
    echo "DISPLAYNAME variable is empty, please set and try again."
    exit 1
fi

# Determine the correct file extension to use
if [[ ${HOSTNAME} == http* ]]; then
    FILEEXT=webloc
    DEFAULTICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns"
fi
if [[ ${HOSTNAME} == smb* ]]; then
    FILEEXT=inetloc
    DEFAULTICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFileServerIcon.icns"
fi
if [[ ${HOSTNAME} == ftp* ]]; then
    FILEEXT=ftploc
    DEFAULTICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFileServerIcon.icns"
fi
if [[ ${HOSTNAME} == vnc* ]]; then
    FILEEXT=vncloc
    DEFAULTICON="/System/Library/CoreServices/Applications/Screen Sharing.app/Contents/Resources/AppIcon.icns"
fi

# Gather current user's UID and home directory path
CURRENT_USER=$(/bin/ls -l /dev/console | awk '{print $3}')
CURRENT_USER_UID=$(/usr/bin/id -u "${CURRENT_USER}")
HOMEDIR=$(/usr/bin/dscl . -read /Users/"${CURRENT_USER}" NFSHomeDirectory | /usr/bin/cut -d' ' -f2)

# Determine if the shortcut already exists and if it does, abort.
if [ -e "${HOMEDIR}/Desktop/${DISPLAYNAME}.${FILEEXT}" ]; then
    echo "Shortcut already exists at ${HOMEDIR}/Desktop/${DISPLAYNAME}.${FILEEXT}, exiting..."
    exit 0
fi

# Set SHORTCUTICON with user input, or if empty, with default icon
if [ -n "${ICON}" ]; then
    SHORTCUTICON=${ICON}
else
    echo "ICON variable not defined, using default icon..."
    SHORTCUTICON=${DEFAULTICON}
fi

# Create the shortcut
/bin/launchctl asuser "${CURRENT_USER_UID}" osascript <<EOF
    tell application "Finder"
	    make new internet location file at desktop to "${HOSTNAME}" with properties {name:"${DISPLAYNAME}"}
    end tell

    use framework "Foundation"

    set iconFile to "${SHORTCUTICON}"
    set targetFile to "${HOMEDIR}/Desktop/${DISPLAYNAME}.${FILEEXT}"
    set imageData to (current application's NSImage's alloc()'s initWithContentsOfFile:iconFile)
    (current application's NSWorkspace's sharedWorkspace()'s setIcon:imageData forFile:targetFile options:2)
    
EOF
