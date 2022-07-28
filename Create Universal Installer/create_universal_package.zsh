#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 07/22/2022
###################################################################################################
# Software Information
###################################################################################################
#
# Script downloads two .apps, one for Intel architecture, one for Apple silicon, and
# builds a combined Universal macOS Installer component package which will place the native .app
# in /Applications for the appropriate Mac architecture.
#
# Validates proper Developer ID Authority/Team Identifier on .app bundles
# Validates matching application versions and bundle identifiers on .app bundles
# If any of those checks fail, package will not build and script will exit 1
#
# Has support for .zip or .dmg files that contain .apps to be placed in /Applications
#
###################################################################################################
# Usage
###################################################################################################
#
# Run the below command; a PKG will be created in the directory from where the script is executed
#
# /bin/zsh /path/to/create_universal_package.zsh
#
###################################################################################################
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
#
###################################################################################################

############################
##########VARIABLES#########
############################

#Name of the app
#This will be used to name the built PKG
application_name=""

#Two download URLs, one for Apple silicon, one for Intel
#Supports either both .dmg or both .zip downloads that contain a .app
apple_download=""
intel_download=""

#Code signature values will be compared against downloaded .apps to confirm security 
#If left blank, missing entries will be reported at runtime, and reported values reported from above downloads 
#Undefined vars can be populated interactively from reported values when prompted from this script

#To hardcode variables, signatures can be determined in advance by running the following commands against the desired .app:

#Developer ID authority: /usr/bin/codesign -dvv "/Applications/EXAMPLE.app" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs
#Team Identifier: /usr/bin/codesign -dvv "/Applications/EXAMPLE.app" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2

dev_id_authority=""
team_identifier=""

# NOTE: By default, script will only build PKG if both Intel + Apple silicon .apps have identical versions and bundle identifiers
#To disable this functionality, (e.g. for apps with differing version #s between archs), set the below to false
#Can also leave blank to populate the variable at runtime
#If disabled, the version associated with the built PKG will be that of the Apple silicon .app
# NOTE: Running this script with flag --nomatch will only set the value for the runtime; to permanently disable matching, set the below to false
match_versions=true

#################################################################################################
##########################################DO NOT MODIFY##########################################
#################################################################################################

script_version=1.0.0

###########################
#########ARGUMENTS#########
###########################

#Set arguments with zparseopts
zparseopts -D -E -a opts h -help n -nomatch v -verbose -labels+:=label_args l+:=label_args

#Set args for help
if (( ${opts[(I)(-h|--help)]} )); then
    printf "\nUsage: ./create_universal_package.zsh [--help|--nomatch|--verbose]\n"
    printf "\n\n###############\n#####ABOUT#####\n###############\n\n"
    printf "Program will create a combined Universal macOS Installer component package\n"
    printf "Builds from separate Apple silicon and Intel .apps for the same application title\n"
    printf "Program supports download URLs of simple .zips or .dmgs containing .apps\n"
    printf "PKG contains logic to place the native .app in /Applications for the proper Mac architecture\n"
    printf "\n\n########################\n########SECURITY########\n########################\n\n"
    printf "Validates proper Developer ID Authority/Team Identifier on .app bundles\n"
    printf "Validates application versions and bundle identifiers match on .app bundles\n"
    printf "NOTE: Version + bundle ID checks can be disabled by passing --nomatch or setting match_versions=false\n" 
    printf "If any of the above checks fail, package will not build, errors printed, and script will exit 1\n\n"
  exit 0
fi

#Set args for verbosity
if (( ${opts[(I)(-v|--verbose)]} )); then
    set -x
fi

#Set args to disable version/bundle ID match validation across archs 
if (( ${opts[(I)(-n|--nomatch)]} )); then
    printf "Setting match requirement to false for this run..."
    match_versions=false
fi

############################
##########FUNCTIONS#########
############################

