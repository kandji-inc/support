#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 02/11/2022
# Updated on 03/10/2022
# Updated on 04/07/2022
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
# macOS 12: 12.1, 12.2, 12.2.1, 12.3b3
# macOS 11: 11.6.1, 11.6.3, 11.6.4
# macOS 10: 10.14.6, 10.15.7
#
###################################################################################################
# Software Information
###################################################################################################
# 
# Audit script for Privileges Checker add-on. Conducts 11 checks to validate the fidelity of the 
# Launch Agent and enforcement script:
# - Execution script exists (1), has proper permissions (2), and has system immutable flag set (3)
# - Launch Agent exists (4), has proper permissions (5), and has system immutable flag set (6)
# - Agent is alive and returns args of script (7), audit/remediation script versions match (8)
# - Timeout value (if set) matches on-disk (9), profile timeout value (if set) matches on-disk (10)
# - User exclusion list (if defined) matches on-disk (11)
# If any of the above fail, return exit 1 to trigger reinstallation of Privileges Checker.
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

###################################################################################################
####################################### VARIABLES TO MODIFY #######################################
###################################################################################################

# If changing the timeout in minutes within the remediation script, also update the value below
# NOTE: This value must match EXACTLY what is defined for MINUTES_TO_WAIT in the remediation script
# Failure to match these values will cause PC to constantly reinstall from the failed audit
# Audit only evaluates this value if defined (e.g. MINUTES_TO_WAIT=20), otherwise skips the check
MINUTES_TO_WAIT=

# If changing the profile timeout option in the remediation script, also update the value below
# NOTE: This value must match EXACTLY what is defined for USE_PROFILE_TIMEOUT in the remediation script
# Failure to match these values will cause PC to constantly reinstall from the failed audit
# Audit only evaluates this value if defined (e.g. USE_PROFILE_TIMEOUT=True), otherwise skips the check
USE_PROFILE_TIMEOUT=

# If changing the users to exclude within the remediation script, also update the value(s) below
# NOTE: This value must match EXACTLY what is defined for USERS_TO_EXCLUDE in the remediation script
# Failure to match these values will cause PC to constantly reinstall from the failed audit
# Audit only evaluates if defined (e.g. USERS_TO_EXCLUDE=("admin")), otherwise skips the check
USERS_TO_EXCLUDE=(
""
""
""
)

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

#zsh has a built-in operator that can actually do float compares; just gotta load it
autoload is-at-least

#Version for both audit + remediation scripts 
version=1.0.6

############################
##########FUNCTIONS#########
############################

###############################################
## Logs to stdout as well as Unified Log
## Arguments:
##   Takes one arg, "${1}"
## Outputs:
##   Writes to stdout and Unified log
###############################################
function LOGGING {
    /bin/echo "${1}"
    /usr/bin/logger "Privileges Checker Audit: ${1}"
}

##############################################
## Validates that ${2} is greater than or equal
## to ${1}; used for version validation of
## this audit script and execution code
## Arguments:
##   Takes two args "${1}", "${2}", both floats
## Returns:
##   0 if version is compliant, 1 if not 
###############################################
function vers_check() {
    # is-at-least is a zsh built-in for float math
    # returns exit 0 for true, exit 1 for false
    is-at-least "${1}" "${2}" 
    /bin/echo $?
}

############################
##########VARIABLES#########
############################

#Define paths to Launch Agent and execution script
agent_path="/Library/LaunchAgents/io.kandji.privileges-checker.plist"
script_path="/Library/Scripts/MDMHelpers/privilegeschecker.zsh"

#Derive octal permissions of Launch Agent and execution script
agent_permissions=$(/usr/bin/stat -f %A "${agent_path}")
script_permissions=$(/usr/bin/stat -f %A "${script_path}")

#Ensure the system immutable flag is set on both components
agent_immutable=$(/bin/ls -lO "${agent_path}" | /usr/bin/awk '{print $5}')
script_immutable=$(/bin/ls -lO "${script_path}" | /usr/bin/awk '{print $5}')

#Get execution script version
script_version=$(/bin/cat "${script_path}" 2>/dev/null | /usr/bin/grep "version=" | /usr/bin/cut -d '=' -f2)
#Compare current version against on-disk version; capture exit code for success/failure
version_validation=$(vers_check "${version}" "${script_version}")

#Validate console user
console_user=$(/usr/bin/stat -f%Su /dev/console)
#If no user logged in, we can throw away stderr
uid=$(/usr/bin/id -u "${console_user}" 2>/dev/null)

