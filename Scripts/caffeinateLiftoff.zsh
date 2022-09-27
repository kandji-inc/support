#!/bin/zsh

########################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
#
#   Created - 05/07/2022
#   Updated - 09/15/2022
#
########################################################################################
# Tested macOS Versions
########################################################################################
#
#   12.5.1
#
########################################################################################
# Software Information
########################################################################################
#
#   This script prevents computers from sleeping until Liftoff advances to the Complete
# 	Screen. This allows the scripts and applications in the blueprint to install
# 	without interuption due to the comptuer going to sleep.
#
########################################################################################
# License Information
########################################################################################
# Copyright 2022 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
########################################################################################

# Script version
VERSION="1.0.0"

########################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##########################
########################################################################################

# Do not modify below, there be dragons. Modify at your own risk.

daemonName="io.kandji.CaffeinateLiftoff"
scriptPath="/tmp/caffeinateliftoff.sh"

# Content for Script
CaffeinateScript=$(
                   /bin/cat <<EOF
#!/bin/bash

# Caffeinate System To Prevent Display & System Sleep
/usr/bin/caffeinate -di &

# Wait for Liftoff to Advance to Complete Screen
until [ ! -f /Library/LaunchAgents/io.kandji.Liftoff.plist ]
	do
	sleep 5
	/bin/echo "Liftoff is still running..."
	done

# Kill Caffeinate
/usr/bin/killall caffeinate

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
/bin/echo "$CaffeinateScript" >"$scriptPath"

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
