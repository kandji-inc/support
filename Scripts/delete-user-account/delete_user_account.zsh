#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | se@kandji.io | Kandji, Inc. | Solutions Engineering
###################################################################################################
# Created on 2021.09.08
# Updated on 2023.09.12 - Added home folder check
###################################################################################################
# Software Information
###################################################################################################
#
# This script is designed to look for a defined user in the USER_TO_REMOVE varable. Then delete
# the user's Home folder and remove the user account.
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
#
###################################################################################################

###################################################################################################
######################################### VARIABLES ###############################################
###################################################################################################

# Update USER_TO_REMOVE to match the username to delete
USER_TO_REMOVE=""

###################################################################################################
############################### MAIN LOGIC - DO NOT MODIFY BELOW ##################################
###################################################################################################

# Creates a list of users with a UID greater than 400
# We are looking for UIDs above 400 just encase there are some hidden users in the 400 range.
user_list=$(/usr/bin/dscl . list /Users UniqueID | \
    /usr/bin/awk '$2 > 1 {print $1}')

# Declare the array so that we can use it
declare -a user_array

# To handle the way zsh does string splitting, or lack there of, we are putting the orignial
# user_list into an array and converting to the sh style string splitting. This will allow us to
# loop over the results.
user_array=( ${=user_list} )

# Check to see if the user_list is empty
if [[ "$user_array" == "" ]]; then
    # If no users with UID over 1000 are returned, Quit.
    echo "No user accounts found."
    echo "Exiting ..."
    exit 0
fi

echo "Looking for $USER_TO_REMOVE ..."

# Initialize a counter to keep track of how how many users have been checked
users_checked=0

# Determine if any of the local users have standard permissions
for user in $user_array; do

    if [[ "$user" == "$USER_TO_REMOVE" ]]; then
        echo "Found $USER_TO_REMOVE ..."
        break
    fi

    # Increment the counter
    (( users_checked++ ))

    # Check to see if the user_array is equal to the user counter
    # If it is equal then we have exhausted the list of user to check.
    if [[ "${#user_array[@]}" == "$users_checked" ]]; then
        echo "Unable to find $USER_TO_REMOVE in the list ..."
        echo "Nothing to to ..."
        exit 0
    fi

done

# Get the home folder for $USER_TO_REMOVE
home_folder=`/usr/bin/dscl . read /Users/$USER_TO_REMOVE NFSHomeDirectory| awk {'print $2'}`

# Confirm the home folder exists
if [[ -d "$home_folder" ]]; then
    /bin/echo "Removing the Home directory for $USER_TO_REMOVE ..."
    /bin/rm -Rf "$home_folder"
else
    /bin/echo "No home folder exists for $USER_TO_REMOVE"
fi

echo "Removing account: $USER_TO_REMOVE ..."
# /usr/sbin/sysadminctl -deleteUser "$USER_TO_REMOVE"
/usr/bin/dscl . -delete "/Users/$USER_TO_REMOVE"

if [[ $? -ne 0 ]]; then
    echo "Failed to remove the user ..."
    exit 1
fi

exit 0
