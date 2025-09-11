#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald, Kandji Fellow | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 09/11/2025
#   Updated -
# 	Version - 1
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - macOS 15.6.1
#
################################################################################################
# Software Information
################################################################################################
#
# This script checks the battery levels of connected Bluetooth HID devices on macOS by parsing
# output from `ioreg`. If any device reports a `BatteryPercent` value below a configurable
# threshold (default: 25%), the script will list those devices and trigger a Kandji display alert
# to notify the user. The alert includes a title, icon, and a message containing the names and
# battery percentages of all low-battery devices.
#
# When devices fall below the threshold, it prints their status, triggers the Kandji alert,
# and exits with status code 0.
#
# The threshold can be adjusted by modifying the `THRESHOLD` variable at the top of the script.
# Device names are taken directly from the `Product` field in the system registry, ensuring that
# any supported Bluetooth accessory (keyboards, mice, trackpads, headphones, etc.) will be
# correctly identified.
#
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

set -euo pipefail

# Set this line to the minimum battery percentage of a bluetooth device before an alert is shown.
# Bluetooth devices BELOW (not at) this threshold will cause an alert to be shown to the user.

battery_percentage_threshold=25

# Determine the username of the current console session
console_user="$(stat -f "%Su" /dev/console)"

# If the console is owned by "root", then no one is logged in
if [[ "$console_user" == "root" ]]; then
  echo "No one is home.."
  exit 0
fi


low_devices="$(
  /usr/sbin/ioreg -r -c AppleDeviceManagementHIDEventService -l | /usr/bin/awk -v thr="${battery_percentage_threshold}" '
  function reset() { prod=""; is_bt=0; pct="" }
  function flush() {
    if (is_bt && pct != "" && (pct+0) < thr) {
      name = (prod != "" ? prod : "Bluetooth HID Device")
      printf "%s — %s%%\n", name, pct
      any=1
    }
  }
  BEGIN { reset(); any=0 }

  {
    if (index($0, "+-o AppleDeviceManagementHIDEventService") > 0) {
      flush(); reset(); next
    }
    if (index($0, "\"Product\" = ") > 0) {
      line = $0
      sub(/^.*"Product" = /, "", line)
      gsub(/^"|"$/, "", line)
      prod = line
      next
    }
    if (index($0, "\"Transport\" = \"Bluetooth\"") > 0) { is_bt=1; next }
    if (index($0, "\"BluetoothDevice\" = Yes") > 0)     { is_bt=1; next }
    if (index($0, "\"BatteryPercent\" = ") > 0) {
      line = $0
      sub(/^.*"BatteryPercent" = /, "", line)
      gsub(/[^0-9]/, "", line)
      if (line != "" && (line+0) >= 0 && (line+0) <= 100) pct=line
      next
    }
  }

  END { flush(); if (!any) exit 0 }
  '
)"


# Print the low devices (if any)
if [[ -n "$low_devices" ]]; then
  printf "%s" "$low_devices"

  # Build a readable alert message with the list
  alert_message=$'The following devices have low battery. Please plug them in:\n\n'"$low_devices"

  # trigger Kandji alert
   /usr/local/bin/kandji display-alert \
    --title "Bluetooth Low Battery" \
    --message "$alert_message" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarInfo.icns \
    --no-wait

  exit 0
else
  # Nothing low
  echo "No low battery devices"
  exit 0
fi