##############################################
# Checks if vars passed to func are defined
# If not, offer input def for the runtime
# Null vars are appended to `undefined_vars`
# If `undefined_vars` is not null, offer to
# write out newly defined vars to new file
# Arguments:
#   Takes multiple args ("$@")
#   Input is assigned to `var_names`
# Returns:
#   Array of undefined var names 
#   to func `replicate_file`
#   Returns exit 1 if `var_name` remains undefined
##############################################
function variable_assignments()
{
    declare -a undefined_vars
    var_names=("$@")
    for var_name in "${var_names[@]}"; do
        #In zsh, (P)VAR returns the def of the var
        if [[ -z "${(P)var_name}" ]]; then
            printf "\n\nALERT: Variable ${var_name} not defined!\n"
            undefined_vars+=${var_name}
            if read -q "?Set the value now for ${var_name}? (Y/N): "; then
                while [[ -z "${(P)var_name}" ]]; do
                    printf "\n\n"
                    read "?Enter value for ${var_name}: " ${var_name}
                done
            else
                printf "\n\n\n\n###############\n#####ERROR#####\n###############\n\nVariable ${var_name} requires assignment to continue!\nPlease enter required information when prompted.\n"
                printf "Alternatively, hardcode undefined values in this script.\n\nMissing required values - exiting program..."
                exit 1
            fi
        fi
    done

    if [[ -n "${undefined_vars[@]}" ]]; then
        #Offer to duplicate this file and fill in variables defined interactively
        replicate_file $(echo "${undefined_vars}")
    fi
}

##############################################
# Assign values to script variable based on 
# hardcoded values or strs entered at runtime
# Returns:
#   Assigned variable values for script use
##############################################
function name_stuff() {
    #Temp build directories for package creation
    tmp_build_dir="/tmp/${application_name}_Universal_Build"
    tmp_build_dir_apple="${tmp_build_dir}/Apple"
    tmp_build_dir_intel="${tmp_build_dir}/Intel"
    tmp_build_dir_scripts="${tmp_build_dir}/Scripts"

    #Name of .zip downloads
    apple_zip="${application_name}-Apple.zip"
    intel_zip="${application_name}-Intel.zip"

    #Name and mountpoints for .dmg downloads
    apple_dmg="${application_name}-Apple.dmg"
    intel_dmg="${application_name}-Intel.dmg"
    apple_mountpoint="${tmp_build_dir}/${application_name}-Apple-Mount"
    intel_mountpoint="${tmp_build_dir}/${application_name}-Intel-Mount"
}

##############################################
# Executes a number of prechecks to ensure var
# definitions are present and assign if not
# Names other vars based on required input
# Removes existing build dir if present based
# on `application_name` definition
# Creates required build directories for PKG
# Arguments:
#   If undefined, prompts to populate value
#   for any of the below empty vars:
#   application_name
#   apple_download
#   intel_download
#   match_versions
# Outputs:
#   Writes build dirs to /tmp
##############################################
function prechecks() {

    #Ensure variables are defined
    #If not, prompt to populate them interactively
    #Exit 1 if any remain undefined post-prompt
    variable_assignments application_name apple_download intel_download match_versions

    #Populate variables for files and names given ${application_name}
    name_stuff

    #If previous directory exists from failed run, remove it
    if [[ -d "${tmp_build_dir}" ]]; then
        printf "\nPrevious build directory found... removing\n\n"
        /bin/rm -R "${tmp_build_dir}"
    fi

    #Create empty directories to populate
    /bin/mkdir -p "${tmp_build_dir_apple}" "${tmp_build_dir_intel}" "${tmp_build_dir_scripts}"

}

