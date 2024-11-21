#!/bin/zsh

################################################################################################
# Created by Jan Rosenfeld & Noah Anderson | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 2024.11.15
#   Updated - 2024.11.29
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - 15.1
#
################################################################################################
# Software Information
################################################################################################
#
# This script is designed to be run via Kandji Self Service. It prompts the
# current user for their password, then performs a FileVault authenticated
# reboot. This is useful for when a user is remotely connected to an encrypted
# macOS device but needs to reboot it and get past the encryption screen.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2024 Kandji, Inc.
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

# Script Version
VERSION="1.0.0"

##############################################################################
############################# VARIABLES ######################################
##############################################################################

# Current logged-in user
current_user=$(/usr/bin/stat -f%Su /dev/console)

##############################################################################
################### MAIN LOGIC - DO NOT MODIFY BELOW #########################
##############################################################################

# Prompt the user for their password
user_password=$(/usr/bin/osascript -e 'display dialog "Please enter your password for an authenticated restart." default answer "" with hidden answer buttons {"OK"} default button "OK"' -e "text returned of result")

# Password check
if ! /usr/bin/dscl /Local/Default authonly "${current_user}" "${user_password}" >/dev/null 2>&1; then
    /usr/bin/osascript -e 'display dialog "Invalid password. Please try again." buttons {"OK"} default button "OK"'
    echo "User entered invalid credentials"
    exit 1
fi

# Create a temp file for the plist
tmp_file=$(/usr/bin/mktemp)

/usr/bin/plutil -create xml1 "${tmp_file}"
/usr/bin/plutil -insert "Username" -string "${current_user}" "${tmp_file}"
/usr/bin/plutil -insert "Password" -string "PASSWORD" "${tmp_file}"

# Read in properly formatted plist to securely pass the user password
plist_var=$(/bin/cat "${tmp_file}")

/bin/rm "${tmp_file}"

plist_var=$(sed "s/PASSWORD/${user_password}/g" <<< "${plist_var}")

# Perform the authenticated restart
/usr/bin/sudo /usr/bin/fdesetup authrestart -inputplist -verbose <<< "${plist_var}"