if [[ "${uid}" -lt 501 ]]; then
    #No user logged in, so skip our agent validation
    agent_args="SKIP"
else
    #If we have a console user, validate our script path is present in the args for our launch agent
    agent_args=$(/bin/launchctl print "gui/${uid}/io.kandji.privileges-checker.plist" 2>&1 | sed -e '1,/arguments = {/d' -e '/}/,$d' | grep -o "${script_path}")
fi

#Check if our MINUTES_TO_WAIT var is populated above
if [[ -n ${MINUTES_TO_WAIT} ]]; then
    #If so, grab the current timeout set on-disk
    on_disk_minutes=$(/bin/cat "${script_path}" 2>/dev/null | /usr/bin/grep "MINUTES_TO_WAIT=" | /usr/bin/grep -v "mdm_minutes" | /usr/bin/cut -d '=' -f2)
    #Confirm the values match
    if [[ "${on_disk_minutes}" == "${MINUTES_TO_WAIT}" ]]; then
        timeout_matches=true
    else
        #If they don't, set this to false
        timeout_matches=false
    fi
else
    timeout_matches=true
fi

#Check if our USE_PROFILE_TIMEOUT var is populated above
if [[ -n ${USE_PROFILE_TIMEOUT} ]]; then
    #If so, grab the current profile value set on-disk
    on_disk_profile=$(/bin/cat "${script_path}" 2>/dev/null | /usr/bin/grep "USE_PROFILE_TIMEOUT=" | /usr/bin/cut -d '=' -f2 | /usr/bin/sed 's/"//g')
    #Confirm the values match
    if [[ "${on_disk_profile}" == "${USE_PROFILE_TIMEOUT}" ]]; then
        profile_matches=true
    else
        #If they don't, set this to false
        profile_matches=false
    fi
else
    profile_matches=true
fi

#Collapse our USERS_TO_EXCLUDE array to see if any user exclusion values are defined to check against
if [[ -n $(/bin/echo "${USERS_TO_EXCLUDE}" | xargs) ]]; then
    #If so, grab list of exclusion users defined on-disk
    on_disk_exclusions=($(/bin/cat "${script_path}" 2>/dev/null | /usr/bin/grep "USERS_TO_EXCLUDE" | /usr/bin/head -1 | /usr/bin/sed -e 's/.*(\(.*\)).*/\1/;s/,//g'))
    #Echo the array elements together, remove extraneous spaces, convert remaining spaces into newlines, sort them, and then report on any unmatched values (case-insensitive)
    exclusion_diff=$(/bin/echo "${USERS_TO_EXCLUDE[@]}" "${on_disk_exclusions[@]}" | /usr/bin/xargs | /usr/bin/tr ' ' '\n' | /usr/bin/sort -f | /usr/bin/uniq -ui)
fi

#############
#####BODY####
#############

#These 11 checks will validate audit + enforcement of script/agent health, as well as validating the latest version is installed, the timeout value, profile setting, + user exclusions (if defined) match across audit + remediation scripts 
if [[ -f "${agent_path}" && -f "${script_path}" && -n "${agent_args}" && "${agent_permissions}" -eq 644 && "${script_permissions}" -eq 444 && "${agent_immutable}" == "schg" && "${script_immutable}" == "schg" && "${version_validation}" -eq 0 && "${timeout_matches}" == true && "${profile_matches}" == true && -z "${exclusion_diff}" ]]; then
    LOGGING "All checks pass"
    exit 0
else
    LOGGING "One or more failures occurred:"
    LOGGING "Agent Path: $(/bin/ls ${agent_path} 2>&1)"
    LOGGING "Agent Permissions: ${agent_permissions} (expected 644)"
    LOGGING "Agent Immutable: ${agent_immutable} (expected schg)"
    LOGGING "Script Path: $(/bin/ls ${script_path} 2>&1)"
    LOGGING "Script Permissions: ${script_permissions} (expected 444)"
    LOGGING "Script Immutable: ${script_immutable} (expected schg)"
    LOGGING "Agent Arguments: ${agent_args} (expected /path/to/privilegeschecker.zsh)"
    LOGGING "On-disk version: ${script_version} (expected ${version})"
    LOGGING "On-disk timeout: ${on_disk_minutes} (expected ${MINUTES_TO_WAIT})"
    LOGGING "On-disk use profile: ${on_disk_profile} (expected ${USE_PROFILE_TIMEOUT})"
    LOGGING "Excluded users: ${on_disk_exclusions} (expected ${USERS_TO_EXCLUDE})"
    exit 1
fi
