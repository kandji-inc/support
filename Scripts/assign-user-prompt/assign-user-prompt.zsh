#!/bin/zsh

###################################################################################################
# Created by Jan Rosenfeld | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created - 5.22.23
#   Updated - 6.19.23
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   - 13.3.1
#
###################################################################################################
# Software Information
###################################################################################################
#
#   Prompt macOS user to update user assignment in device record.
#
###################################################################################################
# License Information
###################################################################################################
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
###################################################################################################

# This script will prompt an end user to input an email address, then search the Kandji SCIM 
# directory integration for that email. If found, it will update the assigned user field in the 
# device record for that device.

	# This script is intended to be used in Kandji Self Service
	# This script requiers a SCIM directory integration in Kandji
	# This script will install JQ in order to parse JSON data
	

############### VARIABLES ###########################################################################

# Set your kandji subdomain (example: for "beekeepr.kandji.io", enter "beekeepr")
subdomain="subdomain"

# Set your region (example: "us" or "eu")
region="us"

# Set the SCIM API token
scim_token="SCIM token goes here"

# API token (requires "Device Information" permissions)
token="API token goes here"


############### DEPENDENCIES ###########################################################################


# Kandji API base URL
if [[ -z $region || $region == "us" ]]; then
  base_url="https://${subdomain}.api.kandji.io/api"
elif [[ $region == "eu" ]]; then
  base_url="https://${subdomain}.api.${region}.kandji.io/api"
else
  /bin/echo "Unsupported region: $region. Please update and try again."
  exit 1
fi

# Content Type
CONTENT_TYPE="application/json"

# Check if jq is installed and install it if not
check_jq() {
  if ! /usr/bin/command -v jq &> /dev/null; then
    /bin/echo "jq is not installed. Installing jq..."
    install_jq
  else
    /bin/echo "jq is already installed."
    jq_binary=$(/usr/bin/which jq)
  fi
}

install_jq() {
  if [[ ! -d "/Library/KandjiSE" ]]; then
    /bin/mkdir "/Library/KandjiSE"
  fi  
  	cd /Library/KandjiSE/
  	/usr/bin/curl -LOs --url "https://github.com/kandji-inc/support/raw/main/UniversalJQ/JQ-1.6-UNIVERSAL.pkg.tar.gz"
  	/usr/bin/tar -xf JQ-1.6-UNIVERSAL.pkg.tar.gz
  	/usr/sbin/installer -pkg JQ-1.6-UNIVERSAL.pkg -target / > /dev/null
  	jq_binary="/Library/KandjiSE/jq"
}

check_jq


############### MAIN LOGIC - END USER INPUT ############################################################


# Prompt the end user for their email address
user_response=$(/usr/bin/osascript -e 'display dialog "Please enter your email address" default answer "you@yourcompany.com" buttons {"Cancel", "Submit"} default button "Submit"')

# Parse email address entered by the end user
user_email=$(/bin/echo "$user_response" | /usr/bin/awk -F ":" '{print $NF}')

/bin/echo The user entered "$user_email"


############### MAIN LOGIC - GET USER ID ############################################################


# Make the SCIM api call (change the count value if you have more users)
response=$(/usr/bin/curl --location --url "$base_url/v1/scim/Users?count=10000" \
--header 'Authorization: Bearer '$scim_token'')

# Check if curl command was successful
if [ $? -ne 0 ]; then
  /bin/echo "Error: Failed to make the SCIM API call."
  exit 1
fi

# Parse the SCIM JSON response for the user ID (and generate user_id variable)
user_id=$(/bin/echo "$response" | $jq_binary --arg email "$user_email" '.Resources[] | select(.emails[].value == $email) | .id')

# Check if parsing was successful
if [ $? -ne 0 ]; then
  /bin/echo "Error: Failed to parse the SCIM API response using jq."
  /usr/bin/osascript -e 'display dialog "Unable to search the directory. We will alert your administrator." buttons ("OK")'
  exit 1
fi

# Check if user ID is empty
if [ -z "$user_id" ]; then
  /bin/echo "Error: User ID not found for the given email."
  /usr/bin/osascript -e 'display dialog "Your email was not found in the directory, but we will alert your administrator." buttons ("OK")'
  exit 1
fi

# State the User ID for the given email
/bin/echo "The Kandji User ID for $user_email is $user_id"


############### MAIN LOGIC - GET DEVICE ID ############################################################


# Get the device serial number
serial_number=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 |
    /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

if [[ -z "$serial_number" ]]; then
    /bin/echo "Had an issue pulling device serial number ..."
    /usr/bin/osascript -e 'display dialog "There was an issue with your serial number, but we will alert your administrator." buttons ("OK")'
    exit 1
fi

# Search for device by serial number
device_record=$(/usr/bin/curl --silent --request GET --url "$base_url/v1/devices/?serial_number=$serial_number" --header "Authorization: Bearer $token")

if [[ -z "$device_record" ]]; then
    /bin/echo "Had an issue pulling devices from Kandji ..."
    /usr/bin/osascript -e 'display dialog "Your device was not found in the system, but we will alert your administrator." buttons ("OK")'
    exit 1
fi

# Parse device_record and extract device ID using jq
device_id=$(/bin/echo "$device_record" | $jq_binary -r '.[0].device_id')

# Print the device ID
/bin/echo "Device ID: $device_id"


############### MAIN LOGIC - PASS USER ID AND DEVICE ID TO KANDJI #############################################


# Update Device Record in Kandji
update_device_response=$(/usr/bin/curl --silent --request PATCH --url "$base_url/v1/devices/$device_id"/ --header "Authorization: Bearer $token" --header "Content-Type: $CONTENT_TYPE" --data "{
    \"user\": \"$user_id\"
}")


if [[ "$update_device_response" == "400" ]]; then
    /bin/echo "Bad request code $update_device_response ..."
      /usr/bin/osascript -e 'display dialog "Unable to assign your device at this time, but we will alert your administrator." buttons ("OK")'
    exit 1
fi

# Print response and alert the end user
/bin/echo "The device has been updated with a new assigned user."
/usr/bin/osascript -e 'display dialog "Thanks! Your device has been assigned." buttons ("OK")'

exit 0
fi
