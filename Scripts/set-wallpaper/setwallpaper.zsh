#!/bin/zsh

################################################################################################
# Created by Brian Van Peski | support@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
#
# Created - 3/21/2023
# Updated - 5/2/2024
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#  14.4.1
#  13.6.6
#  12.7.4
#
################################################################################################
# Software Information
################################################################################################
# 
# This script is designed to set the desktop wallpaper for a user while allowing them to 
# modify it later if they choose. Set the script to "run once" to set the initial wallpaper.
#
# If you want to lock a Mac to a specific wallpaper, deploy a configuration profile
# with the `com.apple.desktop` payload. (Use a tool like iMazing Profile Editor and use the
# "Desktop Picture" option)
#
# This script assumes two things:
# 1. That the images have been pushed to the machine (via zip file in custom app payload) and
# 2. A PPC profile has been deployed that gives the Kandji agent access to Finder.
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
# Path to wallpaper
wallpaper="/Users/Shared/Wallpapers/custom_wallpaper.jpg"

# Fetch current desktop image
current_wallpaper=$(/usr/bin/osascript -e 'tell application "System Events" to get picture of current desktop')

################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##################################
################################################################################################
currentUser=$(/usr/bin/stat -f%Su /dev/console)
currentUID=$(/usr/bin/id -u ${currentUser})

# Check that Kandji agent has access to Finder Events
pppc_status=$(/usr/libexec/PlistBuddy -c 'print "io.kandji.KandjiAgent:kTCCServiceAppleEvents:com.apple.finder:Allowed"' "/Library/Application Support/com.apple.TCC/MDMOverrides.plist")

# Check that wallpaper is present and PPPC Profile is installed
if [[ -f "$wallpaper" && $pppc_status = true ]]; then
  # Check if wallpaper is already set, if not, set for all desktops.
  if [[ "$wallpaper" != "$current_wallpaper" ]]; then
    echo "Desktop pictures not set."
    echo "Setting Desktop picture for all displays..."
    sudo launchctl asuser ${currentUID} /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "'$wallpaper'"'
    exit 0
  else
    echo "Wallpaper is already set..."
    exit 0
  fi
elif [[ -f "$wallpaper" && $pppc_status != true ]]; then
  echo "The Kandji agent does not have access to Finder events. Exiting... "
  exit 1
else
  echo "Wallpaper not found at $wallpaper. Exiting..."
  exit 1
fi
