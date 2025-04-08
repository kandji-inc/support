#!/bin/zsh
###################################################################################################
# Created by Noah Anderson + Matt Wilson | se@kandji.io | Kandji, Inc. | Systems Engineering
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
# Designed for use as an add-on to the SAP Privileges 1.X app for macOS. Installs in two parts: a
# Launch Agent that runs a lightweight enforcement script every 30 seconds and validates console
# user permissions. If permissions are administrative, rights are revoked after a certain number
# of minutes, set either in this script below (MINUTES_TO_WAIT) or via Configuration Profile key
# (DockToggleTimeout) from a deployed SAP Privileges Configuration Profile installed on the Mac.
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
#
###################################################################################################

###################################################################################################
####################################### VARIABLES TO MODIFY #######################################
###################################################################################################

# Set to a positive integer (default 20 minutes)
# A value of 0 disables the timeout and allows the user to permanently toggle privileges
# NOTE: If updating this value with an audit/remediate workflow, update line 59 in the audit script
MINUTES_TO_WAIT=20

# Set to either True or False (default True)
# Setting this true requires the DockToggleTimeout key to be defined in the Privileges Config Profile
# (see link below for an example profile)
# https://github.com/SAP/macOS-enterprise-privileges/blob/main/application_management/example_profiles/DockToggleTimeout/Example_DockToggleTimeout.mobileconfig
# Overrides local value set above if valid int, otherwise value set above acts as fallback
# NOTE: If updating this value with an audit/remediate workflow, update line 65 in the audit script
USE_PROFILE_TIMEOUT=True

# Populate user(s) to exclude from rights revocation by shortname
# User shortnames should be enclosed in double quotes (e.g. "admin")
# To confirm the shortname to specify below, run "whoami" without quotes in Terminal
# This should be done while logged in as the account you wish to exclude and run without sudo
# You may add unlimited quote-enclosed shortnames below; delete any unused ""
# NOTE: If updating this value with an audit/remediate workflow, update line 71 in the audit script
USERS_TO_EXCLUDE=(
""
""
""
)

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

####### GLOBAL VARS - DO NOT MODIFY #######

PRIVS_CHECK_AGENT_PATH="/Library/LaunchAgents/io.kandji.privileges-checker.plist"
PRIVS_CHECK_EXEC_DIR="/Library/Scripts/MDMHelpers"
PRIVS_CHECK_EXEC_SCRIPT="privilegeschecker.zsh"

##############################################
## Writes a Launch Agent (LA), sets perms,
## converts to binary, makes immutable
## Outputs:
##   Writes LA to /Library/LaunchAgents
##############################################
function privs_agent_deploy() {

    #Try unsealing our Launch Agent - dump stderr since audit script reports on this
    /usr/bin/chflags noschg "${PRIVS_CHECK_AGENT_PATH}" 2>/dev/null
    /bin/cat >"${PRIVS_CHECK_AGENT_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>io.kandji.privileges-checker.plist</string>
        <key>LimitLoadToSessionType</key>
        <string>Aqua</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/zsh</string>
            <string>${PRIVS_CHECK_EXEC_DIR}/${PRIVS_CHECK_EXEC_SCRIPT}</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StartInterval</key>
        <integer>30</integer>
    </dict>
</plist>
EOF

    #Change ownership to root:wheel
    /usr/sbin/chown root:wheel "${PRIVS_CHECK_AGENT_PATH}"
    #Change POSIX perms to w+r/r/r
    /bin/chmod 644 "${PRIVS_CHECK_AGENT_PATH}"
    # Convert xml to binary plist
    /usr/bin/plutil -convert xml1 "${PRIVS_CHECK_AGENT_PATH}"
    #Seal it up
    /usr/bin/chflags schg "${PRIVS_CHECK_AGENT_PATH}"
}

