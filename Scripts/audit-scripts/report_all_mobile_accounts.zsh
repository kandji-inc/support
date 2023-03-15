#!/usr/bin/env zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Updated - 2023-01-27 - Matt Wilson
#
################################################################################################
# TESTED MACOS VERSIONS
################################################################################################
#
#   - 13.2
#
################################################################################################
# SOFTWARE INFORMATION
################################################################################################
#
#   Get all user accounts with a UID greater than 500 and report if they are mobile accounts
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

# Creates a list of users with a UID greater than 500
# Users with a UID less than UID 500 are typically services accuonts
USER_LIST=("$(/usr/bin/dscl . list /Users UniqueID |
    /usr/bin/awk '$2 > 500 {print $1}' |
    /usr/bin/sed -e 's/^[ \t]*//')")

# Check to see if the user_list is empty
if [[ "${#USER_LIST[@]}" -eq 0 ]]; then
    # If no users with UID over 1000 are returned, Quit.
    echo "No user accounts found."
    echo "Nothing to do ..."
    echo "Exiting ..."
    echo ""
    exit 0
fi

# If the list contianed users with UID over 1000 print them to stdout
for user in "${USER_LIST[@]}"; do

    # Verify that the accounts found are actually mobile accounts
    echo "Checking user account type for $user ..."

    # Grab the user account type
    _ACCOUNT_TYPE=$(/usr/bin/dscl . \
        -read /Users/"$user" AuthenticationAuthority |
        /usr/bin/head -2 |
        /usr/bin/awk -F'/' '{print $2}' |
        /usr/bin/tr -d '\n' |
        /usr/bin/sed -e 's/^[ \t]*//')

    if [[ $_ACCOUNT_CHECK -eq 1 ]]; then
        # Check the user account type before attemtpting to convert the account.

        _MOBILE_USER_CHECK=$(/usr/bin/dscl . \
            -read /Users/"$user" AuthenticationAuthority |
            /usr/bin/head -2 |
            /usr/bin/awk -F'/' '{print $1}' |
            /usr/bin/tr -d '\n' |
            /usr/bin/sed 's/^[^:]*: //' |
            /usr/bin/sed s/\;/""/g)
    fi

    if [[ $_ACCOUNT_TYPE = "Active Directory" ]] || [[ $_MOBILE_USER_CHECK = "LocalCachedUser" ]]; then
        echo "$user has an AD mobile account."
        echo "Converting to a local account with the same username and UID."
    else
        echo "The $user account is not a AD mobile account."
        echo ""
        # break
    fi

done
