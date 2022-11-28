#!/bin/zsh
###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
# Created on 08/25/2021
###################################################################################################
# Software Information
###################################################################################################
#
#   An Script to report the status of the current login user.
#
#   If the CURRENT_USER_ACCOUNT_STATU returns true then the local account is
#   locked and we return a status of Disabled to the MDM console.
#
#   If the CURRENT_USER_ACCOUNT_STATU returns false then we report that the
#   local user account is Enabled.
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

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

# Returns the current logged in user
CURRENT_USER=$(printf '%s' "show State:/Users/ConsoleUser" |
    /usr/sbin/scutil |
    /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')

# Look for the DisabledUser attribute in the AthenticatinoAuthority for the current user.
CURRENT_USER_ACCOUNT_STATUS=$(/usr/bin/dscl . \
    -read "/Users/$CURRENT_USER" AuthenticationAuthority |
    /usr/bin/grep "DisabledUser")

if [ "$?" -eq 0 ]; then
    # Return DisabledUser from the AthenticatinoAuthority.
    echo "$CURRENT_USER: Disabled"
else
    # Did not return DisabledUser from the AthenticatinoAuthority
    echo "$CURRENT_USER: Enabled"
fi
