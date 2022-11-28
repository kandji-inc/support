#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | se@kandji.io | Kandji, Inc.
###################################################################################################
# Created on 12/10/2021
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   - 12.0.1
#   - 11.6.1
#
###################################################################################################
# Software Information
###################################################################################################
#
#   Audit the status of the firmware password on an Intel-based Mac.
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
###################################################################################################

# Determine the processor brand
processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

# How to find manufacturer information - https://evasions.checkpoint.com/techniques/macos.html
manufacturer=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice |
    /usr/bin/awk -F\" '/manufacturer/{print $(NF-1)}')

if [[ "$processor_brand" == *"Apple"* ]]; then
    echo "Apple Silicon Mac detected ..."
    echo "Firmware password is not compatible ..."
    exit 0

# Check to see if macOS is running on a virtual device
elif [[ "$manufacturer" != *"Apple"* ]]; then
    echo "Virtual device detected ..."
    echo "Firmware password is not compatible ..."
    exit 0

else
    echo "Intel-based Mac hardware detected ..."
fi

# Get the firmwarepasswd status
firmware_password_status=$(/usr/sbin/firmwarepasswd -check | /usr/bin/awk '{print $NF}')

if [[ "$firmware_password_status" != "No" ]]; then
    echo "Firmware password set: $firmware_password_status"
    exit 1
fi

echo "Firmware password set: $firmware_password_status"

exit 0
