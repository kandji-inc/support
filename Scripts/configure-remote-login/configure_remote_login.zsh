#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | se@kandji.io | Kandji, Inc. | Solutions Engineering
###################################################################################################
# Created on 2021.09.09
###################################################################################################
# Software Information
###################################################################################################
#
# This script is designed to enable Remote Login for a specific user on macOS. Set the
# USER_TO_ENABLE variable to the local user that should be added to the Remote Login configuration.
#
# Tested on
#   - macOS Catalina 10.15.7
#   - macOS Big Sur 11.5.2
#
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
#
###################################################################################################

VERSION="1.0.0"

###################################################################################################
######################################### VARIABLES ###############################################
###################################################################################################

# Update USER_TO_ENABLE to match the username to add to the Remote Login SSH config
USER_TO_ENABLE="USER_NAME_HERE"

###################################################################################################
############################### MAIN LOGIC - DO NOT MODIFY BELOW ##################################
###################################################################################################

# Check to the status of setremotelogin to see if it needs to be turned on

if [[ "$(/usr/sbin/systemsetup -getremotelogin | awk '{print $3}')" == "On" ]]; then
    echo "Remotelogin already enabled ..."

else
    echo "Enabling Remote Login ..."
    /bin/launchctl load -w /System/Library/LaunchDaemons/ssh.plist

    if [[ "$(/usr/sbin/systemsetup -getremotelogin | awk '{print $3}')" == "Off" ]]; then
        echo "Unable to enable Remote Login ..."
        echo "Exiting ..."
    fi
fi

# Check to see if the com.apple.access_ssh group exists
if [[ "$(/usr/bin/dscl . list /groups | /usr/bin/grep com.apple.access_ssh)" == "" ]]; then
    echo "Could not find the com.apple.access_ssh group"
    echo "Creating it now ..."

    # Create the SSH group
    /usr/sbin/dseditgroup -o create -q com.apple.access_ssh

    # Add the USER_TO_ENABLE to the Remote Login group
    echo "Adding $USER_TO_ENABLE to the com.apple.access_ssh group ..."
    /usr/sbin/dseditgroup -o edit -a "$USER_TO_ENABLE" -t user com.apple.access_ssh

else
    echo "The com.apple.access_ssh group already exists ..."
    echo "Checking to see if $USER_TO_ENABLE is already a memeber ..."

    # Capture membership status
    member_status=$(/usr/sbin/dseditgroup -o checkmember -m "$USER_TO_ENABLE" com.apple.access_ssh | /usr/bin/awk '{print $4}')

    if [[ "$member_status" == "NOT" ]]; then
        echo "Adding $USER_TO_ENABLE ..."
        /usr/sbin/dseditgroup -o edit -a "$USER_TO_ENABLE" -t user com.apple.access_ssh

    else
        echo "$USER_TO_ENABLE is already a memeber of com.apple.access_ssh ..."
        echo "Nothing to do ..."

    fi
fi
