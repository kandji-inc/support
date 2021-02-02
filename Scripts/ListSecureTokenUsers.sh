#!/bin/bash

################################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 02/01/2021
################################################################################################
# Software Information
################################################################################################
# This script will list all secure token enabled user accounts 
################################################################################################
# License Information
################################################################################################
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
#
################################################################################################

allUsers=$(/usr/bin/dscl . -list /Users GeneratedUID)
secureTokenGUIDS=$(/usr/sbin/diskutil apfs listcryptousers /)


IFS="
"

for user in ${allUsers}
do
	
userGUID=$(echo $user | /usr/bin/awk '{print $2}')
username=$(echo $user | /usr/bin/awk '{print $1}')

	if [[ "${secureTokenGUIDS}" == *"${userGUID}"* ]]; then
		echo "${username} ($userGUID) is a Secure Token User"
		echo "----------------------------------------------"
	fi

done

if [[ "${secureTokenGUIDS}" == *"MDM Bootstrap Token External Key"* ]]; then
	echo "Bootstrap Token is present (Not Validated)"
else 
	echo "Bootstrap Token User DOES NOT EXIST"
fi

if [[ "${secureTokenGUIDS}" == *"Personal Recovery User"* ]]; then
	echo "PRK Secure Token User exist"
else 
	echo "PRK Secure Token User DOES NOT EXIST"
fi

if [[ "${secureTokenGUIDS}" == *"Unknown"* ]]; then
	echo "Unknown Secure Token User type exist"
fi

exit 0