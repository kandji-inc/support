#!/bin/zsh

################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 05/07/2022
#   Updated - 05/24/2024
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - 14.5
#   - 13.6.7
#   - 12.7.5
#
################################################################################################
# Software Information
################################################################################################
#
#   This script prevents computers from sleeping until Liftoff advances to the Complete Screen.
# 	This allows the scripts and applications in the blueprint to install without interuption due
# 	to the comptuer going to sleep.
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

# Script version
VERSION="1.0.1"

################################################################################################
############################### MAIN LOGIC - DO NOT MODIFY BELOW ###############################
################################################################################################

daemonName="io.kandji.CaffeinateLiftoff"
scriptPath="/tmp/caffeinateliftoff.zsh"

# Create Script
echo "Creating Script at ${scriptPath}..."
/bin/cat > "${scriptPath}" <<EOF
#!/bin/zsh

# Caffeinate System To Prevent Display & System Sleep
/usr/bin/caffeinate -di &

# Wait for Liftoff to Advance to Complete Screen
until [ ! -f /Library/LaunchAgents/io.kandji.Liftoff.plist ]
	do
	sleep 5
	echo "Liftoff is still running..."
	done

# Kill Caffeinate
/usr/bin/killall caffeinate

# Clean Up After Yourself
/bin/rm "/tmp/${daemonName}.plist"
/bin/rm "${scriptPath}"

# Unload LaunchDaemon
/bin/launchctl bootout system/${daemonName}
EOF


# Create LaunchDaemon
echo "Creating LaunchDaemon at /tmp/${daemonName}.plist..."
/bin/cat > "/tmp/${daemonName}.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${daemonName}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${scriptPath}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# Set Correct Permissions on LaunchDaemon
echo "Setting Permissions on LaunchDaemon..."
/usr/sbin/chown root:wheel "/tmp/${daemonName}.plist"
/bin/chmod 644 "/tmp/${daemonName}.plist"
/bin/chmod +x "${scriptPath}"

# Load LaunchDaemon
echo "Loading LaunchDaemon..."
/bin/launchctl bootstrap system "/tmp/${daemonName}.plist"

exit 0