##############################################
# Only called if vars are defined during runtime
# Asks the user if they want to write a new file
# for the app they are building, so they can
# invoke that in the future without specifying
# input values upon the next run of this program 
# Outputs:
#   New file under `replicated_name`
#   `replicated_name` will have updated values
#   replaced from sed if there are vars
#   newly defined during the runtime
# Returns:
#   0 if user skips writing new file.
##############################################
function replicate_file() {

    #ZSH_ARGZERO is a built-in for zsh to get script name
    #We use this because invoking ${0} within a function returns the function name
    script_name=$(/usr/bin/basename "${ZSH_ARGZERO}")
    #Prepend the application_name to the script_name
    replicated_name="${application_name}_${script_name}"

    printf "\n\n"
    if read -q "?Write all above values to new file? (Y/N): "; then
        if [[ -e "${replicated_name}" ]]; then
            printf "\n\n"
            if read -q "?ALERT: ${replicated_name} already exists! Update with new values? (Y/N): "; then
                printf "\nUpdating ${replicated_name}"
            else
                return 0
            fi
        else
            /bin/cp "${script_name}" "${replicated_name}"
        fi

        var_names=("$@")
        for var_name in "${var_names[@]}"; do
            if [[ -n "${(P)var_name}" ]]; then
                /usr/bin/sed -i "" "s|${var_name}=.*|${var_name}='${(P)var_name}'|g" "${replicated_name}"
            else
                printf "\n\n###############\n#####ERROR#####\n###############\n\n"
                printf "\nVariable ${var_name} not defined!\nYou must set a value for ${var_name} to continue."
                exit 1
            fi
        done
        printf "\n\nSUCCESS: Wrote value(s) to ${replicated_name}\n"
        printf "\nPROTIP: Run 'zsh ${replicated_name}' next time to build a package without prompts!\n\n\n"
    else
        printf "\n\nContinuing without writing above variable to file..."
    fi
}

##############################################
# Downloads two DMGs, one Apple, one Intel
# Mounts them both, copies the .app contents
# to the temp build dir for each arch
# Unmounts the DMG and deletes when done
# Outputs:
#   Downloads temporary DMG files
#   Moves .app bundles to build dirs
# Returns:
#   Success message if exit 0
##############################################
function download_dmg() {

    #Download our arm64 and x86_64 files
    printf "Beginning download of ${apple_dmg}\n"
    /usr/bin/curl -L "${apple_download}" -o "${tmp_build_dir_apple}/${apple_dmg}"
    printf "Beginning download of ${intel_dmg}\n"
    /usr/bin/curl -L "${intel_download}" -o "${tmp_build_dir_intel}/${intel_dmg}"

    /bin/mkdir -p "${apple_mountpoint}" "${intel_mountpoint}"

    /usr/bin/hdiutil attach "${tmp_build_dir_apple}/${apple_dmg}" -mountpoint "${apple_mountpoint}" -noverify -nobrowse -noautoopen >/dev/null 2>&1
    /usr/bin/hdiutil attach "${tmp_build_dir_intel}/${intel_dmg}" -mountpoint "${intel_mountpoint}" -noverify -nobrowse -noautoopen >/dev/null 2>&1

    /usr/bin/find "${apple_mountpoint}" -maxdepth 1 -iname "*.app*" -exec /bin/cp -R {} "${tmp_build_dir_apple}" \; \
    && /usr/bin/hdiutil detach "${apple_mountpoint}" >/dev/null 2>&1 \
    && /bin/rm "${tmp_build_dir_apple}/${apple_dmg}" \
    && /bin/rm -R "${apple_mountpoint}" \
    && printf "\nSuccessfully extracted Apple application $(/bin/ls ${tmp_build_dir_apple})\n"

    /usr/bin/find "${intel_mountpoint}" -maxdepth 1 -iname "*.app*" -exec /bin/cp -R {} "${tmp_build_dir_intel}" \; \
    && /usr/bin/hdiutil detach "${intel_mountpoint}" >/dev/null 2>&1 \
    && /bin/rm "${tmp_build_dir_intel}/${intel_dmg}" \
    && /bin/rm -R "${intel_mountpoint}" \
    && printf "Successfully extracted Intel application $(/bin/ls ${tmp_build_dir_intel})\n"
}

