#!/bin/zsh

################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 05/07/2022
#   Updated - 1/18/2023
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.1
#   12.6.1
#
################################################################################################
# Software Information
################################################################################################
#
# This script creates a launchdaemon that will trigger the execution of a library item
# as soon as Liftoff is closed.  This can be useful for some security platforms that
# aggresively disrupt the network connectivity during install or require user
# interaction to complete.
#
# To use this script, update the LIBRARY_ITEM variable to match the name of the Library
# Item in the Kandji Web App and add the following script to the beginning of the audit
# and enforce script of the library item.
#
# 	#!/bin/zsh
# 	if pgrep "Liftoff" > /dev/null; then
#   	/bin/echo "Liftoff is running, aborting process..."
#   	exit 0
# 	else
#   	/bin/echo "Liftoff is not running, continuing process..."
# 	fi
#
# Considerations:
# If the execution of the library item does not need to happen immediately after
# Liftoff closes, it is advisable to keep it simple and put the above snippet in your
# audit and enforce script and avoid using this custom script.
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
VERSION="1.0.1"

################################################################################################
########################################## VARIABLES ###########################################
################################################################################################
# Adjust this to match the Library Item name in the Kandji Web App. ie "Zscaler
# Connector"

LIBRARY_ITEM="Zscaler Connector"

################################################################################################
################################ MAIN LOGIC - DO NOT MODIFY BELOW ##############################
################################################################################################

# Do not modify below, there be dragons. Modify at your own risk.
daemonName="io.kandji.installAfterLiftoff"
scriptPath="/tmp/installAfterLiftoff.sh"

# Content for Script
script=$(
         /bin/cat <<EOF
#!/bin/bash

# Wait for Liftoff to close
until ! pgrep "Liftoff" >/dev/null
	do
	sleep 1
	/bin/echo "Liftoff is running..."
	done

# Execute Library Item
/usr/local/bin/kandji library --item "$LIBRARY_ITEM" -F

# Clean Up After Yourself
rm "/tmp/$daemonName.plist"
rm "$scriptPath"

# Unload LaunchDaemon
/bin/launchctl unload "/tmp/$daemonName.plist"
EOF
)

# Content for LaunchDaemon
launchDaemon=$(
               /bin/cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$daemonName</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$scriptPath</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
)

# Create Script
/bin/echo "Creating Script at $scriptPath..."
/bin/echo "$script" >"$scriptPath"

# Create LaunchDaemon
/bin/echo "Creating LaunchDaemon at /tmp/$daemonName.plist..."
/bin/echo "$launchDaemon" >/tmp/$daemonName.plist

# Set Correct Permissions on LaunchDaemon
/bin/echo "Setting Permissions on LaunchDaemon..."
/usr/sbin/chown root:wheel /tmp/$daemonName.plist
/bin/chmod 644 /tmp/$daemonName.plist
/bin/chmod +x "$scriptPath"

# Load LaunchDaemon
/bin/echo "Loading LaunchDaemon..."
/bin/launchctl load "/tmp/$daemonName.plist"

exit 0
