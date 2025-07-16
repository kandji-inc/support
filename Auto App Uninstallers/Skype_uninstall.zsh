#!/bin/zsh
###################################################################################################
# Software Information
###################################################################################################
#
# Uninstaller script for Skype
# Designed for Kandji Auto Apps
#
###################################################################################################
# License Information
###################################################################################################
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
###################################################################################################

# NOTE: Descope any accompanying Configuration Profiles from devices running this uninstaller

##############################
########## VARIABLES #########
##############################

# NOTE: By default, uninstall won't delete user files
# To remove user files, set the below variable to true
delete_user_files=false

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

app_friendly_name="Skype"
app_path="/Applications/Skype.app"
app_bundle_id="com.skype.skype"

app_user_paths=(
    '${HOME}/Library/Address Book Plug-Ins/SkypeABCaller.bundle'
    '${HOME}/Library/Address Book Plug-Ins/SkypeABChatter.bundle'
    '${HOME}/Library/Address Book Plug-Ins/SkypeABDialer.bundle'
    '${HOME}/Library/Address Book Plug-Ins/SkypeABSMS.bundle'
    '${HOME}/Library/Application Scripts/com.skype.skype.shareagent'
    '${HOME}/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.skype.skype.sfl3'
    '${HOME}/Library/Application Support/CrashReporter/Skype_*.plist'
    '${HOME}/Library/Application Support/Microsoft/Skype for Desktop'
    '${HOME}/Library/Application Support/Skype Helper'
    '${HOME}/Library/Application Support/Skype'
    '${HOME}/Library/Application Support/T/SkypeRT'
    '${HOME}/Library/Caches/com.skype.skype'
    '${HOME}/Library/Caches/com.skype.skype.ShipIt'
    '${HOME}/Library/Caches/com.plausiblelabs.crashreporter.data/com.skype.skype'
    '${HOME}/Library/HTTPStorages/com.skype.skype'
    '${HOME}/Library/Logs/Skype Helper (Renderer)'
    '${HOME}/Library/Preferences/com.skype.skype.plist'
    '${HOME}/Library/Containers/com.skype.skype.shareagent'
    '${HOME}/Library/Cookies/com.skype.skype.binarycookies'
    '${HOME}/Library/Group Containers/*.com.skype.skype'
    '${HOME}/Library/Preferences/ByHost/com.skype.skype.*.plist'
    '${HOME}/Library/Preferences/com.skype.skypewifi.plist'
    '${HOME}/Library/Saved Application State/com.skype.skype.savedState'
    '${HOME}/Library/WebKit/com.skype.skype'
)

##############################
########## FUNCTIONS #########
##############################

