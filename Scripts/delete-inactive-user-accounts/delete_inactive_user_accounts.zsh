#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
# Created - 12/10/2021
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.0.1
#   11.6.1
#
###################################################################################################
# Software Information
###################################################################################################
#
# This script is designed to be run from Kandji as a customer script library item. The script will
# look for and remove any user accounts that are older than the number of days specified in the
# `AGE` varialbe and do not appear in the `KEEP` list.
#
# Modified from https://github.com/dankeller/macscripts/blob/master/delete-inactive-users/delete_inactive_users.sh
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

# Script version
VERSION="1.0.0"

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

# Delete /User/ folders inactive longer than this many days
AGE=90

# User folders you would like to bypass. Typically local users or admin accounts.
# Modify this list as needed
KEEP=(
    "/Users/Shared"
    "/Users/support"
    "/Users/student"
    "/Users/testuser"
    "/Users/localadmin"
)

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

# Make sure that we are running as root
if [[ $UID -ne 0 ]]; then echo "$0 must be run as root." && exit 1; fi

# Create a list of accounts that are older than the number of days defined in the AGE variable
user_list=$(/usr/bin/find /Users -type d -maxdepth 1 -mindepth 1 -not -name "." -mtime +$AGE)

# Declare the array so that we can use it
declare -a user_array

# To handle the way zsh does string splitting, or lack there of, we are putting the orignial
# user_list into an array and converting to the sh style string splitting. This will allow us to
# loop over the results.
user_array=( ${=user_list} )

echo "$user_array"

# Check to see if the user_list is empty
if [[ -z "$user_list" ]]; then
    echo "No accounts older than $AGE days were found ..."
    exit 0
fi

for user in $user_array; do
    if ! [[ ${KEEP[*]} =~ "$user" ]]; then

        echo "Deleting inactive account and home directory for : $user"

        echo "Removing the Home directory for $user ..."
        /bin/rm -Rf "$user"

        if [[ $? -ne 0 ]]; then
            echo "Failed to remove the user Home folder ..."
            echo "May need to check the local system to see why the user was not removed ..."
        fi

        echo "Removing account: $user ..."
        /usr/bin/dscl . -delete "$user"

        if [[ $? -ne 0 ]]; then
            echo "Failed to remove the user ..."
            echo "May need to check the local system to see why the user was not removed ..."
        fi

    else
        echo "SKIPPING: $user"
    fi

done

echo "Cleanup complete"
exit 0
