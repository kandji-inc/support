#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 08/27/2020
################################################################################################
# Software Information
################################################################################################
# This script is designed to remove any user-level profiles that were manually installed
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

#This collects a list of all installed configuration profiles, removes the last line stating the number of profiles installed
profileDump=$(sudo /usr/bin/profiles -P | /usr/bin/grep -vw "There")

#This line filters out the computerlevel profiles, leaving only the user-level profiles in the list
profileLevel=$(echo ${profileDump} | /usr/bin/grep -vw "_computerlevel" | /usr/bin/awk '{print $1}')

#This line determines the profile(s) identifiers
profilesToRemove=$(echo "${profileDump}" | /usr/bin/grep -F "${profileLevel} attribute: profileIdentifier: " | /usr/bin/awk '{print $4}')


for profile in ${=profilesToRemove}; do
	
	#This line determines the username of the account with the user-level profile installed 
	Username=$(echo ${profileDump} | /usr/bin/grep "${profile}" | /usr/bin/grep -vw "_computerlevel" | /usr/bin/awk '{print $1}' | /usr/bin/cut -f1 -d "[")
	
	echo "Profile Identifier: ${profile} installed for User: ${Username}... removing profile"
	
	#This line removes the profile for the specific user it is installed for
	/usr/bin/profiles -R -p ${profile} -U ${Username}
	
done 

echo "Done removing User Level Profiles..."

exit 0