##############################################
# Downloads two ZIPs, one Apple, one Intel
# Expands the .app contents each of
# to the temp build dir for each arch
# Deletes the ZIP when done
# Outputs:
#   Downloads temporary ZIP files
#   Expands .app bundles to build dirs
# Returns:
#   Success message if exit 0
##############################################
function download_zip() {

    #Download our arm64 and x86_64 .zips
    printf "Beginning download of ${apple_zip}\n"
    /usr/bin/curl -L "${apple_download}" -o "${tmp_build_dir_apple}/${apple_zip}"
    printf "Beginning download of ${intel_zip}\n"
    /usr/bin/curl -L "${intel_download}" -o "${tmp_build_dir_intel}/${intel_zip}"

    #Unzip both installs to architecture-specific folders and remove the zips upon success
    /usr/bin/unzip "${tmp_build_dir_apple}/${apple_zip}" -d "${tmp_build_dir_apple}" >/dev/null 2>&1 \
    && /bin/rm "${tmp_build_dir_apple}/${apple_zip}" \
    && printf "Successfully unzipped Apple application $(/bin/ls ${tmp_build_dir_apple})\n"

    /usr/bin/unzip "${tmp_build_dir_intel}/${intel_zip}" -d "${tmp_build_dir_intel}" >/dev/null 2>&1 \
    && /bin/rm "${tmp_build_dir_intel}/${intel_zip}" \
    && printf "Successfully unzipped Intel application $(/bin/ls ${tmp_build_dir_intel})\n"
}

##############################################
# Confirms both Apple + Intel DL URLs
# Ensures content size for both URLs is > 0
# Identifies DL type from URL suffix
# If filename does not include .dmg or .zip,
# will attempt to identify from header info
# Selects DMG or ZIP based on results
# Otherwise print output + exit with error 
# Returns:
#   Exit + error with output if any checks fail
#   Otherwise, proceeds to appropriate DL func
##############################################
function determine_download() {

    if [[ -n "${apple_download}" ]] && [[ -n "${intel_download}" ]]; then

        printf "Determining filetypes for download... "
        #Query our download locations and capture stderr + stdout for parsing
        apple_header=$(/usr/bin/curl -sIvL "${apple_download}" 2>&1)
        intel_header=$(/usr/bin/curl -sIvL "${intel_download}" 2>&1)

        #Get the size of the download (last entry) and ensure it's greater than 0
        apple_download_size=$(echo "${apple_header}" | /usr/bin/grep -i 'content-length' | /usr/bin/tail -1 | /usr/bin/cut -d ":" -f2 | /usr/bin/xargs | /usr/bin/fmt)
        intel_download_size=$(echo "${intel_header}" | /usr/bin/grep -i 'content-length' | /usr/bin/tail -1 | /usr/bin/cut -d ":" -f2 | /usr/bin/xargs | /usr/bin/fmt)

        #Parse the verbose return to look for redirect location and identify .zip or .dmg from there
        apple_download_type=$(echo "${apple_header}" | /usr/bin/grep -i 'location:\|content-type\|content-disposition:' | /usr/bin/sed -n -e 's/^.*ocation: //p' -e 's/^[Cc]ontent-[Tt]ype: //p' -e 's/^[Cc]ontent-[Dd]isposition: //p'| /usr/bin/sort -u)
        intel_download_type=$(echo "${intel_header}" | /usr/bin/grep -i 'location:\|content-type\|content-disposition:' | /usr/bin/sed -n -e 's/^.*ocation: //p' -e 's/^[Cc]ontent-[Tt]ype: //p' -e 's/^[Cc]ontent-[Dd]isposition: //p'| /usr/bin/sort -u)

        #Check DL sizes
        if [[ ${apple_download_size} -gt 0 ]] && [[ ${intel_download_size} -gt 0 ]]; then
            printf "\nApple download size is ${apple_download_size} bytes\n"
            printf "Intel download size is ${intel_download_size} bytes\n\n"
        else
            printf "\n\n###############\n#####ERROR#####\n###############\n\n"
            printf "At least one download did not return expected content length!\n"
            printf "'apple_download' set as ${apple_download} returned a download size of ${apple_download_size} bytes\n"
            printf "'intel_download' set as ${intel_download} returned a download size of ${intel_download_size} bytes\n\n"
            printf "Double-check the above values and try again"
            exit 1
        fi

        #Check filename and location from cURL response for .zip or .dmg
        if [[ -n $(echo "${apple_download}" | /usr/bin/grep -i '.zip') && -n $(echo "${intel_download}" | /usr/bin/grep -i '.zip') ]] \
        || [[ -n $(echo "${apple_download_type}" | /usr/bin/grep -i '.zip' ) ]] && [[ -n $(echo "${intel_download_type}" | /usr/bin/grep -i '.zip' ) ]]; then
            printf "\nIdentified Apple download type/source(s) as ${apple_download_type}\n" 2>/dev/null
            printf "\nIdentified Intel download type/source(s) as ${intel_download_type}\n\n" 2>/dev/null
            printf "Specified downloads are zip files\nContinuing...\n\n"

            download_zip

        elif [[ -n $(echo "${apple_download}" | /usr/bin/grep -i '.dmg') && -n $(echo "${intel_download}" | /usr/bin/grep -i '.dmg\|diskimage') ]] \
        || [[ -n $(echo "${apple_download_type}" | /usr/bin/grep -i '.dmg' ) && -n $(echo "${intel_download_type}" | /usr/bin/grep -i '.dmg\|diskimage' ) ]]; then
            printf "\nIdentified Apple download type/source(s) as ${apple_download_type}\n" 2>/dev/null
            printf "\nIdentified Intel download type/source(s) as ${intel_download_type}\n\n" 2>/dev/null
            printf "Specified downloads are disk images\nContinuing...\n\n"

            download_dmg

        else
            printf "\n\n###############\n#####ERROR#####\n###############\n\n"
            printf "Specified downloads may be mismatched, invalid, or filetype other than .zip/.dmg!\n"
            printf "'apple_download' value populated as ${apple_download}\n"
            printf "'intel_download' value populated as ${intel_download}\n\n"
            printf "Double-check the above values and try again"
            exit 1
        fi
    else
        printf "\n\n###############\n#####ERROR#####\n###############\n\n"
        printf "One or more downloads may be invalid or not populated!\n"
        printf "'apple_download' value populated as ${apple_download}\n"
        printf "'intel_download' value populated as ${intel_download}\n\n"
        printf "Double-check the above values and try again"
        exit 1
    fi

}

