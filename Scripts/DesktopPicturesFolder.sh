#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 09/02/2020
################################################################################################
# Software Information
################################################################################################
# This script is designed to be used as a pre install script for a "zip" custom app 
# The scrpt checks for the /Library/Desktop Pictures/ and creates it if it doesnt exist 
# The purpose is to pre create the desktop pictures folder so that a custom image can be 
# Extracted to that folder and then set at the desktop picture with a config profile
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

#This line checks if the folder exist 
if [ ! -e "/Library/Desktop Pictures/" ]; then
	echo "/Library/Desktop Pictures/ does not yet exist... creating now..."
	
	#This line creates the folder if it does not exist
	/bin/mkdir "/Library/Desktop Pictures/"
	/usr/sbin/chown root:wheel "/Library/Desktop Pictures/"
else
	echo "/Library/Desktop Pictures/ already exist..."
fi

exit 0
