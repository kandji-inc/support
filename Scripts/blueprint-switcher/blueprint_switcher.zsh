#!/bin/zsh

################################################################################################
# Created by Brian Van Peski, Jan Rosenfeld & Matt Wilson
# support@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
#
# Created on 7/13/2023
#
########################################################################################
# Tested macOS Versions
########################################################################################
#
#   - 13.4.1
#   - 12.6.1
#   - 11.7.6
#
################################################################################################
# Software Information
################################################################################################
# 
# Move an enrolled device to another blueprint via the Kandji API.
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
###############################################################################################

# Set logging - Send logs to stdout as well as Unified Log
# Use 'log show --process "logger"'to view logs activity.
LOGGING {
    /bin/echo "${1}"
    /usr/bin/logger "bp_switcher: ${1}"
}

##############################################################
# USER INPUT 
##############################################################

# Kandji Subdomain
subdomain="mycompany"

# Region (us and eu) - this can be found in the Kandji settings on the Access tab
region=""

# API Bearer Token
# The API token must have permissions for: List Blueprints, Get Blueprint, Update a Device, Device List, Device Details.
token="your-token-here"

# Blueprint name (This is the name of the blueprint as it exists in Kandji that you want to assign devices to).
# You can also use a Blueprint UUID (useful if your Blueprint has emojis or other special characters).
assignBlueprint="BlueprintName"

# User Notification (When set to true, the script will notify end-users about Blueprint changes).
notifyUsers=false


##############################################################
# VARIABLES
##############################################################

# OS Version
osVer="$(sw_vers -productVersion)"
# Device Serial
serialnum=$(system_profiler SPHardwareDataType | awk '/Serial/ { print $NF }')

# URl Encode Blueprint Name
blueprint_name_enc="${assignBlueprint// /%20}"

# Content Type
content_type="application/json"

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

blueprint_value_validator(){
  # Determine if given blueprint value is a name or UUID.
  if [[ $assignBlueprint =~ [0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12} ]]; then
    LOGGING "User-provided blueprint UUID is: $assignBlueprint"
    bpvalue="UUID"
  else
    LOGGING "User-provided blueprint name: $assignBlueprint"
  fi
}

