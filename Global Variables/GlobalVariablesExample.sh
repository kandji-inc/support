#!/bin/bash
################################################################################################
# Created by Nicholas McDonald | support@iru.com | Iru, Inc.
################################################################################################
#
# Created - 03/29/2021
# Updated - 10/15/2026
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - macOS Golden Gate 27
#   - macOS Tahoe 26
#   - macOS Sequoia 15
#
################################################################################################
# Software Information
################################################################################################
#
# Example script reading in Iru global variables from the global variables custom profile.
#
# For more information about Global Variables, please refer to the Iru documentation
# https://docs.iru.com/en/endpoint/library/library-items-profiles/global-variables
#
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

globalVariablesPlist="/Library/Managed Preferences/io.kandji.globalvariables.plist"

if [[ ! -f "${globalVariablesPlist}" ]]; then
    echo "Global Variables profile is not installed. ${globalVariablesPlist} was not found."
    exit 1
fi

FULL_NAME=$(/usr/libexec/PlistBuddy -c 'print :FULL_NAME' "${globalVariablesPlist}")
EMAIL=$(/usr/libexec/PlistBuddy -c 'print :EMAIL' "${globalVariablesPlist}")
EMAIL_PREFIX=$(/usr/libexec/PlistBuddy -c 'print :EMAIL_PREFIX' "${globalVariablesPlist}")
USERNAME=$(/usr/libexec/PlistBuddy -c 'print :USERNAME' "${globalVariablesPlist}")
USERNAME_PREFIX=$(/usr/libexec/PlistBuddy -c 'print :USERNAME_PREFIX' "${globalVariablesPlist}")
DEPARTMENT=$(/usr/libexec/PlistBuddy -c 'print :DEPARTMENT' "${globalVariablesPlist}")
JOB_TITLE=$(/usr/libexec/PlistBuddy -c 'print :JOB_TITLE' "${globalVariablesPlist}")
DEVICE_NAME=$(/usr/libexec/PlistBuddy -c 'print :DEVICE_NAME' "${globalVariablesPlist}")
SERIAL_NUMBER=$(/usr/libexec/PlistBuddy -c 'print :SERIAL_NUMBER' "${globalVariablesPlist}")
ASSET_TAG=$(/usr/libexec/PlistBuddy -c 'print :ASSET_TAG' "${globalVariablesPlist}")
DEVICE_ID=$(/usr/libexec/PlistBuddy -c 'print :DEVICE_ID' "${globalVariablesPlist}")
BLUEPRINT_NAME=$(/usr/libexec/PlistBuddy -c 'print :BLUEPRINT_NAME' "${globalVariablesPlist}")
BLUEPRINT_ID=$(/usr/libexec/PlistBuddy -c 'print :BLUEPRINT_ID' "${globalVariablesPlist}")
UDID=$(/usr/libexec/PlistBuddy -c 'print :UDID' "${globalVariablesPlist}")
PROFILE_UUID=$(/usr/libexec/PlistBuddy -c 'print :PROFILE_UUID' "${globalVariablesPlist}")
MODEL_NAME=$(/usr/libexec/PlistBuddy -c 'print :MODEL_NAME' "${globalVariablesPlist}")
MODEL_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'print :MODEL_IDENTIFIER' "${globalVariablesPlist}")

echo "Global Variables Summary
Full Name: $FULL_NAME
Email: $EMAIL
Email Prefix: $EMAIL_PREFIX
Username: $USERNAME
Username Prefix: $USERNAME_PREFIX
Department: $DEPARTMENT
Job Title: $JOB_TITLE
Device Name: $DEVICE_NAME
Serial Number: $SERIAL_NUMBER
Asset Tag: $ASSET_TAG
Device ID: $DEVICE_ID
Blueprint Name: $BLUEPRINT_NAME
Blueprint ID: $BLUEPRINT_ID
Hardware UDID: $UDID
Model Name: $MODEL_NAME
Model Identifier: $MODEL_IDENTIFIER
Profile UUID: $PROFILE_UUID"

exit 0