#################################################
## Validates if console user is logged in
## If so, load Launch Agent in their space
## Returns:
##   "No user logged in" to stdout if $uid < 501
################################################
function privs_agent_load() {

    #Get logged in user info
    console_user=$(/usr/bin/stat -f%Su /dev/console)
    uid=$(/usr/bin/id -u "${console_user}")

    # Only enable the LaunchAgent if there is a user logged in, otherwise rely on built in LaunchAgent behavior
    if [[ "${uid}" -lt 501 ]]; then
        /bin/echo "No user logged in"
    else
        #Unload the agent so it can be triggered on re-install
        /bin/launchctl asuser "${uid}" /bin/launchctl unload -w "${PRIVS_CHECK_AGENT_PATH}" 2>/dev/null
        #Load the launch agent anew
        /bin/launchctl asuser "${uid}" /bin/launchctl load -w "${PRIVS_CHECK_AGENT_PATH}"
    fi
}

#########################################################
## Attempt to remove schg flag, writes script,
## sets perms, makes immutable
## Globals:
##   MINUTES_TO_WAIT: Local timeout in minutes
##   USE_PROFILE_TIMEOUT: T/F value to set profile use
## Outputs:
##   Writes execution file to /Library/Scripts/MDMHelpers
#########################################################
function privs_execute_deploy() {

    /bin/mkdir -p "${PRIVS_CHECK_EXEC_DIR}"
    privs_check_execution_script="${PRIVS_CHECK_EXEC_DIR}/${PRIVS_CHECK_EXEC_SCRIPT}"

    #Try unsealing our execution script - dump stderr since audit script reports on this
    /usr/bin/chflags noschg "${privs_check_execution_script}" 2>/dev/null

    /bin/cat >"${privs_check_execution_script}" <<EOF
#!/bin/zsh
################################################################################################
# Created by Noah Anderson + Matt Wilson | se@kandji.io | Kandji, Inc. | Systems Engineering
################################################################################################
# Created on 02/07/2022
################################################################################################
# Software Information
################################################################################################
#
# Designed for use as an add-on to the SAP Privileges app for macOS. This is an enforcement
# script which validates console user permissions. If permissions are administrative, rights are
# revoked after a certain number of minutes, set either in this script below (MINUTES_TO_WAIT)
# or via Configuration Profile key (DockToggleTimeout) from a deployed SAP Privileges
# Configuration Profile installed on the Mac.
#
################################################################################################
# License Information
################################################################################################
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
#
################################################################################################

#
#   CHANGELOG
#
#       - (1.0.1)
#           - Modified the remove_privs_function so that it can both remove or add admin privileges
#           - Updated the function name to modify_user_privileges
#       - (1.0.2)
#           - Bug fix where current user uid was unabled to be determined in some edge cases.
#           - Some additional code refactoring
#       - (1.0.3)
#           - Changed time to wait to minutes
#       - (1.0.4)
#           - Added support for Config Profile key/value pair
#           - Added script execution timeout
#           - Improved method for deriving current user
#           - Improved logging
#           - Improved security for agent and script
#       - (1.0.5)
#           - Rearchitected method of determining/enforcing rights timeout
#           - Modified method of deriving logged-in user
#           - Added version validation to audit script
#       - (1.0.6)
#           - Added script timeout validation to audit script
#           - Added script profile setting validation to audit script
#           - Added support for excluding users defined by shortname from rights revocation 
#           - Added script user exclusion validation to audit script


version=1.0.6

###################################################################################################
################################ VARIABLES ########################################################
###################################################################################################

### LOCAL CONFIG ###

# Number of minutes to wait before removing admin rights from the current user
# Set to default of 20 minutes
MINUTES_TO_WAIT=${MINUTES_TO_WAIT}

# Set T/F value on enforcing timeout in minutes from DockToggleTimeout key
USE_PROFILE_TIMEOUT="${USE_PROFILE_TIMEOUT}"

# Populated user(s) to exclude from rights revocation by shortname
# User shortnames should be enclosed in double quotes (e.g. "admin")
# Populates as an array
USERS_TO_EXCLUDE=(${USERS_TO_EXCLUDE})

EOF

    # Separate heredoc with quoted EOF to so the rest of our vars don't expand
    /bin/cat >>"${privs_check_execution_script}" <<'EOF'
###############################################
## Logs to stdout as well as Unified Log
## Arguments:
##   Takes one arg, "${1}"
## Outputs:
##   Writes to stdout and Unified log
###############################################
function LOGGING {
    /bin/echo "${1}"
	/usr/bin/logger "Privileges Checker: ${1}"
}

### MDM CONFIG - DO NOT MODIFY ###

# Validate preference domain exists
if [[ -f "/Library/Managed Preferences/corp.sap.privileges.plist" ]]; then


    # Check if a value is set for EnforcePrivileges
    privs_enforce=$(/usr/libexec/PlistBuddy -c "Print :EnforcePrivileges" "/Library/Managed Preferences/corp.sap.privileges.plist" 2>/dev/null)

    # IMPORTANT: If so, this will override our ability to manage privileges with the CLI
    if [[ "${privs_enforce}" ]]; then
            LOGGING "WARNING: Privileges are enforced with value ${privs_enforce}"
            LOGGING "WARNING: Console user cannot be managed with EnforcePrivileges key set - exiting"
            # Exit and defer to our privilege enforcement
            exit 0
    fi

    if [[ "${USE_PROFILE_TIMEOUT}" =~ [tT] ]]; then

        # Set timeout in minutes from Config Profile if DockToggleTimeout key defined
        mdm_minutes=$(/usr/libexec/PlistBuddy -c "Print :DockToggleTimeout" "/Library/Managed Preferences/corp.sap.privileges.plist" 2>/dev/null)

        # If our variable is defined, successfully read value from Config Profile plist
        if [[ "${mdm_minutes}" ]]; then
                # Assign our Config Profile value to our timeout
                MINUTES_TO_WAIT=${mdm_minutes}
        fi
    fi
fi

if [[ ! "${MINUTES_TO_WAIT}" -gt 0 ]]; then
    LOGGING "Timeout value not positive integer - exiting"
    exit 0
fi

# Path to Privileges binary
privileges_cli="/Applications/Privileges.app/Contents/Resources/PrivilegesCLI"

###################################################################################################
####################### FUNCTIONS - DO NOT MODIFY #################################################
###################################################################################################


function get_current_user() {
    # Returns the current user
    /usr/bin/stat -f%Su /dev/console
}

########################################################
## Validates the current user's UID
## Will continue to loop until UID is > 500
## Times out and exits after 5 minutes if no user found
## Globals:
##   LOGGING
########################################################
function validate_uid() {

    current_user_uid=$(/usr/bin/id -u "$(get_current_user)")

    # Initialize our timeout variable
    timeout=0

    # Set an upper bound on how long our loop runs
    # Currently set to 5 minutes
    maxtime=300

    until [[ "${current_user_uid}" -ge 501 || "${timeout}" -ge "${maxtime}"  ]]; do
        /bin/sleep 1

        let timeout++

        LOGGING "Awaiting logged in user; ${timeout}/${maxtime} seconds elapsed"

        # Get the current console user again
        current_user=$(get_current_user)

        # Get uid again
        current_user_uid=$(/usr/bin/id -u "${current_user}")

    done

    if [[ ! "${current_user_uid}" -ge 501 ]]; then
        LOGGING "Current user: ${current_user} with UID ${current_user_uid} ..."
        LOGGING "Console user never logged in... Exiting with status code 1"
        exit 1
    fi
}

##############################################
## Returns the console user's group membership
## Queries membership from Privileges CLI
## Returns:
##   $permissions, either admin or standard
###############################################
function current_privileges() {
    # Return the current logged-in users group membership.
    #
    # Returns admin if the user is a member of the local admin group. Returns standard
    # if the user is a member of the standard users group "aka not an admin."
    #
    # $1: current logged in user

    admin_check=$("${privileges_cli}" --status 2>&1 | /usr/bin/awk "/${1}/ && /admin/")

    if [[ "${admin_check}" ]]; then
        # User is in the admin group
        permissions="admin"
    else
        # User is not in the admin group
        permissions="standard"
    fi
    /usr/bin/printf "%s\n" "${permissions}"
}

##############################################
## Creates hidden file .timeout in /var/tmp
## with value of current epoch timestamp
## If .timeout already exists, checks value
## If diff between recorded value and now is
## greater than set timeout, revokes rights
## Globals:
##   LOGGING
## Arguments:
##   Takes one arg, ${1}, timeout in minutes 
## Outputs:
##   Writes .timeout_${SHORTNAME} to /var/tmp
## Returns:
##   0 if THING was deleted, non-zero on error.
###############################################
function timeout_check_revoke() {

    timeout_path="/var/tmp/.timeout_${current_user}"
    now=$(/bin/date +%s)
    # Check if .timeout hidden file exists
    if [[ ! -f "${timeout_path}" ]]; then
        LOGGING "No on-disk timeout found"
        LOGGING "Recording when rights were detected for console user ..."

        # If not, create it with current epoch timestamp
        /bin/echo "${now}" > "${timeout_path}"
    else
        # Read in our epoch timestamp
        previously=$(/bin/cat "${timeout_path}")
        # Check the delta between then and now in seconds
        diff_in_seconds=$(/bin/expr "${now}" - "${previously}")
        # Convert into minutes for our compare
        diff_in_minutes=$(/bin/expr "${diff_in_seconds}" / 60)

        if [[ "${diff_in_minutes}" -ge "${1}" ]]; then
            LOGGING "Rights have been granted for ${diff_in_minutes} minutes"
            LOGGING "This is greater than/equal to set rights timeout of ${1} minutes"

            # Remove the user from the admin group
            LOGGING "Removing ${current_user} from the admin group ..."

            # Remove the current user's privileges
            "${privileges_cli}" --remove

            privilege_status=$(current_privileges ${current_user})

            LOGGING "The current user has ${privilege_status} rights"
            LOGGING "Deleting historical record of when rights were detected ..."

            #Delete our timeout dotfile
            /bin/rm "${timeout_path}"
        else
            minutes_remaining=$(/bin/expr "${1}" - "${diff_in_minutes}")
            LOGGING "Rights will be revoked in ${minutes_remaining} minute(s)..."
        fi
    fi
}
###################################################################################################
#################### MAIN LOGIC - DO NOT MODIFY ###################################################
###################################################################################################

###############################################
## Main function - validates logged in user,
## user permissions, revokes after # of minutes
## if rights are found to be administrative
## Globals:
##   LOGGING
##   MINUTES_TO_WAIT
###############################################
function main() {
    # Run the main logic

    # Get the current console user and validate UID
    current_user=$(get_current_user)

    #Check exact match if the current user is on our exclusion list
    for UTE in ${USERS_TO_EXCLUDE[@]}; do
        if [[ $(/usr/bin/printf "${UTE}" | /usr/bin/grep -wi "${current_user}") ]]; then
            LOGGING "User ${current_user} is excluded from rights revocation"
            exit 0
        fi
    done

    validate_uid

    LOGGING "--- Start privilegeschecker log ---"
    LOGGING ""
    LOGGING "Version: ${version}"

    LOGGING "Current Console User: ${current_user} with UID ${current_user_uid}"

    # Only run if the PrivilegesCLI is installed
    if [[ -f "${privileges_cli}" ]]; then
        LOGGING "Checking the current console user's privileges ..."

        # Return privilege status
        privilege_status=$(current_privileges "${current_user}")
        LOGGING "The current user has ${privilege_status} rights"

        if [[ "${privilege_status}" = "admin" ]]; then
            # Confirm when rights were detected and revoke them if past due
            timeout_check_revoke "${MINUTES_TO_WAIT}" 
        else
            LOGGING "${current_user} is already a standard user ..."
            # If user revoked their own rights, clean up our timeout dot file if present
            if [[ -f "/var/tmp/.timeout_${current_user}" ]]; then
                /bin/rm "/var/tmp/.timeout_${current_user}"
            fi
        fi

    else
        LOGGING "The PrivilegesCLI tool is not installed ..."
        LOGGING "User privileges have not been modified ..."
    fi

    LOGGING ""
    LOGGING "--- End privilegeschecker log ---"
    LOGGING ""
}

# Run the main
main
EOF

    # Set permissions to read-only
    /bin/chmod 444 "${privs_check_execution_script}"
    # Seal it up
    /usr/bin/chflags schg "${privs_check_execution_script}"

}

#############
#####BODY####
#############

# Install enforcement script
privs_execute_deploy
# Install Launch Agent
privs_agent_deploy
# Attempt to load it
privs_agent_load
