#!/bin/zsh
################################################################################################
# Created by Brian van Peski & Jan Rosenfeld | Solutions Engineering | Kandji, Inc.
################################################################################################
# Created on 2023/10/17
# Updated on 2023/10/25
################################################################################################
# Based on the LAPS retrieval scripts created by James Smith - https://github.com/smithjw
# macOSLAPS was created by Joshua D. Miller - josh.miller@outlook.com
################################################################################################
# Tested macOS Versions
################################################################################################
#   - 14.0
################################################################################################
# Software Information
################################################################################################
# Collects the Current Password and Expiration Date from macOSLAPS and submits
# that to a device's Notes in Kandji.
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

VERSION=1.0

################################################################################################
# REQUIREMENTS
################################################################################################

# This script has been tested on macOS 12+ which supports the plutil raw commands.
# It does not work on earlier versions of macOS.

# macOSlaps must be installed and configured on endpoints running this script.
# Download macOSLAPS here: https://github.com/joshua-d-miller/macOSLAPS

# A configuration profile should be used to set macOSLAPS preferences.
# The template provided by iMazing Profile Editor is recommended.
# iMazing Profile Editor can be downloaded here: https://imazing.com/profile-editor

################################################################################################
# CONSIDERATIONS
################################################################################################

# The date on a device note is the creation date, and does not represent when the note
# was last modified. To track changes, refer to the datetime variable in the note content.
#
# Note that both custom script library item output, as well as device Notes, is viewable by all
# team member role types in Kandji as the password is stored in plaintext.

##############################################################
# SET LOGGING
##############################################################
# Set logging - Send logs to stdout as well as Unified Log
# Use 'log show --process "logger"'to view logs activity.
LOGGING(){
    /bin/echo "${1}"
    /usr/bin/logger "LAPSRetriever: ${1}"
}

##############################################################
# USER INPUT
##############################################################

# Kandji Subdomain
subdomain="mycompany"

# Region (us and eu) - this can be found in the Kandji settings on the Access tab
region=""

# API Bearer Token
# The API token must have permissions for: Device List, Create Note, Update Note, Device Notes
token="YOUR-TOKEN-HERE"

# Note Title
# You'll need to include a UNIQUE note title or specific piece of information from a note in order to grab it's UUID and continuously update it.
noteTitle="LAPS Information"

##############################################################
# VARIABLES
##############################################################

# Path to macOSLAPS binary
LAPS="/usr/local/laps/macOSLAPS"
# Path to Password File
PW_FILE="/var/root/Library/Application Support/macOSLAPS-password"
# Path to Expiration File
EXP_FILE="/var/root/Library/Application Support/macOSLAPS-expiration"
# Local Admin Account
LOCAL_ADMIN=$(/usr/bin/defaults read \
  "/Library/Managed Preferences/edu.psu.macoslaps.plist" LocalAdminAccount)

# Device Serial
serialnum=$(system_profiler SPHardwareDataType | awk '/Serial/ { print $NF }')

# Timestamp to add "last updated" to note.
datetime=$(date)

# Kandji API base URL
if [[ -z $region || $region == "us" ]]; then
  base_url="https://${subdomain}.api.kandji.io/api"
elif [[ $region == "eu" ]]; then
  base_url="https://${subdomain}.api.${region}.kandji.io/api"
else
  LOGGING "Unsupported region: $region. Please update and try again."
  exit 1
fi

##############################################################
# FUNCTIONS
##############################################################

verify_requirements() {
  # Check if macOSLAPS binary exists
  if [[ -e $LAPS ]]; then
    LOGGING "--- macOSLAPS is installed"
  else
    LOGGING "--- macOSLAPS is NOT installed. Exiting..."
    exit 1
  fi
  
  # Check if config profile exists.
  if [[ -f "/Library/Managed Preferences/edu.psu.macoslaps.plist" ]]; then
	 /bin/echo "--- Config profile is present ..."
  else
	 /bin/echo "--- Missing macOSLAPS Configuration Profile..."
	 /bin/echo "--- Will check again on next Kandji Agent check-in ..."
	 exit 1
  fi
  
  # Verify the local admin specified in the config profile exists.
  if id "$LOCAL_ADMIN" >&/dev/null; then
    LOGGING "--- Local Admin account $LOCAL_ADMIN exists"
  else
    LOGGING "--- Admin account not found. Double-check that the LocalAdminAccount value is correct in your configuration profile and that the account has been created on the machine. Exiting..."
    exit 1
  fi
}

