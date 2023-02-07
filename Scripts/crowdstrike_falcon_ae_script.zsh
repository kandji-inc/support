#!/bin/zsh

################################################################################################
# Created by David Larrea & Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2021-08-26
# Updated - 2022-02-23
# Updated - 2022-11-28 - Matt Wilson
# Updated - 2023-01-25 - Matt Wilson
# Updated - 2023-02-03 - Matt Wilson
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.2
#   12.6.1
#   11.7.1
#
################################################################################################
# Software Information
################################################################################################
#
# This Audit and Enforce script is used to ensure that a specific Crowdstrike
# configuration profile is installed and ensure that Crowdstrike is running properly
# after installation.
#
# Configuration profiles are included with the Crowdstrike deployment instructions
# found in the Kandji Knowledge Base.
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

# This is the profile ID that contains all settings.
# This prefix exists in the KEXT and kextless version of the settings profile
PAYLOAD_ID_PREFIX="io.kandji.crowdstrike.2C5CBFD0"

# Service management profile prefix
# NOTE: this profile only contains managed backgroud settings for macOS 13+
# Change the SERVICE_MANAGEMENT_PREFIX variable to the profile prefix you want to wait
# on before running the installer.
SERVICE_MANAGEMENT_PREFIX="io.kandji.crowdstrike.service-management"

# App info
APP_NAME="Falcon.app"
PROCESS_LABEL="com.crowdstrike.falcon.Agent"

########################################################################################
##################################### FUNCTIONS ########################################
########################################################################################

profile_search() {
    # Look for a profile
    # $1 - payload payload uuid
    /usr/bin/profiles show | grep "$1" | sed 's/.*\ //'
}

system_extension_status() {
    # Return system ext status
    # $1 - system extension label
    /usr/bin/systemextensionsctl list | /usr/bin/grep "$1" |
        /usr/bin/awk '{print $7" "$8}' | /usr/bin/grep "activated" |
        /usr/bin/sed -e 's/\[//g' -e 's/\]//g'
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

    /bin/echo "$response"
}

########################################################################################
###################################### MAIN LOGIC ######################################
########################################################################################

# All of the main logic be here ... modify at your own risk.

# Look for profile without KEXT payload
# The profiles_list variable will be set to an array of profiles that match the prefix
# in the PAYLOAD_ID_PREFIX variable
profiles_list=$(profile_search "$PAYLOAD_ID_PREFIX")

# Check to see if the profile ID prefix defined in $PAYLOAD_ID_PREFIX or
# $KEXT_PAYLOAD_ID_PREFIXis installed. If both lists are empty, exit 0 to wait for the
# next agent run.
if [[ ${#profiles_list[@]} -eq 0 ]]; then
    /bin/echo "Settings profile not found ..."
    /bin/echo "Waiting until the profile is installed before proceeding ..."
    /bin/echo "Will check again at the next Kandji agent check-in ..."
    exit 0
fi

/bin/echo "$APP_NAME Settings profile with prefix ($PAYLOAD_ID_PREFIX) is installed ..."

# macOS Version
osvers_major="$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F '.' '{print $1}')"

# macOS Ventura(13.0) or newer - this is for the managed background settings profile.
if [[ "${osvers_major}" -ge 13 ]]; then
    # The profiles variable will be set to an array of profiles that match the prefix in
    # the SERVICE_MANAGEMENT_PREFIX variable
    profiles=$(profile_search "$SERVICE_MANAGEMENT_PREFIX")

    # If matching profiles are found exit 1 so the installer will run, else exit 0 to
    # wait
    if [[ ${#profiles[@]} -eq 0 ]]; then
        /bin/echo "No profiles with ID $SERVICE_MANAGEMENT_PREFIX were found ..."
        /bin/echo "Will check again at the next Kandji agent check in before moving on ..."
        exit 0
    fi

    /bin/echo "Profile prefix $SERVICE_MANAGEMENT_PREFIX present ..."
fi

# This command looks in /Applications, /System/Applications, and /Library for the
# existance of the app defined in $APP_NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name $APP_NAME 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e $installed_path ]] || [[ $APP_NAME != "$(/usr/bin/basename "$installed_path")" ]]; then
    /bin/echo "$APP_NAME not installed. Starting installation process ..."
    exit 1

else
    # Get the installed app version
    installed_version=$(/usr/bin/defaults read "$installed_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    # make sure we got a version number back
    if [[ -n "$installed_version" ]]; then
        /bin/echo "$APP_NAME version $installed_version is installed at \"$installed_path\"..."
    else
        /bin/echo "$APP_NAME is installed at \"$installed_path\"..."
    fi
fi

# Get status of the CS KEXT
cs_kext_stat=$(sysctl cs 2>&1)

if [[ "$cs_kext_stat" == "sysctl: unknown oid 'cs'" ]]; then
    /bin/echo "Crowdstrike KEXT is not running ... checking for newer process"
else
    /bin/echo "Crowdstrike KEXT is running ..."
    /bin/echo "No action needed ..."
    exit 0
fi

# Get the falcon PID
falcon_process_id=""
loop_counter=0

# Loop until the falcon pid is found or we have checked the status 5 times
while [[ "$falcon_process_id" == "" ]] && [[ "$loop_counter" -lt 6 ]]; do

    # Get the falcon PID
    falcon_process_id="$(/usr/bin/pgrep $PROCESS_LABEL)"

    # Get the CS SysEXT status
    cs_sysext_status="$(system_extension_status $PROCESS_LABEL)"

    # If no PID is returned and the system ext is not activated and enabled, try to
    # reload the falcon process and check to the status of the system ext again.
    if [[ -z "$falcon_process_id" ]] && [[ $cs_sysext_status != "activated enabled" ]]; then

        /bin/echo "Falcon agent not running ..."
        /bin/echo "Attempting to reload falcon ..."

        # call the load_falcon_agent function
        ret="$(load_falcon_agent)"

        # Check to see if the falcon agent loaded successfully
        if [[ "$ret" == "Falcon sensor is loaded" ]]; then
            /bin/echo "Falcon agent loaded successfully ..."

            # Get the CS SysEXT status
            cs_sysext_status="$(system_extension_status $PROCESS_LABEL)"

            # Check to see if the CS System Extension is activated and enabled.
            if [[ $cs_sysext_status == "activated enabled" ]]; then
                /bin/echo "Crowdstrike System Extension is $cs_sysext_status ..."
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
        /bin/echo "Falcon System Extension is $cs_sysext_status ..."
        /bin/echo "Falcon agent($falcon_process_id) is running ..."
    fi
done

# Everything checks out
/bin/echo "Crowdstrike Falcon appears to be running properly ..."
/bin/echo "Nothing to do ..."

exit 0