##############################################
# Stores the name for both Intel + Apple .apps
# Confirms proper arch for Intel + Apple .apps
# Returns:
#   Assigns `app_name` if both app names match
#   Exit + error with output if any checks fail
##############################################
function get_app_name_arch() {

    apple_name=$(/usr/bin/basename "$(/usr/bin/find ${tmp_build_dir_apple} -iname "*.app" -maxdepth 1)" )
    intel_name=$(/usr/bin/basename "$(/usr/bin/find ${tmp_build_dir_intel} -iname "*.app" -maxdepth 1)" )

    #Identify executable names from Info.plist
    apple_exec=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${tmp_build_dir_apple}/${apple_name}/Contents/Info.plist")
    intel_exec=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${tmp_build_dir_intel}/${intel_name}/Contents/Info.plist")

    #Find the path within the MacOS dir matching the CFBundleExecutable
    apple_exec_path=$(/usr/bin/find "${tmp_build_dir_apple}/${apple_name}/Contents/MacOS" -name ${apple_exec} -maxdepth 1)
    intel_exec_path=$(/usr/bin/find "${tmp_build_dir_intel}/${intel_name}/Contents/MacOS" -name ${intel_exec} -maxdepth 1)

    #Confirm Apple exec and Intel exec types are as expected (discard path)
    apple_exec_type=$(/usr/bin/file -b "${apple_exec_path}" | /usr/bin/xargs)
    intel_exec_type=$(/usr/bin/file -b "${intel_exec_path}" | /usr/bin/xargs)

    #Ensure Apple arch shows arm64; Intel arch x86_64
    if [[ -n $(echo "${apple_exec_type}" | /usr/bin/grep -i "arm64") ]] && [[ -n $(echo "${intel_exec_type}" | /usr/bin/grep -i "x86_64") ]]; then
        printf "\nApple .app exec type is ${apple_exec_type}"
        printf "\nIntel .app exec type is ${intel_exec_type}"
    else
        printf "\n\n###############\n#####ERROR#####\n###############\n\nDownloaded .app executables were not expected values!\n"
        printf "Apple .app executable ${apple_exec} type at path ${apple_exec_path} reported as ${apple_exec_type}\n"
        printf "Intel .app executable ${intel_exec} type at path ${intel_exec_path} reported as ${intel_exec_type}\n"
        printf "Double-check the above values and try again."
        exit 1
    fi

    #If both app names match, set common name `app_name`
    if [[ "${apple_name}" == "${intel_name}" ]]; then
        app_name="${apple_name}"
    else
        printf "\n\n###############\n#####ERROR#####\n###############\n\nDownloaded .app names do not match!\n"
        printf "Apple .app name is ${apple_name}\n"
        printf "Intel .app name is ${intel_name}\n\n"
        printf "Double-check the above values and try again."
        exit 1
    fi
}

