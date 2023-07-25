#!/bin/zsh

################################################################################################
# Created by Jan Rosenfeld | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 5.22.23
#   Updated - 6.19.23
#
################################################################################################
# TESTED MACOS VERSIONS
################################################################################################
#
#   - 13.4.1
#
################################################################################################
# SOFTWARE INFORMATION
################################################################################################
#
#   Enable Remote Desktop via the Kandji API. 
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

# This script will use the Kandji "Remote Desktop" API to toggle on Remote Desktop.
# Useful in Self Service, or run automatically to enable Remote Desktop across a Blueprint.

	# This script will install JQ in order to parse JSON data, then remove JQ 
	
############### VARIABLES ################################################################

# Set your kandji subdomain (example: for "beekeepr.kandji.io", enter "beekeepr")
subdomain="subdomain"

# Set your region (example: "us" or "eu")
region="us"

# The API token must have permissions for: Update a Device, Device List, Remote Desktop
token="API_token_here"


############### DEPENDENCIES #############################################################

regionLower=$(/bin/echo "$region" | /usr/bin/tr '[:upper:]' '[:lower:]')

# Kandji API base URL
if [[ -z $regionLower || $regionLower == "us" ]]; then
  base_url="https://${subdomain}.api.kandji.io/api"
elif [[ $regionLower == "eu" ]]; then
  base_url="https://${subdomain}.api.${regionLower}.kandji.io/api"
else
  /bin/echo "Unsupported region: $regionLower. Please update and try again."
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

# Clean up Kandji jq
cleanup_jq(){
  /bin/echo "Removing Kandji jq files."
  if [[ $(/bin/ls /Library/KandjiSE | /usr/bin/wc -l) == "       3" ]]; then
    /bin/rm -rf /Library/KandjiSE
  else
    /bin/rm /Library/KandjiSE/jq
    /bin/rm /Library/KandjiSE/JQ-1.6-UNIVERSAL.pkg.tar.gz
    /bin/rm /Library/KandjiSE/JQ-1.6-UNIVERSAL.pkg
  fi
}

############### MAIN LOGIC - GET DEVICE ID ###############################################


# Get the device serial number
serial_number=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 |
    /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

if [[ -z "$serial_number" ]]; then
    /bin/echo "Had an issue pulling device serial number ..."
    exit 1
fi

# Search for device by serial number
device_record=$(/usr/bin/curl --silent --request GET --url "$base_url/v1/devices/?serial_number=$serial_number" --header "Authorization: Bearer $token")

# Error check to make sure we received device record from API call
if [[ -z "$device_record" ]] || [[ "$device_record" == "[]" ]]; then
  /bin/echo "Had an issue pulling device record from Kandji. Exiting..."
  exit 1
else
  /bin/echo "Device record found!"
fi

# Parse device_record and extract device ID using jq
device_id=$(/bin/echo "$device_record" | $jq_binary -r '.[0].device_id')

# Print the device ID
/bin/echo "Device ID: $device_id"


############### MAIN LOGIC - PASS DEVICE ID TO REMOTE DESKTOP API ########################

# Enable Remote Desktop
/bin/echo "Enabling Remote Desktop..."
response=$(/usr/bin/curl --location --request POST --url "$base_url/v1/devices/$device_id/action/remotedesktop" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $token" \
  --data-raw '{
    "EnableRemoteDesktop": true
  }'
)
if [[ $? -ne 0 ]]; then
  /bin/echo "Failed to enable Remote Desktop: $response"
  exit 1
else
  /bin/echo "--- Remote Desktop enabled successfully!"
fi

cleanup_jq
exit 0
