#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 06/07/2024
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Script to migrate existing Insomnia 2020-2023 installs to Insomnia 8/9+ via Kandji
# An upgrade cannot occur without intervention due to a violation in semantic versioning practices
# Runs on macOS and detects/modifies an existing Insomnia bundle, allowing an upgrade in-place
# Once the .app is altered, script calls Kandji binary to trigger install of Kong Insomnia Auto App 
# NOTE: Ensure Auto App 'Kong Insomnia' is scoped to Kandji devices before running
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

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

##############################
########## VARIABLES #########
##############################

kandji_bin="/usr/local/bin/kandji"
insomnia_path="/Applications/Insomnia.app"
insomnia_info_plist="${insomnia_path}/Contents/Info.plist"
insomnia_old_floor="2020.0.0"
insomnia_new_floor="7.0.0"
insomnia_new_aa_name="Kong Insomnia"

##############################
########## FUNCTIONS #########
##############################

##############################################
# Overwrites CFBundleShortVersionString value
# in Info.plist to new major version floor to
# allow in-place upgrade of Kong Insomnia
# Fixes permissions on Info.plist, re-signs
# ad hoc, and strips xattrs that could prevent
# app launch post-upgrade
# Globals:
#   insomnia_info_plist
#   insomnia_new_floor
#   insomnia_path
# Outputs:
#   Writes new version to Info.plist
##############################################
function downgrade_vers_fix_perms() {
    # Overwrite version to be less than new major for app
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${insomnia_new_floor}" "${insomnia_info_plist}"
    # Fix perms
    /bin/chmod 644 "${insomnia_info_plist}"
    # Re-sign ad hoc
    /usr/bin/codesign --force --deep --sign - "${insomnia_path}"
    # Remove xattrs (if present) that could prevent app launch
    # -r flag got removed around 14.3, so if it fails, run find to clear recursively
    /usr/bin/xattr -rc "${insomnia_path}" >/dev/null 2>&1 || /usr/bin/find "${insomnia_path}" -exec /usr/bin/xattr -c "{}" \;
}

##############################################
# Invokes Kandji binary to trigger install of
# Kong Insomnia;  gets stdin from and redirects
# to /dev/null in bg to allow parallel
# execution without hanging Kandji binary
# Outputs:
#   Triggers Kong Insomnia install to disk
##############################################
function kandji_self_call() {

    echo "Triggering Auto App install of Kong Insomnia..."

    # Redirecting stderr/out to /dev/null and bg'ing the Kandji proc
    # This allows the agent to end its run without waiting for our script exec
    # We also provide stdin from /dev/null as well, allowing us to detach from any active TTY connections
    # Serves to inform our program any input will not be coming from a terminal session
    "${kandji_bin}" library --item "${insomnia_new_aa_name}" -F < /dev/null > /dev/null 2>&1 &
}

##############################################
# Main function to handle script execution
# Validates appropriate run permissions (sudo)
# Checks for existing Insomnia app bundle; if
# missing, proceeds to Kong Insomnia install
# If found, ensures Kong Insomnia is scoped
# Checks existing version; if higher than old
# major version floor, updates to new floor
# Calls Kandji binary to install new Kong
# Insomnia in-place over existing Auto App
# Globals:
#  EUID
#  insomnia_info_plist
#  insomnia_new_aa_name
#  insomnia_new_floor
#  insomnia_old_floor
#  insomnia_path
#  kandji_bin
# Returns:
#  Exit 0 on successful completion
#  Exit 1 if non-root exec or AA not in scope
##############################################
function main() {
    # Check invocation perms
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Script must be run with sudo or as root"
        exit 1
    fi

    # Only proceed with version mod if Insomnia exists at expected path
    if [[ -d "${insomnia_path}" ]]; then
        echo "Insomnia installed... checking version"

        insomnia_vers=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${insomnia_info_plist}")

        # Compare minimum enforced version to installed version via zsh builtin is-at-least
        autoload is-at-least
        is-at-least "${insomnia_old_floor}" "${insomnia_vers}" && upgrade_needed=true || upgrade_needed=false

        if ${upgrade_needed}; then
            echo "Insomnia version ${insomnia_vers} is greater than ${insomnia_old_floor}... Proceeding with downgrade"
            kandji_lib_items=$(${kandji_bin} library --list)
            if [[ -z $(grep -o "${insomnia_new_aa_name}" <<< "${kandji_lib_items}") ]]; then
                echo "${insomnia_new_aa_name} not scoped to Mac! Cannot complete cutover..."
                exit 1
            fi
            echo "Downgrading Insomnia CFBundleShortVersionString from ${insomnia_vers} to ${insomnia_new_floor}"
            downgrade_vers_fix_perms
            kandji_self_call
        else
            echo "Insomnia already on new major version ${insomnia_vers}... Nothing to do"
        fi
    else
        echo "Insomnia not installed..."
        kandji_lib_items=$(${kandji_bin} library --list)
        if [[ -z $(grep -o "${insomnia_new_aa_name}" <<< "${kandji_lib_items}") ]]; then
            echo "${insomnia_new_aa_name} not scoped to Mac! Cannot complete install..."
            exit 1
        fi
        kandji_self_call
    fi
    exit 0
}


###############
##### MAIN ####
###############
main