api_device_record(){
  device_record=$(/usr/bin/curl --silent --request GET --url "$base_url/v1/devices/?serial_number=$serialnum" \
  --header "Authorization: Bearer $token" \
  --header "Content-Type: $content_type")
}

api_device_notes(){
  device_notes=$(/usr/bin/curl --silent --request GET --url "$base_url/v1/devices/$device_id/notes" \
  --header "Authorization: Bearer $token" \
  --header "Content-Type: $content_type")
}

add_note(){
  # Count how many notes exist to loop through
  sleep 1 # Trying to sleep for a second to figure out why it sometimes returns 0 items
  notes_index=$( /usr/bin/plutil -extract notes raw -o - - <<< "$device_notes" )
  LOGGING "--- Notes payload has $notes_index entries..."
  
  #Loop to see if note with notetitle already exists...
  for i in {0.."$notes_index"}
  do
    # Find a value in the content of the current Note we're processing
    note_contents=$( /usr/bin/plutil -extract notes.$i."content" raw -o - - <<< "$device_notes" )
    # Does the noteTitle match? If so, find it's id.
    [[ "$note_contents" == *"$noteTitle"* ]] && noteid=$( /usr/bin/plutil -extract notes.$i.note_id raw -o - - <<< "$device_notes" )
  done
  
  if [ -z $noteid ]; then
    LOGGING "No matching note found. Generating new note..."
    /usr/bin/curl --location --request POST ''$base_url'/v1/devices/'$device_id'/notes/' \
    --header 'Authorization: Bearer '$token'' \
    --header 'Content-Type: application/json' \
    --data-raw '{
      "content": "'$noteMessage'"
    }' &>/dev/null
  else
    LOGGING "Note found. Updating existing note..."
    /usr/bin/curl --location --request PATCH ''$base_url'/v1/devices/'$device_id'/notes/'$noteid'/' \
    --header 'Authorization: Bearer '$token'' \
    --header 'Content-Type: application/json' \
    --data-raw '{
      "content": "'$noteMessage'"
    }' &>/dev/null
  fi
}

################################################################
#  MAIN LOGIC
################################################################

# Verify macOSLAPS requirements and that the local admin account is present
LOGGING "Validating macOSLAPS Requirements..."
verify_requirements

# Ask macOSLAPS to write out the current password and echo it for the Kandji record
LOGGING "Fetching current password and expiration date..."
$LAPS -getPassword > /dev/null
CURRENT_PASSWORD=$(/bin/cat "$PW_FILE" 2>/dev/null)
EXPIRATION_DATE=$(/bin/cat "$EXP_FILE" 2>/dev/null)
# Test $current_password to ensure there is a value
if [ -z "$CURRENT_PASSWORD" ]; then
  # Don't Write anything to Kandji as it might overwrite an old password in place that might still be needed.
  exit 0
else
  LOGGING "| Password: $CURRENT_PASSWORD | Expiration: $EXPIRATION_DATE |"
  # Run macOSLAPS a second time to remove the password file and expiration date file from the system
  $LAPS
fi

# Escape any special characters in the password that might result in invalid JSON or HTML.
CURRENT_PASSWORD=$(/bin/echo $CURRENT_PASSWORD | /usr/bin/sed 's/\\/\\\\/g; s/"/\\"/g' | /usr/bin/sed 's/</\&lt;/g; s/>/\&gt;/g')

# Composing note content with password and expiration.
noteMessage="<h1>$noteTitle</h1><br><br><strong>Current Password:</strong> $CURRENT_PASSWORD<br><br><strong>Password Expiration:</strong> $EXPIRATION_DATE<br><br><small>Note updated: $datetime</small>"

# Fetch Device Info for serial number.
LOGGING "Fetching Device Record..."
api_device_record
# Parse returned JSON for device_id.
LOGGING "Fetching device id..."
device_id=$(/usr/bin/plutil -extract 0.device_id raw -o - - <<< "$device_record")
LOGGING "--- Found device id: $device_id"
# Fetch any existing notes for the device.
LOGGING "Fetching device notes..."
api_device_notes
# Add notes to device.
LOGGING "Adding Note to device record..."
add_note
