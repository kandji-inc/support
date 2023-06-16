#!/usr/bin/env zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created on 2022-11-28
# Updated on 2023-06-16
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.4
#
################################################################################################
# Software Information
################################################################################################
#
#   API pagination example using limit and offset in zshell.
#
#   DESCRIPTION
#
#       This script uses a combination of the limit and offset parameters to
#       demonstrate the use of pagination to control the number of records returned per
#       API call and how to call the next batch of device records until all device
#       records are returned.
#
#       param: limit
#
#       The limit parameter controls the maximum number of items that may be returned
#       for a single request. This parameter can be thought of as the page size. If no
#       limit is specified, the functionault limit is set to 300 records per request.
#
#       param: offset
#
#       The offset parameter controls the starting point within the collection of
#       resource results. For example, if you have a total of 35 device records in your
#       Kandji instance and you specify limit=10, you can retrieve the entire set of
#       results in 3 successive requests by varying the offset value: offset=0,
#       offset=10, and offset=20. Note that the first item in the collection is
#       retrieved by setting a zero offset.
#
#   RESOURCES
#
#       In very simple terms, pagination is the act of splitting large amounts of data
#       into multiple smaller pieces. For example, whenever you go to the questions
#       page in Stack Overflow, you see something like this at the bottom
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

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Kandji tenant subdomain
SUBDOMAIN="accuhive" # accuhive

# tenant region
REGION="" # us, eu

# Kandji Bearer Token
TOKEN=""

########################################################################################
###################################### FUNCTIONS #######################################
########################################################################################

function install_jq() {
    # Download and install jq

    # univeral install hosted by Kandji
    universal_jq_release="https://github.com/kandji-inc/support/raw/main/UniversalJQ/JQ-1.6-UNIVERSAL.pkg.tar.gz"

    # jq temp download location
    jq_tmp="/private/tmp/jq.tar.gz"

    # installed binary
    installed_jq="/Library/KandjiSE/jq"

    jq_bin="/usr/local/bin/jq"

    /usr/bin/curl -L "${universal_jq_release}" -o "${jq_tmp}"

    # Expand our tarball into tmp
    /usr/bin/tar -xf "${jq_tmp}" -C /private/tmp

    # Locate our extracted JQ package and install it
    /usr/bin/find -L /private/tmp -iname "jq*pkg" -exec sudo /usr/sbin/installer \
        -pkg {} -target / \;

    sudo /bin/mkdir -p "/usr/local/bin"
    sudo /bin/mv "${installed_jq}" "${jq_bin}"
    sudo /bin/chmod a+x "${jq_bin}"
}

function get_devices() {
    # Return device inventory
    #
    # This function will call the /devices endpoint and return a JSON object containing
    # all records. If pagination is needed to return all records, limit and offset are
    # used to get all pages.
    # limit - set the number of records to return per API call
    limit=300
    # offset - set the starting point within a list of resources
    offset=0

    count=0

    # declare array to hold device records returned
    declare -a data

    data=()

    # loop until no device records are returned in the response.
    while True; do
        # return device inventory using limit and offset ordered by serial_number
        response=$(/usr/bin/curl --silent --request GET \
            --url "${BASE_URL}/v1/devices?limit=${limit}&offset=${offset}&ordering=serial_number" \
            --header "Authorization: Bearer ${TOKEN}" \
            --header "Content-Type: ${CONTENT_TYPE}")

        # update offset so that we know which records/page to get next
        offset=$((offset + limit))

        ((count++))

        # check to see if the response is empty meaning that no devices were returned
        # for the specified tenant.
        if [[ $(echo "${response}" | ${jq_path} '. | length') == "0" ]]; then
            # make sure that devices were returned from kandji
            if [[ "$count" = 1 && $(echo "${response}" | ${jq_path} '. | length') == "0" ]]; then
                /bin/echo "No devices found in the ${SUBDOMAIN} tenant..."
                exit 0
            fi
            break
        fi

        # base64 ecode the response and append to the data array
        for record in $(echo $response | ${jq_path} -r '.[] | @base64'); do
            # shellcheck disable=SC2206
            data+=(${record})
        done
    done

    # shellcheck disable=SC2128
    /bin/echo ${data}
}

########################################################################################
###################################### MAIN LOGIC ######################################
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

# look for jq
jq_path="$(/usr/bin/find /usr/local/bin /bin /opt/homebrew -maxdepth 3 \
    -name jq 2>/dev/null)"

if [[ -z $jq_path ]]; then
    /bin/echo "Did not find jq in PATH. Attempting to install..."
    install_jq

    # set jq path
    jq_path="$(/usr/bin/find /usr/local/bin /bin /opt/homebrew -maxdepth 3 \
        -name jq 2>/dev/null)"
    /bin/echo "jq installed at $jq_path."

else
    /bin/echo "jq path found at $jq_path"
fi

/bin/echo ""
/bin/echo "Base URL: ${BASE_URL}"
/bin/echo ""

# Get the total number of devices
/bin/echo "Getting device inventory from Kandji..."

# device_ids=($(get_devices))
device_inventory=($(get_devices))

echo "Total device records returned: ${#device_inventory[@]}"

#
# device_id
#

echo ""
echo "Getting device ids..."
echo ""

# store device uuids in an array called device_ids
declare -a device_ids
device_ids=()

# loop over device inventory to pull out device_id
for record in "${device_inventory[@]}"; do
    device_ids+=($(/bin/echo ${record} | base64 --decode | ${jq_path} -r '.device_id'))
done

# print each device id
for device_id in "${device_ids[@]}"; do
    echo "$device_id"
done

#
# device_name
#

echo ""
echo "Getting device names..."
echo ""

# store device serial_number in an array called device_names
local -a device_names
device_names=()

# loop over device inventory to pull out device_id
for record in "${device_inventory[@]}"; do
    device_names+=($(/bin/echo ${record} | base64 --decode | ${jq_path} -r '.device_name'))
done

# print each device id
for device_name in "${device_names[@]}"; do
    echo "$device_name"
done

#
# serial_number
#

echo ""
echo "Getting device serial numbers..."
echo ""

# store device serial_numbers in an array called serial_numbers
local -a serial_numbers
serial_numbers=()

# loop over device inventory to pull out device_id
for record in "${device_inventory[@]}"; do
    serial_numbers+=($(/bin/echo ${record} | base64 --decode |
        ${jq_path} -r '.serial_number'))
done

# print each device id
for serial_number in "${serial_numbers[@]}"; do
    echo "$serial_number"
done