##############################################
# Locates app bundle using bundle identifier
# Primary method uses mdfind, find as fallback
# Retains default assignment if no match
# Globals:
#   app_bundle_id
#   app_path
# Assigns:
#   app_path
##############################################
function override_app_path() {

    # Find via bundle ID using mdfind; sort to bring shortest path (if multiple) to top and assign
    loc_app_path=$(/usr/bin/mdfind "kMDItemCFBundleIdentifier == '${app_bundle_id}'" | /usr/bin/sort | /usr/bin/head -1)
    if [[ -z ${loc_app_path} ]]; then
        # Search /Applications for app bundle dir structures, match on BID from Info.plists and assign matching app (if any)
        info_plist_path=$(/usr/bin/find /Applications -maxdepth 4 -path "*\.app/Contents/Info.plist" -print0 -exec /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "{}" \; 2>/dev/null | /usr/bin/grep -a "${app_bundle_id}" | /usr/bin/sed -n "s/${app_bundle_id}$//p")
        # Shell built-in to lop off two sub dirs
        loc_app_path=${info_plist_path%/*/*}
    fi
    # If no matches found, assign default path
    app_path=${loc_app_path:-$app_path}
}

##############################################
# Locates and kills any active app processes
# as identified by bundle ID (via launchctl)
# or application path (via lsappinfo)
# Globals:
#   app_bundle_id
#   app_friendly_name
#   app_path
# Outputs:
#   Kills any active app processes
##############################################
function kill_app() {

    echo "Killing running processes for ${app_friendly_name}..."
    # Locate active launch procs under user context, bootout if found
    /bin/launchctl print ${app_bundle_id:l} 2>&1  | /usr/bin/grep gui | /usr/bin/xargs -I {} /bin/launchctl bootout "{}"
    # Kill by app path
    /usr/bin/lsappinfo info $(/usr/bin/lsappinfo find bundlepath=${app_path}) -only pid | /usr/bin/cut -d '=' -f2 | /usr/bin/xargs kill -9
}

##############################################
# Assigns list of users with UID ≥500, and
# iterates over them to assign/validate home
# directories exist; if so, iterates over
# provided array of paths to sub in user dir
# for ${HOME} and delete any matches
# Arguments:
#   Array name for iteration; "${1}"
# Outputs:
#   Prints matching paths to stdout
#   Deletes matching paths
##############################################
function user_iter_rm() {
    # Assign arr by name passed in; zsh-ism to expand array via (P)
    # NOTE: Expected value is the array name str, not the array itself
    local -a paths_arr=("${(f)$(printf "%s\n" "${(P)1[@]}")}")

    # Populate array of users from DSCL with UID ≥500
    dscl_users=($(/usr/bin/dscl /Local/Default -list /Users UniqueID | /usr/bin/awk '$2 >= 500 {print $1}'))
    for user in "${dscl_users[@]}"; do
        # Derive home directory value from DSCL attribute
        user_dir=$(/usr/bin/dscl /Local/Default -read "/Users/${user}" NFSHomeDirectory | /usr/bin/cut -d ":" -f2 | /usr/bin/xargs)

        # Confirm User dir exists
        if [[ -d "${user_dir}" ]]; then
            echo "Valid user directory at ${user_dir} for ${user}"
            # Iterate over array of the above user directories
            # If any paths are found, print match to stdout and delete them
            for dir in "${paths_arr[@]}"; do
                # ${HOME} is single quoted, so won't expand
                if grep -q '${HOME}/' <<< ${dir}; then
                    # Sub in user dir for ${HOME}
                    this_user_dir=${dir:s:${HOME}:$user_dir}
                    if [[ -e "${this_user_dir}" ]]; then
                        echo "Removing ${this_user_dir}..."
                        /bin/rm -f -R "${this_user_dir}" 2>/dev/null
                    fi
                fi
            done
        fi
    done
}

##############################################
# Removes application bundles located on-disk
# Globals:
#   app_path
#   app_bundles
# Outputs:
#   Writes detected paths to stdout
#   Removes detected paths
# Returns:
#   Exit code from last rm command
##############################################
function remove_app_bundles() {

    echo "Removing ${app_path}..."
    /bin/rm -f -R "${app_path}" 2>/dev/null

    # Multiple app bundles may exist for title
    for bundle in "${app_bundles[@]}"; do
        if [[ -d "${bundle}" ]]; then
            echo "Removing ${bundle}..."
            /bin/rm -f -R "${bundle}" 2>/dev/null
        fi
    done
}

##############################################
# Checks if bool set to delete user files
# If so, iterates over all users with UID ≥500
# Removes matching paths from their home dirs
# Globals:
#   delete_user_files
#   app_user_paths
# Returns:
#   Exit code from user_iter_rm function
##############################################
function remove_user_app_files() {
    # Only deletes user files if bool set to true
    if ${delete_user_files}; then
        # Assign arr by name passed in; zsh-ism to expand array via (P)
        # NOTE: Expected value is the array name str, not the array itself
        user_iter_rm "app_user_paths"
    fi
}

##############################################
# Main function
# Checks for existence of app path
# If missing, attempts to locate via bundle ID
# If found, attempts removal of app from Dock
# Kills any active app processes
# Removes user files if bool set to true
# Removes app bundle/ancillary files from disk
# Globals:
#   app_path
#   app_friendly_name
#   app_bundle_id
# Outputs:
#   Writes status messages to stdout
# Returns:
#   0 on successful uninstall or app not found
#   Non-zero if any uninstallation step fails
##############################################
function main() {

    # Initial check for app path as defined
    if [[ ! -d "${app_path}" ]]; then
        # If not found, attempt to locate via bundle ID
        override_app_path
    fi

    if [[ -d "${app_path}" ]]; then

        echo "Located ${app_friendly_name} installed at ${app_path}..."

        # Remove App from Dock
        /usr/local/bin/kandji dock --remove ${app_bundle_id}
        kill_app
        remove_user_app_files
        remove_app_bundles
        exit 0
    else
        echo "${app_friendly_name} not found; exiting..."
        exit 0
    fi
}

###############
##### MAIN ####
###############

main