##############################################
# Populates Developer ID Authority and
# Team Identifier from .app bundle for each
# Apple + Intel architecture; confirms they
# match as expected across architectures
# If any security vars are missing, will prompt
# the user to populate interactively; can use
# the `codesign` output if source is trusted
# Arguments:
#   If undefined, prompts to populate value
#   for any of the below empty vars:
#   dev_id_authority 
#   team_identifier
# Returns:
#   WARNING if security checks are unpopulated
#   prior to offering runtime input
##############################################
function populate_security() {

    #Populate Signing Authority and TeamID values
    apple_dev_authority=$(/usr/bin/codesign -dvv "${tmp_build_dir_apple}/${app_name}" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs)
    intel_dev_authority=$(/usr/bin/codesign -dvv "${tmp_build_dir_intel}/${app_name}" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs)
    apple_teamid=$(/usr/bin/codesign -dvv "${tmp_build_dir_apple}/${app_name}" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2)
    intel_teamid=$(/usr/bin/codesign -dvv "${tmp_build_dir_intel}/${app_name}" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2)

    #If there is a mismatch with known good values, our validate_security function below will catch it
    if [[ "${apple_teamid}" == "${intel_teamid}" ]] && [[ "${apple_dev_authority}" == "${intel_dev_authority}" ]]; then

        if [[ ! "${dev_id_authority}" ]] && [[ "${apple_dev_authority}" == "${intel_dev_authority}" ]]; then
            printf "\n\n#####################\n#######WARNING#######\n#####################\n\n"
            printf "Developer ID not populated!\n"
            printf "If you trust this source, 'dev_id_authority' variable can be populated as\n\n${apple_dev_authority}\n\n"
        fi

        if [[ ! "${team_identifier}" ]] && [[ "${apple_teamid}" == "${intel_teamid}" ]]; then
            printf "\n\n#####################\n#######WARNING#######\n#####################\n\n"
            printf "Team identifier not populated!\n"
            printf "If you trust this source, 'team_identifier' variable can be populated as\n\n${apple_teamid}\n\n"
        fi

        #Check our variables and offer assignment
        variable_assignments dev_id_authority team_identifier
    fi
}

