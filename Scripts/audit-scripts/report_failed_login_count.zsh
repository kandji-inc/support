#!/bin/zsh
###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
# Created on 08/25/2021
###################################################################################################
# Software Information
###################################################################################################
#
#   An Audit Script to report the failedLoginCount for the current login
#   user.
#
#   If the count is equal to the total allowed login attempts in your org than
#   you can mostlikely assume that the local user's account is disabled.
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
###################################### VARIABLES ##################################################
###################################################################################################

NUMBER_OF_ALLOWED_LOGIN_ATTEMPTS=10

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

CURRENT_USER=$(printf '%s' "show State:/Users/ConsoleUser" |
    /usr/sbin/scutil |
    /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')

FAILED_LOGIN_COUNT=$(/usr/bin/dscl . \
    -readpl "/Users/$CURRENT_USER" accountPolicyData failedLoginCount |
    /usr/bin/awk '{print $2}')

# Check to see if the login attempts are greater than or equal to the number of allowed login
# attempts in the assigned passcode policy.
if [[ $FAILED_LOGIN_COUNT -ge $NUMBER_OF_ALLOWED_LOGIN_ATTEMPTS ]]; then
    # Failed login attempts are greater than or equal to the allow amount
    echo "Login count for $CURRENT_USER: $FAILED_LOGIN_COUNT"
    exit 1
fi

echo "Login count for $CURRENT_USER: $FAILED_LOGIN_COUNT"
exit 0
