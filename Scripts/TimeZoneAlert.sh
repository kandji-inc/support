#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald | nick.mcdonald@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 10/30/2020
################################################################################################
# Software Information
################################################################################################
# This script checks the current system time zone, and exits 1 (throwing an alert), if that time
# zone does not match the expected time zone. This can be useful when wanting to know when a 
# Mac leaves its expected region. 
################################################################################################
# License Information
################################################################################################
# Copyright 2020 Kandji, Inc. 
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

# Set the value of this variable to the expected time zone, you can find this value by running this command in terminal on a Mac set to your expected time zone
# Example command: /usr/sbin/systemsetup -gettimezone | awk '{ print $3 }'

expectedTimeZone="America/Los_Angeles"

# Do not modify below this line 
currentTimeZone=$(/usr/sbin/systemsetup -gettimezone | /usr/bin/awk '{ print $3 }')

echo "Current time zone is ${currentTimeZone}...desired time zone is ${expectedTimeZone}"

if [[ "${currentTimeZone}" != "${expectedTimeZone}" ]]; then
	echo "Time Zone does not match desired time zone... throwing an alert now"
	exit 1
else
	echo "Time Zone is as expected... no notification needed..."
	exit 0
fi

echo "unexpected error"
exit 1