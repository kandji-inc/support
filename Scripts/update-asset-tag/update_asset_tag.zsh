#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created - 12/09/2021
#   Updated - 2023-04-28
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   - 13.1
#   - 12.6.1
#   - 11.7.1
#
###################################################################################################
# Software Information
###################################################################################################
#
#   Update device asset tag from self service.
#
#   This script is designed to be run from Self Service. Update the BASE_URL and TOKEN varialbes
#   to meet your needs.
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

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

# Kandji tenant subdomain
SUBDOMAIN="accuhive" # accuhive

# tenant region
REGION="us" # us, eu

# Kandji Bearer Token
TOKEN="your_api_key_here"

########################################################################################

# Kandji API base URL
if [[ -z $REGION || $REGION == "us" ]]; then
  BASE_URL="https://${SUBDOMAIN}.api.kandji.io/api"
elif [[ $REGION == "eu" ]]; then
  BASE_URL="https://${SUBDOMAIN}.api.${REGION}.kandji.io/api"
else
  echo "Unsupported region: $REGION. Please update and try again."
  exit 1
fi

###################################################################################################
###################################### FUNCTIONS ##################################################
###################################################################################################

get_device_info_value() {
    # Return a json value
    #
    # Must pass in the JSON data, serial number of a device, and the search key that you want to
    # return the value for out of the JSON data object.
    #
    # Args:
    #   $1: JSON data  $2: serial_number  $3: search key

    read -r -d '' JSON <<EOF
    function run() {

        // parsed json data
        const devices = JSON.parse(\`$1\`);

        for (const device of devices) {

            // If the serial number is found return the seach key value
            if ( device.serial_number == "$2" ) {

                return device.$3

            }
    	}
    }
EOF

    /usr/bin/osascript -l "JavaScript" <<<"${JSON}"
}

###################################################################################################
###################################### MAIN LOGIC #################################################
###################################################################################################

# Get the device serial number
serial_number=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 |
    /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

if [[ -z "$serial_number" ]]; then
    echo "Had an issue pulling device serial number ..."
    exit 1
fi

# debug: Print the serial_number var
# echo "$serial_number"

echo "$BASE_URL/v1/devices?serial_number=$serial_number"
# search for device by serial number
device_record=$(/usr/bin/curl --silent --request GET \
    --url "$BASE_URL/v1/devices?serial_number=$serial_number" \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/json")

if [[ -z "$device_record" ]]; then
    echo "Had an issue pulling devices from Kandji ..."
    exit 1
fi

# debug: Print device record information
# echo ""
# echo "$device_record"
# echo ""

# Get the Kandji device_id based on the provided serial number.
device_id=$(get_device_info_value "$device_record" "$serial_number" "device_id")

if [[ -z "$device_id" ]]; then
    echo "Did not find the device ID associated with $serial_number"
    exit 1
else
    echo "Found $device_id associated with $serial_number ..."
fi

# Prompt the user for their device asset tag
user_response=$(/usr/bin/osascript -e 'display dialog "Please enter you Mac 🐝 Asset Tag" default answer "bee-" buttons {"Cancel", "Update"} default button "Update"')

# parse asset_tag entered by user
asset_tag=$(echo "$user_response" | /usr/bin/awk -F ":" '{print $NF}')

# Update asset tag in Kandji
update_asset_tag_response=$(/usr/bin/curl --silent --request PATCH \
    --url "$BASE_URL/v1/devices/$device_id"/ \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
    \"asset_tag\": \"$asset_tag\"
}")

if [[ "$update_asset_tag_response" == "400" ]]; then
    echo "Bad request code $update_asset_tag_response ..."
    exit 1
fi

# debug: Print response
# echo "$update_asset_tag_response"

exit 0
