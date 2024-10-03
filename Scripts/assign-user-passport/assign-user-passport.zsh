#!/bin/zsh

################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 2023/07/13
#   Updated - 2024/09/30
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - 15
#    -14.7
#   - 13.6.7
#
################################################################################################
# Software Information
################################################################################################
#
# This script is designed to automatically look for the IdP user who signed in with Passport and 
# assign that user to the device record in Kandji. 
#
# By default, the script searches across all user directory integrations. To limit the search to
# a specific integration, please set the INTEGRATION_ID variable.
#
# For details, see https://github.com/kandji-inc/support/tree/main/Scripts/assign-user-passport
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

# Script version
VERSION="2.0.0"

################################################################################################
###################################### USER INPUT ##############################################
################################################################################################

# Set your Kandji subdomain (example: for "beekeepr.kandji.io", enter "beekeepr")
SUBDOMAIN="subdomain"

# Set your region (example: "us" or "eu")
REGION="us"

# Kandji Enterprise API token
# Requires the following permissions: List Users, Update a device, and Device List
TOKEN="Kandji API Token Here"

# User Directory Integration UUID (leave blank to search all integrations)
INTEGRATION_ID=""

################################################################################################
########################### FUNCTIONS - DO NOT MODIFY BELOW ####################################
################################################################################################

# Set logging - Send logs to stdout as well as Unified Log
# Usage: logging "LEVEL" "Message..."
# Use 'log show --process "logger"'to view logs activity.
logging(){
  script_id="assign_user_passport"
  timestamp=$(/bin/date +"%m-%d-%Y %H:%M:%S")
  
  echo "${timestamp} ${1}: ${2}"
  /usr/bin/logger "${script_id}: [${1}] ${2}"
}

# Check if jq is installed. If not found will install Kandji provided jq
# Usage: check_jq "CHECK_TYPE"
# CHECK_TYPE should be either "install" or "remove"
check_jq() {
  
  local check_type="${1}"
  
  if [[ "${check_type}" == "install" ]]; then
    if ! /usr/bin/command -v jq &> /dev/null; then
      logging "INFO" "jq is not installed. Installing Kandji provided jq..."
      
      # Create KandjiSE directory if needed
      if [[ ! -d "/Library/KandjiSE" ]]; then
        /bin/mkdir "/Library/KandjiSE"
      fi  
      
      if [[ -f "/Library/KandjiSE/jq" ]]; then
        logging "INFO" "Kandji jq already installed..."
        jq_binary="/Library/KandjiSE/jq"
      else
        # Install Kandji provided jq
        cd /Library/KandjiSE/ || exit 
        /usr/bin/curl -LOs --url "https://github.com/kandji-inc/support/raw/main/UniversalJQ/JQ-1.7-UNIVERSAL.pkg.tar.gz"
        /usr/bin/tar -xf JQ-1.7-UNIVERSAL.pkg.tar.gz
        /usr/sbin/installer -pkg JQ-1.7-UNIVERSAL.pkg -target / > /dev/null
        jq_binary="/Library/KandjiSE/jq"
      fi
      
      # Verify jq is available now
      if ! /usr/bin/command -v "${jq_binary}" &> /dev/null; then
        logging "ERROR" "Unable to find jq after installing..."
        logging "ERROR" "Exiting."
        exit 1
      fi
      
      # Set flag for Kandji jq uninstall
      kandji_jq_install="true"
    else
      logging "INFO" "jq is already installed."
      jq_binary=$(/usr/bin/which jq)
    fi
  elif [[ "${check_type}" == "remove" ]]; then
    # Check if Kandji installed jq was used
    if [[ "${kandji_jq_install}" == "true" ]] ; then
      logging "INFO" "Removing Kandji jq files."
      if [[ $(/bin/ls /Library/KandjiSE | /usr/bin/wc -l) == "       3" ]]; then
      /bin/rm -rf /Library/KandjiSE
      else
      /bin/rm /Library/KandjiSE/jq
      /bin/rm /Library/KandjiSE/JQ-1.7-UNIVERSAL.pkg.tar.gz
      /bin/rm /Library/KandjiSE/JQ-1.7-UNIVERSAL.pkg
      fi
    else
      logging "INFO" "Kandji provided jq was not used. Nothing to do..."
    fi
  else
    logging "ERROR" "Invalid check_type value specified..."
    logging "Exiting."
    exit 1
  fi
}

# Check for logged in user
current_user(){
  # Get the current logged in or most common user of the system
  local_account=$(/usr/bin/stat -f%Su /dev/console)
  # If root, no console session
  # Find most common user by console time and assign
  if [[ "${local_account}" == "root" ]]; then
    local_account=$(/usr/sbin/ac -p | \
      /usr/bin/sort -nk 2 | \
      /usr/bin/grep -E -v "total|root|mbsetup|adobe" | \
      /usr/bin/tail -1 | \
      /usr/bin/xargs | \
      /usr/bin/cut -d " " -f1)
    logging "INFO" "No console user found...Assuming ${local_account} from total logged in time"
  fi
 }

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# Set language environment variable
# This is not set in the shell session Kandji scripts run in.
# A value is needed to correctly parse characters with diacritical marks.
export LANG=en_US.UTF-8

