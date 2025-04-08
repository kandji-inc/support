#!/bin/zsh

################################################################################
# Created by Jan Rosenfeld | Solutions Engineering | Kandji, Inc.
################################################################################
#
# Created on 2023/05/22
# Updated on 2024/04/10
#
################################################################################
# Tested macOS Versions
################################################################################
#
#   - 14.4.1
#   - 13.2.1
#   - 12.3.1
#
################################################################################
# Software Information
################################################################################
#
# This script is designed to automatically toggle on Remote Management for any 
# macOS endpoint it is run on. When assigned to a Blueprint, this script will enable 
# Remote Desktop for all devices associated with that Blueprint, or it could be executed 
# via Self Service for a user-centric approach.
#
###################################################################################################
# License Information
###################################################################################################
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
###################################################################################################

# Script Version
VERSION="2.0.0"

##############################################################################
############################# USER INPUT #####################################
##############################################################################

# Kandji Subdomain
subdomain="mycompany"

# Region (us and eu) - this can be found in the Kandji settings on the
# Access tab
region=""

# API Bearer Token
# The API token must have permissions for: Update a Device, Device List, Remote Desktop
token="your-token-here"

##############################################################################
############################# VARIABLES - DO NOT MODIFY BELOW ################
##############################################################################

# Ensure region variable is lowercase
region="${region:l}"

# Kandji API base URL
if [[ -z $region || $region == "us" ]]; then
  base_url="https://${subdomain}.api.kandji.io/api"
elif [[ $region == "eu" ]]; then
  base_url="https://${subdomain}.api.${region}.kandji.io/api"
else
  echo "Unsupported region: $region. Please update and try again."
  exit 1
fi

# OS Version
osVer="$(sw_vers -productVersion)"

# Device Serial
serialnum=$(system_profiler SPHardwareDataType | awk '/Serial/ { print $NF }')

# Content Type
content_type="application/json"

##############################################################################
################## FUNCTIONS - DO NOT MODIFY BELOW ###########################
##############################################################################

api_device_record(){
  device_record=$(/usr/bin/curl --silent --request GET \
    --url "$base_url/v1/devices/?serial_number=$serialnum" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: $content_type")
}

get_device_id_value() {
  if [[ $osVer > 12. ]]; then
    # Parsing w/ plutil. Supported on macOS Monterey+
    device_id=$(/usr/bin/plutil -extract 0.device_id raw -o - - <<< "$device_record")
  else
    # Convert record to XML for plutil OS compatibility (pre-Monterey)
    device_record_xml=$(/usr/bin/plutil -convert xml1 -o - - <<< "$device_record" )
    # Parse for Device ID
    device_id=$(/usr/libexec/PlistBuddy -c "Print 0:device_id" /dev/stdin <<< "$device_record_xml")
  fi
}

##############################################################################
################### MAIN LOGIC - DO NOT MODIFY BELOW #########################
##############################################################################

api_device_record

get_device_id_value

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

exit 0
