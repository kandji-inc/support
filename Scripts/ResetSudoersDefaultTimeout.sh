#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald | support@kandji.io | Kandji, Inc. 
################################################################################################
#
# Created on 12/08/2020
# Updated on 01/18/2023
# Updated on 05/11/2025
#
################################################################################################
# Software Information
################################################################################################
#
# This script resets the sudoers timestamp_timeout value to 5
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

# Checks if timestamp_timeout is already set to 5 (allows for variable whitespace); exits if true.
if /usr/bin/grep -E -q '^Defaults\s+timestamp_timeout\s*=\s*5\b' /etc/sudoers; then
    echo "timestamp_timeout is already set to 5 minutes... no changes needed..."
    exit 0
else
    echo "timestamp_timeout is not set to 5 minutes...changes needed..."
fi
	
#Copies the current sudoers file
/bin/cp /etc/sudoers /tmp/sudoers-tmp

#Uses sed to find and replace the default timestamp line
/usr/bin/sed -i --backup -E 's/^(Defaults[[:space:]]+timestamp_timeout[[:space:]]*=).*/\15/' /tmp/sudoers-tmp

#Uses visudo to validate the syntax of the new file prior to copying
/usr/sbin/visudo -cf /tmp/sudoers-tmp

attempt="1"

fCopyModifiedFile ()
{
	while [ ${attempt} -lt 4 ]
	do
		
		if [ ${attempt} -gt 1 ]; then 
			sleep 10
		fi
	
			echo "Starting copy attempt number ${attempt}"
			/bin/cp /tmp/sudoers-tmp /etc/sudoers
			
			if [ $? -eq 0 ]; then
				echo "Sudoers file replaced successfully."
				fDeleteTmpFiles
				exit 0
			else
				echo "Failed to copy the new file ${attempt} times... Attempting recovery..."
				attempt=$[${attempt}+1]
				fCopyModifiedFile
			fi
	done
	
	echo "Max copy attempts reached. Please restore the backup manually from /tmp/sudoers-backup"
	exit 2
}

fDeleteTmpFiles ()
{
	echo "Deleting /tmp/sudoers-backup-modified & /tmp/sudoers-backup"
	/bin/rm -f "/tmp/sudoers-tmp-backup"
	/bin/rm -f "/tmp/sudoers-tmp"
}

##Checks if the validation was successful; if so, proceeds with copying the new file.
if [ $? -eq 0 ]; then
	echo "Sudoers file validated... attempting copy"
	fCopyModifiedFile
else
	echo "Syntax validation failed. Please edit the file manually using visudo... removing backup and modified files since nothing was changed..."
	fDeleteTmpFiles
	exit 1
fi
