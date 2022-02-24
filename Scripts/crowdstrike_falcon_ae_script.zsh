#!/bin/zsh

###################################################################################################
# Created by David Larrea & Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
# Created - 2021-08-26
# Updated - 2022-02-23
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.2
#   11.6.2
#
###################################################################################################
# Software Information
###################################################################################################
#
# This Audit and Enforce script is used to ensure that a specific Crowdstrike configuration
# profile is installed and ensure that Crowdstrike is running properly after installation.
#
# Configuration profiles are included with the Crowdstrike deployment instructions found in the
# Kandji Knowledge Base.
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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

# Script version
VERSION="2.1.2"

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

# Change the PROFILE_PAYLOAD_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. If the profile is not found, this audit and enforce script will exit 0
# and do nothing until the next Kandji agent check-in.

# This is the profile ID that contains alls settings excluding the KEXT.
# Use this profile if not leveraging the crowdstrike firmware analysis tools or for Apple Silicon
# Mac computers that are manually enrolled into Kandji.
PROFILE_PAYLOAD_ID_PREFIX="io.kandji.crowdstrike.2C5CBFD0-7CFE"

# This is the profile ID that contains all settings including KEXT and SysEXT
# This can be used for all macOS devices (Intel or M1(Apple Silicon) that are enrolled in ABM and
# managed via Kandji. If you want to use this profile with manually enrolled Apple Silicon devices
# end-users will need to manually lower security on their Mac before the profile will be allowed
# to install. https://support.apple.com/guide/deployment-reference-macos/kernel-extensions-in-macos-apd37565d329/web
KEXT_PROFILE_PAYLOAD_ID_PREFIX="io.kandji.crowdstrike.2C5CBFD0-8CFE"

# App Name
APP_NAME="Falcon.app"

###################################################################################################
##################################### FUNCTIONS ###################################################
###################################################################################################

return_installed_app_version() {
    # Return the currently installed application version
    local path="$1"
    local inst_vers=""

    inst_vers=$(/usr/bin/defaults read "$path/Contents/Info.plist" CFBundleShortVersionString)

    if [[ "$?" -ne 0 ]]; then
        #statements
        inst_vers="None"
    fi

    echo "$inst_vers"
}

load_falcon_agent() {
    # Load falcon

    if [[ -e "/Library/CS/falconctl" ]]; then
        # old falconctl location
        response="$(/Library/CS/falconctl load)"
    else
        # Versions 6.11+
        response="$(/Applications/Falcon.app/Contents/Resources/falconctl load)"
    fi

    echo "$response"
}

###################################################################################################
##################################### MAIN LOGIC ##################################################
###################################################################################################

# All of the main logic be here ... modify at your own risk.

# The profiles_list variable will be set to an array of profiles that match the prefix in
# the PROFILE_PAYLOAD_ID_PREFIX variable

# Look for profile with KEXT payload
profiles_list_kext=$(/usr/bin/profiles show | grep "$KEXT_PROFILE_PAYLOAD_ID_PREFIX" | sed 's/.*\ //')

# Look for profile without KEXT payload
profiles_list=$(/usr/bin/profiles show | grep "$PROFILE_PAYLOAD_ID_PREFIX" | sed 's/.*\ //')

# Check to see if the profile ID prefix defined in $PROFILE_PAYLOAD_ID_PREFIX or
# $KEXT_PROFILE_PAYLOAD_ID_PREFIXis installed. If both lists are empty, exit 0 to wait for the
# next agent run.
if [[ ${#profiles_list_kext[@]} -eq 0 ]] && [[ ${#profiles_list[@]} -eq 0 ]]; then
    echo "No profiles with ID prefix $PROFILE_PAYLOAD_ID_PREFIX or $KEXT_PROFILE_PAYLOAD_ID_PREFIX(profile with KEXT payload) were found ..."
    echo "Waiting until the profile is installed before proceeding ..."
    echo "Will check again at the next Kandji agent check-in ..."
    exit 0
else
    echo "$APP_NAME Settings profile is installed ..."
fi

# Check to see if the Falcon.app is installed
if [[ ! -e "/Applications/$APP_NAME" ]]; then
    echo "$APP_NAME is not installed ..."
    echo "Starting the installation process ..."
    exit 1
else
    installed_version=$(return_installed_app_version "/Applications/$APP_NAME")
    echo "$APP_NAME version $installed_version is installed ..."
fi

# Get status of the CS KEXT
cs_kext_stat=$(sysctl cs 2>&1)

if [[ "$cs_kext_stat" == "sysctl: unknown oid 'cs'" ]]; then
    echo "Crowdstrike KEXT is not running ... checking for newer process"
else
    echo "Crowdstrike KEXT is running ..."
    echo "No action needed ..."
    exit 0
fi

# Get the falcon PID
falcon_process_id=""
loop_counter=0

# Loop until the falcon pid is found or we have checked the status 5 times
while [[ "$falcon_process_id" == "" ]] && [[ "$loop_counter" -lt 6 ]]; do

    # Get the falcon PID
    falcon_process_id="$(/usr/bin/pgrep com.crowdstrike.falcon.Agent)"

    # Get the CS SysEXT status
    cs_sysext_status="$(/usr/bin/systemextensionsctl list |
        /usr/bin/grep com.crowdstrike.falcon.Agent |
        /usr/bin/awk '{print $7" "$8}' |
        /usr/bin/grep "activated" |
        /usr/bin/sed -e 's/\[//g' -e 's/\]//g')"

    # If no PID is returned and the system ext is not activated and enabled, try to reload the
    # falcon process and check to the status of the system ext again.
    if [[ -z "$falcon_process_id" ]] && [[ $cs_sysext_status != "activated enabled" ]]; then

        echo "Falcon agent not running ..."
        echo "Attempting to reload falcon ..."

        # call the load_falcon_agent function
        ret="$(load_falcon_agent)"

        # Check to see if the falcon agent loaded successfully
        if [[ "$ret" == "Falcon sensor is loaded" ]]; then
            echo "Falcon agent loaded successfully ..."

            # Get the CS SysEXT status
            cs_sysext_status="$(/usr/bin/systemextensionsctl list |
                /usr/bin/grep com.crowdstrike.falcon.Agent |
                /usr/bin/awk '{print $7" "$8}' |
                /usr/bin/grep "activated" |
                /usr/bin/sed -e 's/\[//g' -e 's/\]//g')"

            # Check to see if the CS System Extension is activated and enabled.
            if [[ $cs_sysext_status == "activated enabled" ]]; then
                echo "Crowdstrike System Extension is $cs_sysext_status ..."
            fi

        else
            echo "Failed to load falcon agent ..."
            echo "Will try again ..."

            /bin/sleep 3

            # Increment counter
            ((loop_counter++))

            if [[ "$loop_counter" -gt 5 ]]; then
                echo "Unable to load the agent successfully ..."
                echo "Re installing $APP_NAME"
                exit 1
            fi
        fi
    else
        # Falcon agent is running
        echo "Falcon agent($falcon_process_id) is running ..."
        echo "Falcon System Extension is $cs_sysext_status ..."
    fi
done

# Everything checks out
echo "Crowdstrike Falcon appears to be running properly ..."
echo "Nothing to do ..."

exit 0
