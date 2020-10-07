#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 08/26/2020
################################################################################################
# Software Information
################################################################################################
# This script sets the Mac computers HostName
# The HostName should not be set unless the device is acting as a server
# However, some security solutions use the HostName as the primary means of identification
# This script sets the HostName as the current Local Host Name + a domain appended
#
# Typically this script is used in conjuction with the Set Computer Name parameter
# in order to match the naming convention set for ComputerName and LocalHostName to the HostName
#
# You will need to set the "DomainAppend" value on line 38 to the domain you want to append
#
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

#Set this value to a domain, typically your corporate search domain would be used
DomainAppend="ExampleDomain.com"

LocalHostName=$(/usr/sbin/scutil --get LocalHostName)

SetHostName="${LocalHostName}.${DomainAppend}"

HostName=$(/usr/sbin/scutil --get HostName)

echo "Current HostName is ${HostName}"

if [ "${HostName}" != "${SetHostName}" ]; then 
	echo "Current HostName ${HostName} doesnt not match desired value"
	
	#This line sets the hostname to the Mac computer's current LocalHostName appended by a domain 
	/usr/sbin/scutil --set HostName ${SetHostName}
	
	#Check Host Name
	HostName=$(/usr/sbin/scutil --get HostName)
	
	#Validates if the HostName changed
	if [ "${HostName}" != "${SetHostName}" ]; then 
		echo "Set HostName Failed..."
		echo "HostName is ${HostName}"
		exit 1
	else 
		echo "Set HostName Succeeded..."
		echo "HostName is now ${HostName}"
		exit 0
	fi
fi