##############################################
# Confirms populated values for `team_identifier`
# and `dev_id_authority` match exactly both
# Intel and Apple architecture vars populated
# in func populate_security
# Returns:
#   Success if all values match
#   Exit + error with output if any checks fail
##############################################
function validate_security() {

    printf "\n\nBeginning security checks...\n"
    #Run security checks
    if [[ "${apple_teamid}" == "${team_identifier}" ]] && [[ "${intel_teamid}" == "${team_identifier}" ]] \
    && [[ "${apple_dev_authority}" == "${dev_id_authority}" ]] && [[ "${intel_dev_authority}" == "${dev_id_authority}" ]]; then
        printf "All security checks passed\n"
    else
        #If security checks do not match expected values, report defined and expected values to stdout and exit 1
        printf "\n\n###############\n#####ERROR#####\n###############\n\nExpected values for Team Identifier and Developer Authority did not match!\n\n"
        printf "Expected Team Identifier is ${team_identifier}\n"
        printf "Apple ${app_name} Team Identifier is ${apple_teamid}\n"
        printf "Intel ${app_name} Team Identifier is ${intel_teamid}\n\n"
        printf "Expected Developer Authority is ${dev_id_authority}\n"
        printf "Apple ${app_name} Developer Authority is ${apple_dev_authority}\n"
        printf "Intel ${app_name} Developer Authority is ${intel_dev_authority}\n\n"
        printf "Installation package for ${application_name} was NOT created\n"
        printf "Inspect temp build directory at ${tmp_build_dir} for issues"
        exit 1
    fi
}

##############################################
# Confirms matching verisons and bundle IDs
# for target Apple silicon and Intel .apps
# Otherwise, if `match_versions` is set to
# False, will skip version/bundle checks and 
# assign version and bundle ID from Apple value
# Returns:
#   Success and assigned values if all checks pass 
#   Exit + error with output if any checks fail
##############################################
function confirm_versions() {

    #NOTE: If match_versions is set to true, Script will only build PKG if both Intel + Apple silicon .apps have identical versions and bundle identifiers
    #This is to ensure our installation package has the correct version and bundle ID for either arch ${app_name}install

    #Get both ShortVersion and Version (in that order)
    #Prefer ShortVersion where it exists
    apple_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" -c "Print :CFBundleVersion" "${tmp_build_dir_apple}/${app_name}/Contents/Info.plist" 2>/dev/null | /usr/bin/head -1)
    intel_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" -c "Print :CFBundleVersion" "${tmp_build_dir_intel}/${app_name}/Contents/Info.plist" 2>/dev/null | /usr/bin/head -1)

    #Get Bundle IDs
    apple_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${tmp_build_dir_apple}/${app_name}/Contents/Info.plist")
    intel_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${tmp_build_dir_intel}/${app_name}/Contents/Info.plist")

    if [[ ! "${match_versions}" =~ [fF] ]]; then
        #Ensure both match
        if [[ "${apple_version}" == "${intel_version}" ]]; then
            version="${apple_version}"
        fi

        if [[ "${apple_id}" == "${intel_id}" ]]; then
            identifier="${apple_id}"
        fi
    else
        printf "Match check set to ${match_versions}; skipping version comparison\n"
        #Skipping match check
        #Set Apple silicon .app values for our PKG build
        if [[ -n "${apple_version}" ]]; then
            printf "\n\nSetting Apple silicon version ${apple_version} as PKG version\n"
            printf "NOTE: this may differ from the Intel version of ${intel_version}!"
            version="${apple_version}"
        fi

        if [[ -n "${apple_id}" ]]; then
            identifier="${apple_id}"
            printf "\n\nSetting Apple silicon bundle ID ${apple_id} as PKG ID\n"
            printf "NOTE: this may differ from the Intel bundle ID of ${intel_id}!\n\n"
        fi
    fi
    #Validate joint version and identifier vars are valid
    #If not, values may be mismatched between Apple and Intel builds (or just Apple if match_versions = false)
    if [[ -n "${version}" ]] && [[ -n "${identifier}" ]]; then
        printf "Identified ${app_name} version as ${version}\n"
        printf "Identified ${app_name} bundle ID as ${identifier}\n\n"
    else
        #If ${version} and/or ${identifier} are not defined, exit 1 and report defined values to stdout
        printf "\n\n###############\n#####ERROR#####\n###############\n\nDerived values for version and/or identifier did not match or was not found\n\n"
        printf "Identified Apple version as ${apple_version}\n"
        printf "Identified Intel version as ${intel_version}\n\n"
        printf "Identified Apple identifier as ${apple_id}\n"
        printf "Identified Intel identifier as ${intel_id}\n\n"
        printf "Installation package for ${application_name} was NOT created\n"
        printf "Inspect temp build directory at ${tmp_build_dir} for issues\n\n"
        printf "NOTE: If app architectures are known to have differing versions, set 'match_versions=false' in this script"
        exit 1
    fi
}

