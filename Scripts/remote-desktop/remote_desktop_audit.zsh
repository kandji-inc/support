#!/bin/zsh

################################################################################################
# Created by Mike Boylan | support@kandji.io | Kandji, Inc. | Product Engineering
################################################################################################
#
# Created on 1/4/2023
#
################################################################################################
# Software Information
################################################################################################
# 
# Audit Script for Remote Desktop
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

# Define the tools we use
defaults="/usr/bin/defaults"
launchctl="/bin/launchctl"

# Check to see if Remote Desktop is on
remoteDesktopOn=$($launchctl list com.apple.screensharing > /dev/null 2>&1; /bin/echo $?)

# 0 status from above means it's on
if [[ $remoteDesktopOn == "0" ]]; then
	# Check to see if it's configured to only allow specific users
	allUsersEnabled=$($defaults read /Library/Preferences/com.apple.RemoteManagement.plist ARD_AllLocalUsers)
	
	# If it is, then it's okay
	if [[ $allUsersEnabled == "0" ]]; then
		echo "Remote Desktop has been configured to allow specifc users."
		exit 0
	# Otherwise, remediate
	else
		echo "Remote Desktop is not configured just for specific users. Remediating..."
		exit 1
	fi
# Remote Desktop is not on, so we don't need to audit its state	
else
	echo "Remote Desktop is not on."
	exit 0
fi
	