#!/bin/zsh
################################################################################################
# Created by Nicholas McDonald | support@kandji.io | Kandji, Inc.
################################################################################################
#
# Created - 03/29/2021
# Updated - 10/24/2024 - Brian Goldstein
#
################################################################################################
# Software Information
################################################################################################
#
# Example script reading in Kandji global variables from the global variables custom profile.
#
# For more information about Global Variables, please refer to the Kandji Knowledge Base
# https://support.kandji.io/kb/global-variables
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

FULL_NAME=$(/usr/libexec/PlistBuddy -c 'print :FULL_NAME' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
EMAIL=$(/usr/libexec/PlistBuddy -c 'print :EMAIL' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
EMAIL_PREFIX=$(/usr/libexec/PlistBuddy -c 'print :EMAIL_PREFIX' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
DEPARTMENT=$(/usr/libexec/PlistBuddy -c 'print :DEPARTMENT' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
JOB_TITLE=$(/usr/libexec/PlistBuddy -c 'print :JOB_TITLE' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
DEVICE_NAME=$(/usr/libexec/PlistBuddy -c 'print :DEVICE_NAME' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
SERIAL_NUMBER=$(/usr/libexec/PlistBuddy -c 'print :SERIAL_NUMBER' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
ASSET_TAG=$(/usr/libexec/PlistBuddy -c 'print :ASSET_TAG' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
DEVICE_ID=$(/usr/libexec/PlistBuddy -c 'print :DEVICE_ID' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
BLUEPRINT_NAME=$(/usr/libexec/PlistBuddy -c 'print :BLUEPRINT_NAME' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
BLUEPRINT_ID=$(/usr/libexec/PlistBuddy -c 'print :BLUEPRINT_ID' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
UDID=$(/usr/libexec/PlistBuddy -c 'print :UDID' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
PROFILE_UUID=$(/usr/libexec/PlistBuddy -c 'print :PROFILE_UUID' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
MODEL_NAME=$(/usr/libexec/PlistBuddy -c 'print :MODEL_NAME' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)
MODEL_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'print :MODEL_IDENTIFIER' /Library/Managed\ Preferences/io.kandji.globalvariables.plist)

echo "
Global Variables Summary

Full Name: $FULL_NAME

Email: $EMAIL

Email Prefix: $EMAIL_PREFIX

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

Profile UUID: $PROFILE_UUID
"

exit 0