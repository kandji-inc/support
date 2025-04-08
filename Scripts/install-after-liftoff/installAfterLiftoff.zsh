#!/bin/zsh

################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 05/07/2022
#   Updated - 05/28/2024
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
# This script can be used to trigger the execution of Library Items when Liftoff advances to the
# Complete Screen or is quit.  This can be useful for some security platforms that aggresively 
# disrupt the network connectivity during install or require user interaction to complete.
# 
# For full instructions please visit:
# https://github.com/kandji-inc/support/tree/main/Scripts/install-after-liftoff
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
VERSION="2.0.3"

################################################################################################
########################################## VARIABLES ###########################################
################################################################################################
# List of Library Items that you want to execute
# You may use the Library Item display name, such as "Zscaler Connector" or the Library Item
# UUID such as "ad06b6ad-b90c-4308-b932-3c223b9e8880".
libraryItemList=(
        "Zscaler Connector"
        "VLC"
        "fb36e3c6-e748-40e8-b69d-15ece20a01d5"
    )

# By default, the install(s) will start once Liftoff has been quit. If you'd rather have the 
# install(s) start once Liftoff advances to the Complete Screen, change this to "false".
startAtLiftoffQuit="true"

################################################################################################
################################ MAIN LOGIC - DO NOT MODIFY BELOW ##############################
################################################################################################

daemonName="io.kandji.installAfterLiftoff"
scriptPath="/tmp/installAfterLiftoff.zsh"

# Define method to trigger the install(s)
if [[ "${startAtLiftoffQuit}" == "true" ]]; then
    trigger='# Wait for Liftoff to close
until ! pgrep "Liftoff" >/dev/null; do
    sleep 1
    echo "Liftoff is running..."
done'
elif [[ "${startAtLiftoffQuit}" == "false" ]]; then 
    trigger='# Wait for Liftoff to complete
until [[ ! -f /Library/LaunchAgents/io.kandji.Liftoff.plist ]]; do
    sleep 1
    echo "Liftoff is still running..."
done'
else
    echo "Invalid startAtLiftoffQuit variable, please check your work and try again."
    exit 1
fi

# Build list of Library Item execution lines
nl=$'\n'
executeLibraryItems=()
for libraryItem in "${libraryItemList[@]}"; do
    line="/usr/local/bin/kandji library --item \"${libraryItem}\" -F"
    executeLibraryItems+=("${line}${nl}")
done

# Create Script
echo "Creating Script at ${scriptPath}..."
/bin/cat > "${scriptPath}" <<EOF
#!/bin/zsh

${trigger}

# Execute Library Item(s)
${executeLibraryItems}

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