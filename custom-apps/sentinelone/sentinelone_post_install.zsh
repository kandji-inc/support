#!/bin/zsh

################################################################################################
# Created by Joe Borner | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2024-03-22
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   14.3.1
#   13.6.4
#   12.7.3
#
################################################################################################
# Software Information
################################################################################################
#
# This post install script is used to install SentinelOne 
#
# Configuration profiles and other scripts are included with the SentinelOne deployment
# instructions found in the Kandji Knowledge Base.
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

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# Unzip path
UNZIP_PATH="/var/tmp"

# pkg name
PKG_NAME="SentinelOneInstaller.pkg"

################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##################################
################################################################################################

/usr/sbin/installer -pkg "$UNZIP_PATH/$PKG_NAME" -target /