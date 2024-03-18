#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 03/14/2024
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Script to transition LastPass Auto App to Mac App Store (MAS) LastPass Password Manager
# Runs on macOS and modifies an existing LastPass install to enable MAS installation/management 
# A direct upgrade cannot occur without intervention due to differing Bundle IDs used for each app
#     (Auto App: com.lastpass.lastpassmacdesktop; MAS: com.lastpass.LastPass)
# Once existing LastPass is altered, script calls Kandji binary to trigger LastPass MAS install
# NOTE: Ensure Mac App Store 'LastPass Password Manager' is scoped to Kandji devices before running
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
lp_bundle_path="/Applications/LastPass.app"
lp_info_plist="${lp_bundle_path}/Contents/Info.plist"
lp_mas_bid="com.lastpass.LastPass"

user=$(stat -f%Su /dev/console)
# If root, no console session
# Find most common user by console time and assign
if [[ "${user}" == "root" ]]; then
    user=$(ac -p | sort -nk 2 | grep -E -v "total|root|mbsetup|adobe" | tail -1 | xargs | cut -d " " -f1)
    echo "No console user found...Assuming ${user} from total logged in time"
fi

# User path with data to migrate over
# Doesn't include any PW data, but will populate user email
lp_old_lib_bundle="/Users/${user}/Library/WebKit/com.lastpass.lastpassmacdesktop"
lp_new_lib_bundle="/Users/${user}/Library/Containers/com.lastpass.LastPass"
lp_new_lib_data="${lp_new_lib_bundle}/Data/Library/WebKit/WebsiteData"

##############################
########## FUNCTIONS #########
##############################

##############################################
# Set the Info.plist Bundle Identifier to val
# defined for ${lp_mas_bid}; resets perms to
# 644 and re-signs the app using an ad hoc
# signature to allow open; removes xattr if
# present that would prevent app launch.
# Globals:
#   lp_mas_bid
#   lp_info_plist
#   lp_bundle_path
# Outputs:
#   Writes new Bundle Identifier to Info.plist
#   Fixes perms and re-signs app ad hoc
#   Strips xattrs if any present
##############################################
function rename_bundle_id() {
    # Overwrite bundle ID with MAS version
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${lp_mas_bid}" "${lp_info_plist}"
    # Fix perms
    chmod 644 "${lp_info_plist}"
    # Re-sign ad hoc
    codesign --force --deep --sign - "${lp_bundle_path}"
    # Remove xattrs (if present) that could prevent app launch
    # -r flag got removed around 14.3, so if it fails, run find to clear recursively
    xattr -rc "${lp_bundle_path}" >/dev/null 2>&1 || find "${lp_bundle_path}" -exec xattr -c "{}" \;
}

##############################################
# Invokes Kandji binary to trigger install of
# MAS LastPass;  gets stdin from and redirects
# to /dev/null in bg to allow parallel
# execution without hanging Kandji binary
# Outputs:
#   Triggers LastPass MAS install to disk
##############################################
function kandji_self_call() {

    echo "Triggering Mac App Store install of LastPass Password Manager..."

    # Redirecting stderr/out to /dev/null and bg'ing the Kandji proc
    # This allows the agent to end its run without waiting for our script exec
    # We also provide stdin from /dev/null as well, allowing us to detach from any active TTY connections
    # Serves to inform our program any input will not be coming from a terminal session
    "${kandji_bin}" library --item "LastPass Password Manager" -F < /dev/null > /dev/null 2>&1 &
}

##############################################
# Attempt location of Auto App LastPass data
# If found, create new directory structure for
# LastPass MAS app, fix up perms, and move
# user data into place; this populates the
# user email address for MAS LastPass
# Globals:
#  lp_old_lib_bundle
#  lp_new_lib_bundle
#  lp_new_lib_data
#  user
# Outputs:
#  Creates new LastPass MAS dir struct
#  Copies over Auto App LastPass data if found
##############################################
function create_migrate_defaults() {
    # Locate the old LastPass user data dir and assign
    lp_old_default=$(find ${lp_old_lib_bundle} -name Default)

    # If nonexistent, nothing to move
    if [[ -z "${lp_old_default}" ]]; then
        echo "No directory Default found in ${lp_old_lib_bundle}... Skipping user data migration"
        return 1
    fi

    # Create new MAS directory struct, reset owner, and move user data into place
    echo "Creating directory at ${lp_new_lib_data} and moving user data into place..."
    mkdir -p ${lp_new_lib_data}
    chown -f -R ${user} ${lp_new_lib_bundle}
    cp -R -p ${lp_old_default} ${lp_new_lib_data}
}

##############################################
# Main function to handle script execution
# Validates appropriate run permissions (sudo)
# Checks for existing LastPass app bundle; if
# missing, proceeds to MAS LastPass install
# If found, ensures MAS LastPass is scoped
# Checks existing bundle ID and different from
# MAS version, renames app bundle ID and calls
# Kandji binary to install MAS LastPass
# in-place over existing Auto App LastPass
# Globals:
#  EUID
#  lp_bundle_path
#  lp_info_plist
#  lp_mas_bid
#  kandji_bin
##############################################
function main() {
    # Check invocation perms
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Script must be run with sudo or as root"
        exit 1
    fi

    # Only proceed with bundle mod if LastPass exists at expected path
    if [[ -d ${lp_bundle_path} ]]; then
        existing_bid=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${lp_info_plist}")
        if [[ "${existing_bid}" != "${lp_mas_bid}" ]]; then
            kandji_lib_items=$(${kandji_bin} library --list)
            if [[ -z $(grep -o "LastPass Password Manager" <<< "${kandji_lib_items}") ]]; then
                echo "LastPass Password Manager not scoped to Mac! Cannot complete cutover..."
                exit 1
            fi
            echo "Changing LastPass Bundle ID from ${existing_bid} to ${lp_mas_bid}"
            rename_bundle_id
            create_migrate_defaults
            kandji_self_call
        else
            echo "LastPass Bundle ID already set to ${lp_mas_bid}... Nothing to do"
        fi
    else
        echo "LastPass not installed... Triggering Mac App Store install"
        kandji_self_call
    fi
    exit 0
}

###############
##### MAIN ####
###############
main