# Get the device serial number
SERIAL_NUMBER=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

# Content Type
CONTENT_TYPE="application/json"

# Kandji API base URL
if [[ -z $REGION || $REGION == "us" ]]; then
  BASE_URL="https://${SUBDOMAIN}.api.kandji.io/api"
elif [[ $REGION == "eu" ]]; then
  BASE_URL="https://${SUBDOMAIN}.api.${REGION}.kandji.io/api"
else
  /bin/echo "Unsupported region: $REGION. Please update and try again."
  exit 1
fi

################################################################################################
############################## MAIN LOGIC - DO NOT MODIFY BELOW ################################
################################################################################################


# Check and install jq if needed
check_jq "install"

# Check for logged in or most active user
current_user

################################################
## Get the users email address from Passport  ##
################################################
passport_linked_account_name=$(/usr/bin/dscl . -read /Users/"${local_account}" "io.kandji.KandjiLogin.LinkedAccountName" 2>&1)

if [[ "${passport_linked_account_name}" == *"No such key"* ]]; then
  logging "ERROR" "Account ${local_account} does not appear to be managed by Passport..."
  logging "ERROR" "Exiting."
  exit 1
else
  passport_email_raw=$(echo "${passport_linked_account_name}" | /usr/bin/awk '{print $2}')
  # Make sure the email address is all lower case
  passport_email="${passport_email_raw:l}"
  logging "INFO" "Account '${local_account}' appears to be managed by Passport..."
  logging "INFO" "${local_account}'s e-mail address is ${passport_email}. Proceeding..."
fi

################################################
## Get the device details and check if the    ##
## user is already assigned to the device.    ##
################################################

# Search for device by serial number
device_record=$(/usr/bin/curl --silent --request GET --url "${BASE_URL}/v1/devices/?serial_number=${SERIAL_NUMBER}" \
--header "Authorization: Bearer ${TOKEN}")

if [[ "${device_record}" == "[]" ]]; then
  logging "ERROR" "Device info was not found for serial number: ${SERIAL_NUMBER}."
  logging "ERROR" "Exiting..."
  exit 1
fi

assigned_user=$(echo "${device_record}" | "${jq_binary}" -r '.[0].user.email' 2>/dev/null)

if [[ -z "${assigned_user}" ]]; then
  logging "INFO" "No user assigned. Will attempt to assign ${passport_email} to the device..."
elif [[ "${assigned_user}" == "${passport_email}" ]]; then
  logging "INFO" "${passport_email} is already the assigned user. Nothing to do!"
  exit 0
else
  logging "INFO" "${assigned_user} is currently assigned. Will attempt to assign ${passport_email} to the device..."
fi

################################################
## Find the user in the Kandji user directory ##
################################################

# Make the API call to get the user ID
user_response=$(/usr/bin/curl --fail-with-body --silent --location --url "${BASE_URL}/v1/users?email=${passport_email}&integration_id=${INTEGRATION_ID}" \
--header "Authorization: Bearer ${TOKEN}")

# Check if curl command was successful
if [[ $? -ne 0 ]]; then
  logging "ERROR" "Failed to make the API call to get the user ID."
  exit 1
fi

# Extract the number of results
result_count=$(echo "${user_response}" | "${jq_binary}" '.results | length')

# Make sure that we only received 1 result
if [[ "${result_count}" -eq 0 ]]; then
  logging "ERROR" "No Kandji users returned for ${passport_email}. Please check your directory and try again."
  exit 1
elif [[ "${result_count}" -gt 1 ]]; then
  logging "ERROR" "Multiple Kandji users returned for ${passport_email}. Please check your directory or include an Integration ID to limit the search and try again."
  exit 1
fi

# Parse the response for the user ID (and generate user_id variable)
user_id=$(echo "${user_response}" | "${jq_binary}" -r '.results[0].id')
logging "INFO" "Found User ID of ${user_id} for ${passport_email}"

################################################
## Assign the user to the device record       ##
################################################

# Parse device_record and extract device ID
device_id=$(echo "${device_record}" | "${jq_binary}" -r '.[0].device_id')

# Print the device ID
logging "INFO" "Device ID: ${device_id}"

# Update Device Record in Kandji
update_device_response=$(/usr/bin/curl --silent --request PATCH --url "${BASE_URL}/v1/devices/${device_id}" \
--header "Authorization: Bearer ${TOKEN}" \
--header "Content-Type: ${CONTENT_TYPE}" \
--data "{\"user\": \"${user_id}\"}")


if [[ "${update_device_response}" == "400" ]]; then
    logging "ERROR" "Bad request code ${update_device_response} ..."
    exit 1
else
    logging "INFO" "User has been successfully assigned to the device record."
fi

# Clean up Kandji jq if used
check_jq "remove"

exit 0