##############################################
# Moves two .apps into arch-specific dirs within
# Scripts dir for PKG construction; writes out
# two heredocs (one with vars expanded, one 
# without) with preinstall script instructions
# to copy the correct .app bundle to /Applications
# based on processor type of the client Mac 
# Outputs:
#   preinstall and two .app bundles to
#   PKG build directory
##############################################
function stage_preinstall() {

    #Move our arch-specific folders containing the .app to our Scripts folder
    /bin/mv "${tmp_build_dir_apple}" "${tmp_build_dir_intel}" "${tmp_build_dir_scripts}"

    #Preinstall below lives in the same Scripts directory as the .app folders
    #At installation time, script will identify processor type and then copy the correct .app bundle to /Applications
    #Write out preinstall heredoc and expand variables
    /bin/cat >"${tmp_build_dir_scripts}/preinstall" <<EOF
#!/bin/zsh

#Populate PKG names
app_name="${app_name}"
EOF

#Write out the remainder of the preinstall and do not expand vars
/bin/cat >>"${tmp_build_dir_scripts}/preinstall" <<"EOF"
apple_app="Apple/${app_name}"
intel_app="Intel/${app_name}"

#Get local directory
local_dir=$(/usr/bin/dirname ${0})

#Identify Mac processor type
intel_check=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | /usr/bin/grep -oi "Intel")

if [[ -n "${intel_check}" ]]; then
    /bin/cp -pR "${local_dir}/${intel_app}" "/Applications"
else
    /bin/cp -pR "${local_dir}/${apple_app}" "/Applications"
fi

#Touch the .app in /Applications so it refreshes the icon cache
/usr/bin/touch "/Applications/${app_name}"

exit 0
EOF

    #Make preinstall executable
    /bin/chmod a+x "${tmp_build_dir_scripts}/preinstall"
}

##############################################
# Execute pkgbuild to build installion PKG
# with .app identifier + version set as metadata
# Only includes Scripts directory (no Payload)
# with .apps contained in Apple + Intel dirs
# Outputs:
#   Creates new PKG at local directory where
#   ZSH script was invoked
# Returns:
#   Built package location upon success 
#   Exit + error with output if exit_code != 0 
##############################################
function build_universal_app() {

    #Build our package with a preinstall governing which .app installs on which architecture
    /usr/bin/pkgbuild --nopayload --scripts "${tmp_build_dir_scripts}" --identifier "${identifier}" --version ${version} "./${application_name}-${version}.pkg"

    exit_code=$?

    if [[ "${exit_code}" == 0 ]]; then
        printf "\nPKG successfully created at $(/bin/pwd)/${application_name}-${version}.pkg"
        #Remove our temporary build directory
        printf "\nRemoving temp build directory..."
        /bin/rm -R "${tmp_build_dir}"
        printf "\nDone!"
    else
        printf "\n\n\n\n###############\n#####ERROR#####\n###############\n\nPackage for ${app_name} returned error when building!\nSpecified error code was exit ${exit_code}\n"
        printf "Installation package for ${application_name} was NOT created\n"
        printf "Inspect temp build directory at ${tmp_build_dir} for issues"
        exit 1
    fi
}

##############################################
# Execute main logic
##############################################
function main() {

    prechecks

    determine_download

    get_app_name_arch

    populate_security

    validate_security

    confirm_versions

    stage_preinstall

    build_universal_app
}

###############
#####BUILD#####
###############

main

exit 0
