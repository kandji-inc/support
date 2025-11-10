#!/bin/zsh

################################################################################################
# Created by Jan Rosenfeld | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 2023.05.22
#   Updated - 2025.11.07
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
#   This script will prompt an end user to input an email address, then search the Kandji user
#   directory for that email. If found, it will update the assigned user on the device record.
#
#   This script is intended to be used in Kandji Self Service
#   If not already installed, the script will install JQ in order to parse JSON data
#
#   For details, see https://github.com/kandji-inc/support/tree/main/Scripts/assign-user-prompt
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2025 Kandji, Inc.
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

# Script Version
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
logging() {
    script_id="assign_user_prompt"
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
        if ! /usr/bin/command -v jq &>/dev/null; then
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
                cd /Library/KandjiSE/
                /usr/bin/curl -LOs --url "https://github.com/kandji-inc/support/raw/main/UniversalJQ/JQ-1.8.1-UNIVERSAL.pkg.tar.gz"
                /usr/bin/tar -xf JQ-1.8.1-UNIVERSAL.pkg.tar.gz
                /usr/sbin/installer -pkg JQ-1.8.1-UNIVERSAL.pkg -target / >/dev/null
                jq_binary="/Library/KandjiSE/jq"
            fi

            # Verify jq is available now
            if ! /usr/bin/command -v "${jq_binary}" &>/dev/null; then
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
        if [[ "${kandji_jq_install}" == "true" ]]; then
            logging "INFO" "Removing Kandji jq files."
            if [[ $(/bin/ls /Library/KandjiSE | /usr/bin/wc -l) == "       3" ]]; then
                /bin/rm -rf /Library/KandjiSE
            else
                /bin/rm /Library/KandjiSE/jq
                /bin/rm /Library/KandjiSE/JQ-1.8.1-UNIVERSAL.pkg.tar.gz
                /bin/rm /Library/KandjiSE/JQ-1.8.1-UNIVERSAL.pkg
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

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

# Set language environment variable
# This is not set in the shell session Kandji scripts run in.
# A value is needed to correctly parse characters with diacritical marks.
export LANG=en_US.UTF-8

# Content Type
CONTENT_TYPE="application/json"

# Kandji API base URL
if [[ -z ${REGION} || ${REGION} == "us" ]]; then
    BASE_URL="https://${SUBDOMAIN}.api.kandji.io/api"
elif [[ ${REGION} == "eu" ]]; then
    BASE_URL="https://${SUBDOMAIN}.api.${REGION}.kandji.io/api"
else
    logging "ERROR" "Unsupported region: ${REGION}. Please update and try again."
    exit 1
fi

KANDJI_ICON="/Applications/Kandji Self Service.app/Contents/Resources/AppIcon.icns"
# If Kandji icon not found, use Finder icon
if [[ ! -f "${KANDJI_ICON}" ]]; then
    KANDJI_ICON="/System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns"
fi

# Get the device serial number
SERIAL_NUMBER=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | /usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

################################################################################################
############################## MAIN LOGIC - DO NOT MODIFY BELOW ################################
################################################################################################

################################################
## Run initial checks                         ##
################################################

# Verify we have a serial number
if [[ -z "${SERIAL_NUMBER}" ]]; then
    logging "ERROR" "Could not determine device serial number ..."
    /usr/bin/osascript -e 'display dialog "There was an issue finding the serial number of your computer. Your administrator will be notified that assignment was not successful." with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons ("OK") giving up after 180' 2>/dev/null
    exit 1
fi

# Check and install jq if needed
check_jq "install"

################################################
## Get the device details and find            ##
## if a user is already assigned              ##
################################################

# Search for device by serial number
device_record=$(/usr/bin/curl --silent --request GET --url "${BASE_URL}/v1/devices/?serial_number=${SERIAL_NUMBER}" \
    --header "Authorization: Bearer ${TOKEN}")

if [[ "${device_record}" == "[]" ]]; then
    logging "ERROR" "Device info was not found for serial number: ${SERIALNUMBER}."
    logging "ERROR" "Exiting..."
    exit 1
fi

assigned_user=$(echo "${device_record}" | "${jq_binary}" -r '.[0].user // empty')

if [[ -z "${assigned_user}" ]]; then
    logging "INFO" "No user currently assigned to computer. Proceeding..."
else
    logging "INFO" "There is already a user assigned to this computer. Nothing to do!"
    exit 0
fi

################################################
## Get the users email address and            ##
## check if it exists in the Kandji directory ##
################################################

# Present a dialog to the user up to three times to enter their email address.
user_response=$(/usr/bin/osascript -e 'display dialog "Your computer needs to be assigned to you in Kandji. Please enter your email address:" default answer "you@company.com" with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons {"Cancel", "Submit"} default button "Submit"' 2>/dev/null)

attempt_counter=0
max_attempts=3
email_valid=false

while [[ ${attempt_counter} -lt ${max_attempts} ]] && [[ ${email_valid} == false ]]; do

    # Check if user pressed Cancel
    if [[ -z "${user_response}" ]]; then
        logging "ERROR" "User canceled the dialog. No email address submitted..."
        logging "ERROR" "Exiting."
        exit 1
    fi

    # Parse email address entered by the end user
    user_email_input=$(echo "${user_response}" | /usr/bin/awk -F ":" '{print $NF}')

    # Modify user input to be lowercase
    user_email="${user_email_input:l}"

    # Validate the user entered an email address
    valid_email="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if [[ "${user_email}" =~ ${valid_email} ]]; then
        logging "INFO" "User entered a valid email address. Proceeding..."
        logging "INFO" "The user entered ${user_email}"
        email_valid=true
    else
        logging "ERROR" "A valid email address was not entered."
        logging "ERROR" "User entered ${user_email_input}"
        attempt_counter=$((attempt_counter + 1))
        if [[ $attempt_counter -lt $max_attempts ]]; then
            logging "INFO" "Attempting again... Attempt ${attempt_counter} of ${max_attempts}."
            user_response=$(/usr/bin/osascript -e 'display dialog "A valid email address was not entered. Please enter your email address:" default answer "you@company.com" with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons {"Cancel", "Submit"} default button "Submit"' 2>/dev/null)
        else
            logging "ERROR" "Maximum attempts reached. Exiting."
            exit 1
        fi
    fi
done

# Make the API call to get the user ID
user_response=$(/usr/bin/curl --silent --location --url "${BASE_URL}/v1/users?email=${user_email}&integration_id=${INTEGRATION_ID}" \
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
    logging "ERROR" "No Kandji users returned for ${user_email}. Please check your directory and try again."
    /usr/bin/osascript -e 'display dialog "An error has occured. Your administrator will be notified that assignment was not successful." with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons ("OK") giving up after 180' 2>/dev/null
    exit 1
elif [[ "${result_count}" -gt 1 ]]; then
    /usr/bin/osascript -e 'display dialog "An error has occured. Your administrator will be notified that assignment was not successful." with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons ("OK") giving up after 180' 2>/dev/null
    exit 1
fi

# Parse the response for the user ID (and generate user_id variable)
user_id=$(echo "${user_response}" | "${jq_binary}" -r '.results[0].id')
logging "INFO" "Found User ID of ${user_id} for ${user_email}"

################################################
## Get the Device ID and Assign the           ##
## computer to the user in Kandji             ##
################################################

# Parse device_record and extract device ID using jq
device_id=$(echo "${device_record}" | ${jq_binary} -r '.[0].device_id')

# Print the device ID
logging "INFO" "Device ID: ${device_id}"

# Update Device Record in Kandji
update_device_response=$(/usr/bin/curl --silent --request PATCH --url "${BASE_URL}/v1/devices/${device_id}" \
    --header "Authorization: Bearer ${TOKEN}" \
    --header "Content-Type: ${CONTENT_TYPE}" \
    --data "{\"user\": \"${user_id}\"}")

if [[ "$update_device_response" == "400" ]]; then
    logging "ERROR" "Bad request code ${update_device_response} ..."
    /usr/bin/osascript -e 'display dialog "There was an issue assigning your computer in Kandji. Your administrator will be notified that assignment was not successful." with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons ("OK") giving up after 180' 2>/dev/null
    exit 1
fi

# Print response and alert the end user
logging "INFO" "The device has been updated with a new assigned user."
/usr/bin/osascript -e 'display dialog "Thank you! Your computer has been assigned to you in Kandji." with title "Computer Assignment" with icon POSIX file "'"${KANDJI_ICON}"'" buttons ("OK") giving up after 180' 2>/dev/null

check_jq "remove"

exit 0
