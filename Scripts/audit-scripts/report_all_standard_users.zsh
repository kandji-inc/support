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
#   Report all local user accounts with a UID greater than 500
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
    /usr/bin/awk '$2 > 500 {print $1}')")

echo "Checking user account permissions ..."

# Determine if any of the local users have standard permissions
for user in "${USER_LIST[@]}"; do

    # Verify that the accounts found are actually mobile accounts
    # Returns true if the current logged in user is a member of the local admins group.
    GROUP_MEMBERSHIP=$(/usr/bin/dscl . read /groups/admin | /usr/bin/grep "$user")
    RET="$?"

    if [ "$RET" -eq 0 ]; then
        # User is in the admin group
        echo "$user has admin permissions ..."
    else
        # User is not in the admin group
        echo "$user has standard permissions ..."
    fi

done
