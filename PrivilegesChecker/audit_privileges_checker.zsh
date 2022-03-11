#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 02/11/2022
# Updated on 03/10/2022
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
# Audit script for Privileges Checker add-on. Conducts eight checks to validate the fidelity of the 
# Launch Agent and enforcement script:
# - Execution script exists (1), has proper permissions (2), and has system immutable flag set (3)
# - Launch Agent exists (4), has proper permissions (5), and has system immutable flag set (6)
# - Agent is alive and returns args of script (7), audit/remediation script versions match (8)
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
########################################## DO NOT MODIFY ##########################################
###################################################################################################

# zsh has a built-in operator that can actually do float compares; just gotta load it
autoload is-at-least

# Version for both audit + remediation scripts 
version=1.0.5

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

#############
#####BODY####
#############

# These eight checks will validate audit + enforcement of script/agent health, as well as validating the latest version is installed
if [[ -f "${agent_path}" && -f "${script_path}" && -n "${agent_args}" && "${agent_permissions}" -eq 644 && "${script_permissions}" -eq 444 && "${agent_immutable}" == "schg" && "${script_immutable}" == "schg" && "${version_validation}" -eq 0 ]]; then
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
    exit 1
fi
