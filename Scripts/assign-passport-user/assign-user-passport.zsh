#!/bin/zsh

################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 07/13/2023
#
################################################################################################
# TESTED MACOS VERSIONS
################################################################################################
#
#   - 13.4.1
#   - 12.6.1
#
################################################################################################
# SOFTWARE INFORMATION
################################################################################################
#
# This script is designed to automatically look for the IdP user who signed in with Passport and 
# assign that user to the device record in Kandji. 
#
# It will look up the IdP user in your Kandji SCIM Directory Integration, and if a match is
# found, assign that user to the device record.
#
# For details, see https://github.com/kandji-inc/support/tree/main/Scripts/assign-passport-user
#
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

# Script version
VERSION="1.0.0"

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# Set your Kandji subdomain (example: for "beekeepr.kandji.io", enter "beekeepr")
subdomain="subdomain"

# Set your region (example: "us" or "eu")
region="us"

# Kandji SCIM Integration API token
scimToken="SCIM token goes here"

# Kandji API token
apiToken="API token goes here"

################################################################################################
########################### FUNCTIONS - DO NOT MODIFY BELOW ####################################
################################################################################################

# Check if jq is installed and if not, install it
check_jq(){
  if [[ ! -z $(/usr/bin/command -v jq) ]]; then
    /bin/echo "jq is already installed."
    jq_binary=$(/usr/bin/which jq)
  elif [[ -e "/Library/KandjiSE/jq" ]]; then
    /bin/echo "Kandji jq is already present."
  	jq_binary="/Library/KandjiSE/jq"
  else
    /bin/echo "jq is not installed. Installing jq..."
    install_jq
  fi
}

# Install jq 1.6 from Kandji GitHub
install_jq(){
  if [[ ! -d "/Library/KandjiSE" ]]; then
    /bin/mkdir "/Library/KandjiSE"
  fi  
  	cd /Library/KandjiSE/
  	/usr/bin/curl -LOs --url "https://github.com/kandji-inc/support/raw/main/UniversalJQ/JQ-1.6-UNIVERSAL.pkg.tar.gz"
  	/usr/bin/tar -xf JQ-1.6-UNIVERSAL.pkg.tar.gz
  	/usr/sbin/installer -pkg JQ-1.6-UNIVERSAL.pkg -target / > /dev/null
  	jq_binary="/Library/KandjiSE/jq"
    jqKandjiInstall="true"
}

# Check for logged in user, if they are a system user, exit
currentUser(){
  # Get the current logged in user excluding loginwindow, _mbsetupuser, and root
  localAccount=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')
  /bin/echo "Current user is: $localAccount"
  # Make sure that we can find the logged in user
  if [[ $localAccount == "" ]]; then
      /bin/echo "ERROR: A system user or no user is currently logged in."
      exit 1
  fi
}

# Check for Passport enabled user, if not enabled, exit
assignmentCheck(){
  passportLinkedAccountName=$(/usr/bin/dscl . -read /Users/$localAccount "io.kandji.KandjiLogin.LinkedAccountName" 2>&1)

  if [[ "$passportLinkedAccountName" == *"No such key"* ]]; then
    /bin/echo "ERROR: Account '$localAccount' does not appear to be managed by Passport."
    exit 1
  else
    passportEmailAddress=$(/bin/echo $passportLinkedAccountName | /usr/bin/awk '{print $2}')
    /bin/echo "Account '$localAccount' appears to be managed by Passport."
    /bin/echo "$localAccount's e-mail address is $passportEmailAddress"
  fi
}

# Get Device ID
getKandjiDeviceID(){
  # Get the computer's serial number
  serialNumber=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

  if [[ -z "$serialNumber" ]]; then
    /bin/echo "ERROR: Had an issue getting the computer's serial number."
    exit 1
  fi

  # Search for device by serial number
  kandjiDeviceRecord=$(/usr/bin/curl --silent --request GET --url "$baseURL/v1/devices/?serial_number=$serialNumber" --header "Authorization: Bearer $apiToken")

  if [[ -z "$kandjiDeviceRecord" ]]; then
    /bin/echo "ERROR: Had an issue getting device details from Kandji."
    exit 1
  fi

  # Parse kandjiDeviceRecord and extract device ID using jq
  kandjiDeviceID=$(/bin/echo "$kandjiDeviceRecord" | $jq_binary -r '.[0].device_id')
}

# Get User ID from Kandji
getKandjiUserID(){
  # Make the SCIM api call to get the user record
  response=$(/usr/bin/curl --silent --location --url "$baseURL/v1/scim/Users?filter=userName%20eq%20%22${passportEmailAddress}%22" --header 'Authorization: Bearer '$scimToken'')

  # Check if curl command was successful
  if [ $? -ne 0 ]; then
    /bin/echo "ERROR: Failed to make the SCIM API call."
    exit 1
  fi

  # Parse the SCIM JSON response for the user ID (and generate user_id variable)
  kandjiUserID=$(/bin/echo "$response" | $jq_binary --arg email "$passportEmailAddress" '.Resources[] | select(.emails[].value == $email) | .id')

  # Check if parsing was successful
  if [ $? -ne 0 ]; then
    /bin/echo "ERROR: Failed to parse the SCIM API response using jq."
    exit 1
  fi

  # Check if user ID is empty
  if [ -z "$kandjiUserID" ]; then
    /bin/echo "ERROR: Kandji User ID not found for the current user."
    exit 1
  fi

  # State the User ID for the given email
  /bin/echo "The Kandji User ID for $passportEmailAddress is $kandjiUserID"
}

# Assign user to device
assignUserToDevice(){
  # Update Device Record in Kandji
  updateDeviceResponse=$(/usr/bin/curl --silent --request PATCH --url "$baseURL/v1/devices/$kandjiDeviceID"/ --header "Authorization: Bearer $apiToken" --header "Content-Type: $CONTENT_TYPE" --data "{
      \"user\": \"$kandjiUserID\"
  }")

  if [[ "$updateDeviceResponse" == "400" ]]; then
    /bin/echo "Bad request code $updateDeviceResponse ..."
    exit 1
  else
    /bin/echo "The device has been updated with a new assigned user."
  fi
}

# Clean up Kandji jq if used
cleanup_jq(){
  if [[ $jqKandjiInstall != "true" ]] ; then
  else
    /bin/echo "Removing Kandji jq files."
    if [[ $(/bin/ls /Library/KandjiSE | /usr/bin/wc -l) == "       3" ]]; then
      /bin/rm -rf /Library/KandjiSE
    else
      /bin/rm /Library/KandjiSE/jq
      /bin/rm /Library/KandjiSE/JQ-1.6-UNIVERSAL.pkg.tar.gz
      /bin/rm /Library/KandjiSE/JQ-1.6-UNIVERSAL.pkg
    fi
  fi
}

################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##################################
################################################################################################

# Kandji API base URL
if [[ -z $region || $region == "us" ]]; then
  baseURL="https://${subdomain}.api.kandji.io/api"
elif [[ $region == "eu" ]]; then
  baseURL="https://${subdomain}.api.${region}.kandji.io/api"
else
  /bin/echo "Unsupported region: $region. Please update and try again."
  exit 1
fi

# Content Type
CONTENT_TYPE="application/json"

# Check for & install jq (prefer to not do this)
check_jq

# Check for logged in user, if they are a system user or part of exemption list exit
currentUser

# Get Device ID
getKandjiDeviceID

# Check for passport enabled user, if not, exit
assignmentCheck

# Get User ID from Kandji
getKandjiUserID

# Assign user to device
assignUserToDevice

# Clean up Kandji jq if used
cleanup_jq

exit 0