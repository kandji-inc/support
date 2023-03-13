#!/bin/zsh

################################################################################################
# Created by Brian Van Peski | support@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created - 03/01/2023
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.2.1
#
################################################################################################
# Software Information
################################################################################################
#
# VenturaCheck
#
# This script is designed to trigger an alert if a device is on macOS Ventura and matches 
# specific criteria:
# Enrolled via ADE, is Apple Silicon, has reduced Secure Boot settings and has upgraded
# from a previous version of macOS to macOS Ventura.
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

##############################################################
# VARIABLES
##############################################################

# Set logging - Send logs to stdout as well as Unified Log
# Use 'log show --process "logger"'to view logs activity.
function LOGGING {
    /bin/echo "${1}"
    /usr/bin/logger "VenturaCheck: ${1}"
}

##############################################################
# VARIABLES
##############################################################

# OS Version
osVer="$(/usr/bin/sw_vers -productVersion)"

# Is Activation Lock On
activationLock=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Activation Lock Status/{print $NF}')

# Was the device enrolled via ADE
adeEnrolled=$(profiles status -type enrollment | /usr/bin/grep "Enrolled via DEP" | /usr/bin/awk '{print $4}')

# Is the device running in reduced security mode
apfsVolumeGroup=$(/usr/sbin/diskutil info / | /usr/bin/awk '/APFS Volume Group/{print $NF}')
bootSecurityMode=$(/usr/bin/bputil -d -v $apfsVolumeGroup | /usr/bin/awk '/Security Mode:/{print $3}')

# Check install history for any versions of macOS that aren't 13.* to determine if this device was upgraded from a previous macOS.
previousmacOS=$(/usr/sbin/system_profiler SPInstallHistoryDataType | /usr/bin/grep "macOS" | /usr/bin/grep -v "macOS 13\.*"  )

##############################################################
# MAIN LOGIC
##############################################################

if [[ $osVer > 13.* && $activationLock == "Enabled" && $adeEnrolled == "Yes" && $bootSecurityMode != "Full" && $previousmacOS =~ "macOS (10|11|12)\.*" ]]; then
	LOGGING "This device meets specified criteria. Triggering alert for Kandji...
	Activation Lock Status: $activationLock
	ADE Enrolled: $adeEnrolled
	Boot Security Mode: $bootSecurityMode
	Previous Upgrades:
	$previousmacOS"
	exit 1
else
  LOGGING "This device does NOT meet specified criteria."
  exit 0
fi