api_device_record(){
  device_record=$(/usr/bin/curl --silent --request GET \
    --url "$base_url/v1/devices/?serial_number=$serialnum" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: $content_type")
}

api_blueprint_record(){
  blueprint_record=$(/usr/bin/curl --silent --request GET \
    --url "$base_url/v1/blueprints/?name=$blueprint_name_enc" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: $content_type")
  # Parse output to validate response
  if [[ $osVer > 12. ]]; then
    # Supported on macOS Monterey+
    bp_count=$(/usr/bin/plutil -extract count raw -o - - <<< "$blueprint_record")
  else
    # Clean up JSON null values
    blueprint_record=$(echo $blueprint_record | tr -d '\n\n' | sed 's/null/false/g')
    # Convert record to XML for plutil OS compatibility
    blueprint_record_xml=$(/usr/bin/plutil -convert xml1 -o - - <<< "$blueprint_record")
    # Parse for Device ID
    bp_count=$(/usr/libexec/PlistBuddy -c "Print count" /dev/stdin <<< "$blueprint_record_xml")
  fi

  if [[ -z "$blueprint_record" || $bp_count = 0 ]]; then
    LOGGING "Had an issue pulling blueprint id from Kandji..."
    LOGGING "Double-check that the provided Blueprint name is correct."
      if [[ $notifyUsers == true ]]; then
      /usr/local/bin/kandji display-alert --title 'ERROR!' --message 'We had an issue assigning this computer to the'$device_blueprint_name' blueprint. Please contact IT for additional support.' --no-wait
      fi
    exit 1
  elif [[ $bp_count > 1 ]]; then
    LOGGING "Had an issue pulling blueprint id from Kandji..."
    LOGGING "Found multiple blueprints that match '$assignBlueprint.'"
      if [[ $notifyUsers == true ]]; then
      /usr/local/bin/kandji display-alert --title 'ERROR!' --message 'We had an issue assigning this computer to the'$device_blueprint_name' blueprint. Please contact IT for additional support.' --no-wait
      fi
    exit 1
  else
    LOGGING "--- Blueprint record found!"
  fi
}

api_blueprint_uuid_record(){
  blueprintUUID_record=$(/usr/bin/curl --silent --request GET \
    --url "$base_url/v1/blueprints/$assignBlueprint" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: $content_type")
  # Parse output to validate response
  if [[ $osVer > 12. ]]; then
    #Supported on macOS Monterey+
    bp_detail=$(/usr/bin/plutil -extract detail raw -o - - <<< "$blueprintUUID_record")
  else
    # Clean up JSON null values
    blueprintUUID_record=$(echo $blueprintUUID_record | tr -d '\n\n' | sed 's/null/false/g')
    # Convert record to XML for plutil OS compatibility
    blueprintUUID_record_xml=$(/usr/bin/plutil -convert xml1 -o - - <<< "$blueprintUUID_record" 2>/dev/null)
    # Parse for Device ID
    bp_detail=$(/usr/libexec/PlistBuddy -c "Print detail" /dev/stdin <<< "$blueprintUUID_record_xml")
  fi
  if [[ -z "$blueprintUUID_record" || "$bp_detail" == "Not found"* ]]; then
    LOGGING "Had an issue pulling blueprint from Kandji..."
    LOGGING "Double-check that the provided Blueprint UUID is correct...."
    exit 1
  fi
}

get_device_id_value() {
  LOGGING "Parsing device id..."
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

get_blueprint_id_value() {
  # Clean up JSON for parsing. Remove everything between description and params and change any null values. 
  blueprint_record=$(echo $blueprint_record | tr -d '\n\n' | sed 's/description.*params/ /g' | sed 's/null/false/g')
  # Parsing returned blueprint record JSON
  if [[ $osVer > 12. ]]; then
    # Using plutil raw to parse blueprint id value. Supported on macOS Monterey+"
    blueprint_id=$(/usr/bin/plutil -extract results.0.id raw -o - - <<< "$blueprint_record")
  else
    # Convert JSON to xml for plutil legacy macOS compatibility
    blueprint_record_xml=$(/usr/bin/plutil -convert xml1 -o - - <<< "$blueprint_record")
    # Parse converted XML
    blueprint_id=$(/usr/libexec/PlistBuddy -c "Print results:0:id" /dev/stdin <<< "$blueprint_record_xml")
  fi
}

get_device_blueprint_value() {
  LOGGING "Fetching device blueprint..."
  # Clean up JSON for parsing
  device_record=$(echo $device_record | tr -d '\n\n' | sed 's/description.*params/ /g' | sed 's/null/false/g')
  # Parsing returned JSON
  if [[ $osVer > 12. ]]; then
    # Using plutil raw to parse device blueprint id... Supported on macOS Monterey+"
    device_blueprint=$(/usr/bin/plutil -extract 0.blueprint_id raw -o - - <<< "$device_record")
    device_blueprint_name=$(/usr/bin/plutil -extract 0.blueprint_name raw -o - - <<< "$device_record")
  else
    # Convert JSON to xml for plutil legacy macOS compatibility
    device_blueprint_xml=$(/usr/bin/plutil -convert xml1 -o - - <<< "$device_record")
    # Parse converted XML
    device_blueprint=$(/usr/libexec/PlistBuddy -c "Print 0:blueprint_id" /dev/stdin <<< "$device_blueprint_xml")
    device_blueprint_name=$(/usr/libexec/PlistBuddy -c "Print 0:blueprint_name" /dev/stdin <<< "$device_blueprint_xml")
  fi
}

move_to_blueprint(){
  LOGGING "--- Changing device blueprint to $assignBlueprint"
  /usr/bin/curl --silent --request PATCH \
  --url "$base_url/v1/devices/$device_id/" \
  --header "Content-Type: $content_type" \
  --header "Authorization: Bearer $token" \
  --data-raw '{
  "blueprint_id": "'"$blueprint_id"'"
  }' > /dev/null
}

blueprint_validator() {
  device_record=$(/usr/bin/curl --silent --request GET \
    --url "$base_url/v1/devices/?serial_number=$serialnum" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: $content_type")
  
  # Fetch UUID of device's currently assigned blueprint.
  get_device_blueprint_value
  if [[ "$device_blueprint" != "$assignBlueprint" ]]; then
    LOGGING "Had an issue re-assigning device to blueprint. Exiting..."
      if [[ $notifyUsers == true ]]; then
      /usr/local/bin/kandji display-alert --title 'ERROR!' --message 'We had an issue assigning this computer to the'$device_blueprint_name' blueprint. Please contact IT for additional support.' --no-wait
      fi
    exit 1
    else
    LOGGING "CONFIRMED! Device is now assigned to blueprint: $device_blueprint_name ($device_blueprint)"
      if [[ $notifyUsers == true ]]; then
      /usr/local/bin/kandji display-alert --title 'BLUEPRINT CHANGED!' --message 'This computer is now assigned to the '$device_blueprint_name' blueprint.' --no-wait
      fi
    exit 0
  fi
}

################################################################
#  THE NEEDFUL
################################################################

# Check Serial number
if [[ -z "$serialnum" ]]; then
  LOGGING "Had an issue pulling device serial number ..."
  exit 1
else
  LOGGING "Device Serial Number: $serialnum"
fi

# API Call to fetch device info for given serial number.
LOGGING "Fetching device record..."
api_device_record

# Error check to make sure we received device record from API call..
if [[ -z "$device_record" ]] || [[ "$device_record" == "[]" ]]; then
  LOGGING "--- Had an issue pulling device record from Kandji. Exiting..."
    if [[ $notifyUsers == true ]]; then
    /usr/local/bin/kandji display-alert --title 'ERROR!' --message 'We had an issue assigning this computer to the'$device_blueprint_name' blueprint. Please contact IT for additional support.' --no-wait
    fi
  exit 1
  else
  LOGGING "--- Device record found!"
fi

# Fetch UUID of currently assigned blueprint from device record.
get_device_blueprint_value

# Check if blueprint value entered by admin is a UUID or blueprint name.
blueprint_value_validator

# Fetch blueprint id if provided 'assignBlueprint' value is a name.
if [[ $bpvalue != "UUID" ]]; then
  LOGGING "Given blueprint value is a name, looking up the Blueprint UUID..."
  api_blueprint_record
  LOGGING "Parsing Blueprint ID..."
  get_blueprint_id_value
  LOGGING "--- Found Blueprint ID for $assignBlueprint: $blueprint_id"
  assignBlueprint=$blueprint_id
else
  LOGGING "--- A Blueprint UUID ($assignBlueprint) has been provided....."
  LOGGING "Validating provided UUID..."
  api_blueprint_uuid_record
  LOGGING "Setting Blueprint ID value from given value.."
  blueprint_id=$assignBlueprint
fi

# Check if device is already assigned to the provided blueprint
if [[ "$device_blueprint" == "$assignBlueprint" ]]; then
  LOGGING "Device is already assigned to blueprint $device_blueprint_name ($device_blueprint)!  Exiting..."
    if [[ $notifyUsers == true ]]; then
    /usr/local/bin/kandji display-alert --title 'Already Assigned' --message 'This computer is already assigned to the '$device_blueprint_name' blueprint.' --no-wait
    fi
  exit 0
else
  LOGGING "--- Device is currently assigned to blueprint: $device_blueprint_name ($device_blueprint). Switching to new blueprint..."
fi

# Get Device Info for serial number and parse device_id
LOGGING "Fetching device id for $serialnum..."
get_device_id_value
LOGGING "--- Found device id: $device_id"

# Change the assigned blueprint
move_to_blueprint
sleep 4

# Check to see if device blueprint assignment was successful.
LOGGING "--- Double-checking device record..."
blueprint_validator

exit 0
