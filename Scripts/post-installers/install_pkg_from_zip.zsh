#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created - 10/29/2021
#   Updated - 2022.02.11
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   - 12.2
#   - 11.5.2
#
###################################################################################################
# Software Information
###################################################################################################
#
#   Post-installer to install a pkg file from an unzipped location
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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
VERSION="1.0.2"

###################################################################################################
####################################### VARIABLES #################################################
###################################################################################################

# Package name
# This is the name of the package that is contained in the zip file
PKG_NAME="antivirus_for_mac.pkg"

# Kandji unzip path
# This should reflect the unzip file path defined in the custom app in Kandji
UNZIP_PATH="/var/tmp"

###################################################################################################
############################ MAIN - DO NOT MODIFY BELOW ###########################################
###################################################################################################

# look for the file to see if it exists
file_search="$(/usr/bin/find $UNZIP_PATH -name $PKG_NAME)"

if [[ $file_search == "" ]]; then
    echo "Unable to find $PKG_NAME in at $UNZIP_PATH ..."
    exit 1
else
    echo "$PKG_NAME found at $file_search"
fi

echo "Attempting to install $file_search ..."

# install the package that was found
/usr/sbin/installer -pkg "$file_search" -target /

# If the previous command exits with something other than 0, something went wrong.
if [[ $? -ne 0 ]]; then
    echo "$PKG_NAME Install failed ..."
    exit 1
fi

# Clean up
/bin/rm -Rf "$UNZIP_PATH/$PKG_NAME"

exit 0
