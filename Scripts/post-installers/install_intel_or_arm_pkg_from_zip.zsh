#!/bin/zsh

################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Iru, Inc.
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

# Package name
# This is the name of the package that is contained in the zip file
PKG_NAME="intel_package_name.pkg"            # Intel package name
AS_PKG_NAME="apple_silicon_package_name.pkg" # Apple Silicon package name

# Iru unzip path
# This should reflect the unzip file path defined in the Custom App in Iru
UNZIP_PATH="/var/tmp"

###################################################################################################
############################ MAIN - DO NOT MODIFY BELOW ###########################################
###################################################################################################

# Determine the processor brand
processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

if [[ "${processor_brand}" == *"Apple"* ]]; then
    /bin/echo "Apple Processor is present..."

    # make sure that the file exists at the defined path
    if [[ -e "$UNZIP_PATH/$AS_PKG_NAME" ]]; then
        /bin/echo "Installing $AS_PKG_NAME"
        /usr/sbin/installer -pkg "$UNZIP_PATH/$AS_PKG_NAME" -target /
    else
        /bin/echo "Could not find $UNZIP_PATH/$AS_PKG_NAME"
        exit 1
    fi

else
    /bin/echo "Intel Processor is not present..."

    # make sure that the file exists at the defined path
    if [[ -e "$UNZIP_PATH/$PKG_NAME" ]]; then
        /bin/echo "Installing $PKG_NAME"
        /usr/sbin/installer -pkg "$UNZIP_PATH/$PKG_NAME" -target /

    else
        /bin/echo "Could not find $UNZIP_PATH/$PKG_NAME"
        exit 1
    fi

fi

# cleanup
# Add any clean up routines that might be required
# Note: If unzipping files /tmp these files will be cleaned up after the next device restart.
/bin/rm -Rf "$UNZIP_PATH/$PKG_NAME" "$UNZIP_PATH/$AS_PKG_NAME"

exit 0
