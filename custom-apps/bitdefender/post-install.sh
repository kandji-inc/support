#!/usr/bin/env zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2022-02-09
# Updated - 2025-05-08
################################################################################################
# Tested macOS Versions
################################################################################################
#
#    15.4.1
#    14.7.5
#    13.7.5
#    12.7.6
#
################################################################################################
# Software Information
################################################################################################
#
#   Postinstall script for Bitdefender
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

################################################################################################
####################################### VARIABLES ##############################################
################################################################################################

# Package name
# This is the name of the package that is contained in the zip file
PKG_NAME="antivirus_for_mac.pkg"        # Intel package name
AS_PKG_NAME="antivirus_for_mac_arm.pkg" # Apple Silicon package name

# Kandji unzip path
# This should reflect the unzip file path defined in the custom app library item
UNZIP_PATH="/var/tmp"

# Bitdefender cert name
BD_CERT_NAME="certificate.pfx"

# BD install.xml name
BD_INST_XML="installer.xml"

################################################################################################
############################ MAIN - DO NOT MODIFY BELOW ########################################
################################################################################################

# Determine the processor brand
processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

# Bitdefender cert directory
bd_cert_dir="/Library/DeployCert"

# Check to see if the BD cert directory exists
if [[ ! -d "$bd_cert_dir" ]]; then
    # create the directory
    /bin/echo "Creating $bd_cert_dir..."
    /bin/mkdir -p "$bd_cert_dir"
fi

# move the cert file into place
/bin/echo "Moving $BD_CERT_NAME to $bd_cert_dir."
/bin/cp "$UNZIP_PATH/$BD_CERT_NAME" "$bd_cert_dir"

# set permissions
/bin/echo "Setting permissions on $bd_cert_dir"
/bin/chmod -R 644 "$bd_cert_dir"

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
    /bin/echo "Apple Processor is not present..."

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
/bin/echo "Removing dependency files in /var/tmp"
/bin/rm -Rf "${UNZIP_PATH:?}/$PKG_NAME" \
    "${UNZIP_PATH:?}/$AS_PKG_NAME" \
    "${UNZIP_PATH:?}/$BD_CERT_NAME" \
    "${UNZIP_PATH:?}/$BD_INST_XML"

exit 0
