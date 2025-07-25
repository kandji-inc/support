#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 07/21/25
# Updated on 07/23/25; Updated by Daniel Chapa
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Custom script to add the following tamper protection exclusions to Microsoft Defender profiles:
# - Kandji signing ID
# - Kandji team ID
# - Kandji binary paths  
# NOTE:
# If exclusions are already present, the script will ensure all values are valid
#
###################################################################################################
# License Information
###################################################################################################
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
###################################################################################################

declare -A id_path

id_path=(
    "kandji-cli" "/Library/Kandji/Kandji Agent.app/Contents/Helpers/Kandji CLI.app/Contents/MacOS/kandji-cli"
    "kandji-daemon" "/Library/Kandji/Kandji Agent.app/Contents/Helpers/Kandji Daemon.app/Contents/MacOS/kandji-daemon"
    "kandji-library-manager" "/Library/Kandji/Kandji Agent.app/Contents/Helpers/Kandji Library Manager.app/Contents/MacOS/kandji-library-manager"
)

team_id="P3FGV63VK7"

expected_payload_id="com.microsoft.wdav"

##############################
########## FUNCTIONS #########
##############################

##############################################
# Formats provided text with ###s to create 
# section headers and footers.
# Globals:
#   None
# Arguments:
#   ${1}; Text string to format with hash 
#         borders
# Outputs:
#   Formatted text with hash borders to stdout
##############################################
function format_stdout() {
    body=${1}
    # Formats provided str with #s to create a header
    hashed_body="####### ${body} #######"
    # shellcheck disable=SC2051
    hashed_header_footer=$(printf '#%.0s' {1..$#hashed_body})
    echo "\n\n${hashed_header_footer}\n${hashed_body}\n${hashed_header_footer}\n"
}

##############################################
# Prompts user for .mobileconfig path and 
# validates the file extension.
# Globals:
#   None
# Arguments:
#   ${1}; Optional path to .mobileconfig file 
#   (if not provided, user will be prompted)
# Outputs:
#   Validated .mobileconfig path to stdout
##############################################
function profile_prompt_check() {

    profile=${1}

    if test -z "${profile}"; then

        # Prompt for .mobileconfig path
        # Disable beautysh read formatting (indents)
        # @formatter:off
        read "provided_profile_path?Drag 'n' drop a .mobileconfig to insert Kandji exclusions (this action will create a backup, then update the profile in place):
"
        # @formatter:on
    else
        provided_profile_path=$(realpath "${profile}")
    fi

    if [[ ! "${provided_profile_path}" =~ .*mobileconfig$ ]]; then
        echo "File ${provided_profile_path} is not valid! File name must end in .mobileconfig"
        profile_prompt_check
        return
    fi
    echo "Updating ${provided_profile_path:t} with Kandji exclusions..."
}

##############################################
# Checks if a Kandji exclusion already exists 
# in the existing exclusions array.
# Globals:
#   team_id; Kandji team identifier
# Arguments:
#   ${1}; Signing ID to check
#   ${2}; App path to check
#   ${3}; Array of existing exclusions
# Outputs:
#   Returns 0 if exclusion exists, 1 if not
##############################################
function check_exclusion_exists() {
    local sign_id app_path existing_exclusions OLD_IFS existing_signing_id existing_path existing_team_id
    
    sign_id="${1}"
    app_path="${2}"
    existing_exclusions=("${@:3}")
    
    # Store the original IFS value
    OLD_IFS="$IFS"
    
    # Set to what we want
    IFS=':'
    
    for existing_exclusion in "${existing_exclusions[@]}"; do
        read -r existing_signing_id existing_path existing_team_id <<< "${existing_exclusion}"
        if [[ "${existing_signing_id}" == "${sign_id}" ]] && [[ "${existing_path}" == "${app_path}" ]] && [[ "${existing_team_id}" == "${team_id}" ]]; then
            # Restore the original IFS
            IFS="$OLD_IFS"
            return 0  # Exclusion exists
        fi
    done
    
    # Restore the original IFS
    IFS="$OLD_IFS"
    return 1  # Exclusion does not exist
}

##############################################
# Checks for partial matches of a Kandji 
# exclusion in the existing exclusions array.
# Globals:
#   team_id; Kandji team identifier
# Arguments:
#   ${1}; Signing ID to check
#   ${2}; App path to check
#   ${3}; Array of existing exclusions
# Outputs:
#   Returns 0 if partial match found, 1 if not
##############################################
function check_partial_match() {
    local sign_id app_path existing_exclusions OLD_IFS existing_signing_id existing_path existing_team_id
    
    sign_id="${1}"
    app_path="${2}"
    existing_exclusions=("${@:3}")
    
    # Store the original IFS value
    OLD_IFS="$IFS"
    
    # Set to what we want
    IFS=':'
    
    for existing_exclusion in "${existing_exclusions[@]}"; do
        read -r existing_signing_id existing_path existing_team_id <<< "${existing_exclusion}"
        if [[ "${existing_signing_id}" == "${sign_id}" ]]; then
            echo "  Found signing_id '${sign_id}' but path or team_id mismatch:"
            echo "    Expected path: '${app_path}' vs Found: '${existing_path}'"
            echo "    Expected team_id: '${team_id}' vs Found: '${existing_team_id}'"
            # Restore the original IFS
            IFS="$OLD_IFS"
            return 0  # Partial match found
        fi
    done
    
    # Restore the original IFS
    IFS="$OLD_IFS"
    return 1  # No partial match
}

##############################################
# Adds a tamper protection exclusion to the 
# mobileconfig file using PlistBuddy.
# Globals:
#   None
# Arguments:
#   ${1}; Path to mobileconfig file
#   ${2}; Index for the exclusion
#   ${3}; App path
#   ${4}; Signing ID
#   ${5}; Team ID
# Outputs:
#   Returns 0 if successful, 1 if failed
##############################################
function add_exclusion_to_plist() {
    local mobileconfig_path index app_path sign_id team_id
    
    mobileconfig_path="${1}"
    index="${2}"
    app_path="${3}"
    sign_id="${4}"
    team_id="${5}"
    
    if /usr/libexec/PlistBuddy -c "Add :PayloadContent:0:tamperProtection:exclusions:${index} dict" "${mobileconfig_path}" && \
        /usr/libexec/PlistBuddy -c "Add :PayloadContent:0:tamperProtection:exclusions:${index}:path string ${app_path}" "${mobileconfig_path}" && \
        /usr/libexec/PlistBuddy -c "Add :PayloadContent:0:tamperProtection:exclusions:${index}:signingId string ${sign_id}" "${mobileconfig_path}" && \
        /usr/libexec/PlistBuddy -c "Add :PayloadContent:0:tamperProtection:exclusions:${index}:teamId string ${team_id}" "${mobileconfig_path}"; then
        return 0  # Success
    else
        return 1  # Failed
    fi
}

##############################################
# Creates a timestamped backup of the provided 
# .mobileconfig file before modification.
# Globals:
#   None
# Arguments:
#   ${1}; Path to .mobileconfig file to backup
# Outputs:
#   Backup creation status to stdout, warnings 
#   to stderr and exits if backup fails
##############################################
function backup_mobileconfig() {
    local mobileconfig_path backup_path

    mobileconfig_path="${1}"
    backup_path="${mobileconfig_path%%.mobileconfig}_$(date +%Y%m%d_%H%M%S).mobileconfig"
    
    if cp "${mobileconfig_path}" "${backup_path}"; then
        echo "Created backup: ${backup_path}"
    else
        echo "Error: Failed to create backup, exiting..." >&2
        exit 1
    fi
}

##############################################
# Main execution function for adding Kandji 
# exclusions to Microsoft Defender profiles.
# Globals:
#   id_path; Associative array of Kandji 
#            signing IDs and their binary 
#            paths
#   team_id; Kandji team identifier
#   expected_payload_id; Expected Microsoft 
#            Defender payload type
# 
# Arguments:
#   ${1}; Optional path to .mobileconfig file 
#   (if not provided, user will be prompted)
# 
# Outputs:
#   Backup file creation, exclusion scanning 
#   results, and operation summary to stdout
##############################################
function main() {

    profile_prompt_check "${1}"
    payload_id=$(/usr/libexec/PlistBuddy -c "Print :PayloadContent:0:PayloadType" "${provided_profile_path}" 2>/dev/null)
    if [[ "${payload_id}" != "${expected_payload_id}" ]]; then
        echo "Incorrect PayloadType (expected '${expected_payload_id}'; got '${payload_id}').\nPlease validate your .mobileconfig and try again."
        exit 1
    fi

    if ! /usr/libexec/PlistBuddy -c "Print :PayloadContent:0:tamperProtection:exclusions" "${provided_profile_path}" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Add :PayloadContent:0:tamperProtection:exclusions array"  "${provided_profile_path}"
    fi

    format_stdout "Inserting Kandji Exclusions"
    count=0
    until ! /usr/libexec/PlistBuddy -c "Print :PayloadContent:0:tamperProtection:exclusions:${count}" "${provided_profile_path}" >/dev/null 2>&1; do
        ((count++))
    done

    # First, scan and display all existing exclusions
    echo "Scanning existing exclusions..."
    existing_count=0
    existing_exclusions=()
    until ! /usr/libexec/PlistBuddy -c "Print :PayloadContent:0:tamperProtection:exclusions:${existing_count}" "${provided_profile_path}" >/dev/null 2>&1; do
        existing_path=$(/usr/libexec/PlistBuddy -c "Print :PayloadContent:0:tamperProtection:exclusions:${existing_count}:path" "${provided_profile_path}" 2>/dev/null)
        existing_signing_id=$(/usr/libexec/PlistBuddy -c "Print :PayloadContent:0:tamperProtection:exclusions:${existing_count}:signingId" "${provided_profile_path}" 2>/dev/null)
        existing_team_id=$(/usr/libexec/PlistBuddy -c "Print :PayloadContent:0:tamperProtection:exclusions:${existing_count}:teamId" "${provided_profile_path}" 2>/dev/null)

        echo "  Found existing exclusion: '${existing_signing_id}':'${existing_path}':'${existing_team_id}'"
        existing_exclusions+=("${existing_signing_id}:${existing_path}:${existing_team_id}")
        ((existing_count++))
    done

    # Check if we need to make any changes and create backup if needed
    for sign_id app_path in ${(kv)id_path}; do
        if ! check_exclusion_exists "${sign_id}" "${app_path}" "${existing_exclusions[@]}"; then
            backup_mobileconfig "${provided_profile_path}"
            break
        fi
    done

    # Then process to add new exclusions
    success_count=0
    mismatch_count=0
    kandji_exclusions_found=0
    for sign_id app_path in ${(kv)id_path}; do
        # Check if exclusion already exists
        if check_exclusion_exists "${sign_id}" "${app_path}" "${existing_exclusions[@]}"; then
            echo "Exclusion for '${sign_id}' already exists, skipping..."
            ((kandji_exclusions_found++))
        elif check_partial_match "${sign_id}" "${app_path}" "${existing_exclusions[@]}"; then
            echo "Exclusion for '${sign_id}' has partial match (mismatched path/team_id), adding new entry..."
            ((mismatch_count++))
            echo "Adding tamper exclusion for '${sign_id}':'${app_path}':'${team_id}'"

            # Add exclusion with success tracking
            if add_exclusion_to_plist "${provided_profile_path}" "${count}" "${app_path}" "${sign_id}" "${team_id}"; then
                ((success_count++))
                ((kandji_exclusions_found++))
            else
                echo "Warning: Failed to add exclusion for ${sign_id}" >&2
            fi
            ((count++))
        else
            echo "Adding tamper exclusion for '${sign_id}':'${app_path}':'${team_id}'"

            # Add exclusion with success tracking
            if add_exclusion_to_plist "${provided_profile_path}" "${count}" "${app_path}" "${sign_id}" "${team_id}"; then
                ((success_count++))
                ((kandji_exclusions_found++))
            else
                echo "Warning: Failed to add exclusion for ${sign_id}" >&2
            fi
            ((count++))
        fi
    done

    # Output the results of the above logic
    total_expected=${#id_path[@]}
    total_existing=${#existing_exclusions[@]}
    if [[ ${success_count} -eq ${total_expected} ]]; then
        format_stdout "Successfully Added All Kandji Exclusions"
        echo "Added ${success_count} exclusions to ${provided_profile_path}"
    elif [[ ${kandji_exclusions_found} -eq ${total_expected} ]] && [[ ${success_count} -eq 0 ]]; then
        format_stdout "All Kandji Exclusions Already Exist"
        echo "All ${total_expected} exclusions were already present in ${provided_profile_path}"
    else
        format_stdout "Partially Added Kandji Exclusions"
        if [[ ${mismatch_count} -gt 0 ]]; then
            echo "Added ${success_count} new exclusions, ${total_existing} were already present, ${mismatch_count} had partial matches (mismatched path/team_id)"
        else
            echo "Added ${success_count} new exclusions, ${total_existing} were already present"
        fi
    fi
}

###############
##### MAIN ####
###############

main "${1}"
