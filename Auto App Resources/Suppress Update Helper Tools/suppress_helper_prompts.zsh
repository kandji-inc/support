#!/bin/zsh
###################################################################################################
# Software Information
###################################################################################################
#
# Suppress App Update Helper Prompts
# Created 04/17/26; NRJA, @captam3rica
#
# Description:
#
#   Prevents apps using helper tools from prompting users to install an update
#   helper tool.
#
#   One authorization right is modified in the macOS authorization database:
#
#   com.apple.ServiceManagement.daemons.modify (SMAppService path, macOS 13+)
#      Default rule: is-root OR entitled-admin-or-authenticate-admin-nonshared
#      Modified rule: is-root only
#      Root processes (mdmclient, Iru daemon) continue to work unchanged.
#      Update helper tool prompts are silently denied without
#      any credential prompt, because the authenticate fallback rule is removed.
#
#   This modification targets the layer that triggers the SecurityAgent
#   builtin:authenticate dialog, suppressing it for the user.
#
#   To revert to system default:
#       right="com.apple.ServiceManagement.daemons.modify"; \
#       /usr/libexec/PlistBuddy -x -c "Print :rights:${right}" /System/Library/Security/authorization.plist | \
#       sudo security authorizationdb write ${right}
#
###################################################################################################
# License Information
###################################################################################################
#
# Copyright 2026 Iru, Inc.
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

##############################
########## VARIABLES #########
##############################

readonly DAEMONS_MODIFY_RIGHT="com.apple.ServiceManagement.daemons.modify"
readonly LOG_PREFIX="[suppress_update_prompts]"

##############################
########## FUNCTIONS #########
##############################

##############################################
# Prints a timestamped log message.
# Arguments:
#   Message string
# Outputs:
#   Prints to stdout.
##############################################
function log() {
    echo "$(date +'%r'): ${LOG_PREFIX} ${1}"
}

##############################################
# Restricts com.apple.ServiceManagement.
# daemons.modify to root-only by removing
# the authenticate-admin fallback sub-rule.
# Root processes (mdmclient, Iru daemon) are unaffected.
# Non-root user processes are silently denied.
# Arguments:
#   None
# Outputs:
#   Prints result to stdout.
##############################################
function restrict_daemons_modify_right() {
    local plist
    plist=$(
        cat <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>class</key>
    <string>rule</string>
    <key>comment</key>
    <string>Managed by Iru: restricted to root-only (is-root sub-rule). Removes entitled-admin-or-authenticate-admin-nonshared to prevent update helpers from triggering a credential prompt via SMAppService. Root processes (mdmclient, Iru daemon) are unaffected. Revert to the Apple default: right="com.apple.ServiceManagement.daemons.modify"; /usr/libexec/PlistBuddy -x -c "Print :rights:${right}" /System/Library/Security/authorization.plist | sudo security authorizationdb write ${right}</string>
    <key>k-of-n</key>
    <integer>1</integer>
    <key>rule</key>
    <array>
        <string>is-root</string>
    </array>
    <key>version</key>
    <integer>1</integer>
</dict>
</plist>
PLIST
    )

    log "Writing root-only rule for ${DAEMONS_MODIFY_RIGHT}..."
    if /usr/bin/security authorizationdb write "${DAEMONS_MODIFY_RIGHT}" <<<"${plist}" &>/dev/null; then
        log "Set ${DAEMONS_MODIFY_RIGHT} to \"is-root\" only."
    else
        log "ERROR: Failed to write ${DAEMONS_MODIFY_RIGHT}. Verify this script is running as root."
        exit 1
    fi
}

##############################################
# Checks whether daemons.modify is already
# restricted to is-root only.
# Arguments:
#   None
# Outputs:
#   Returns 0 if already restricted, 1 if not.
##############################################
function daemons_modify_is_restricted() {
    local plist_output first_rule
    if ! plist_output=$(/usr/bin/security authorizationdb read "${DAEMONS_MODIFY_RIGHT}" 2>/dev/null); then
        return 1
    fi

    if ! first_rule=$(/usr/bin/plutil -extract 'rule.0' raw -o - - 2>/dev/null <<<"${plist_output}"); then
        return 1
    fi

    # Use exit code to detect rule.1 presence: 0 = exists (multiple rules), non-zero = only one rule.
    # &>/dev/null suppresses both the extracted value and plutil's error diagnostics (sent to stdout).
    [[ "${first_rule}" == "is-root" ]] && ! /usr/bin/plutil -extract 'rule.1' raw -o /dev/null - &>/dev/null <<<"${plist_output}"
}

##############################################
# Verifies daemons.modify rule array contains
# only is-root (authenticate fallback removed).
# Arguments:
#   None
# Outputs:
#   Prints result to stdout.
##############################################
function verify_daemons_modify() {
    local plist_output
    if ! plist_output=$(/usr/bin/security authorizationdb read "${DAEMONS_MODIFY_RIGHT}" 2>/dev/null); then
        log "ERROR: Failed to read ${DAEMONS_MODIFY_RIGHT} from authorization database."
        exit 1
    fi

    local first_rule
    if ! first_rule=$(/usr/bin/plutil -extract 'rule.0' raw -o - - <<<"${plist_output}"); then
        log "ERROR: Failed to extract rule from ${DAEMONS_MODIFY_RIGHT}."
        exit 1
    fi

    # Verify rule.0 is is-root and rule.1 does not exist.
    # &>/dev/null suppresses both the extracted value and plutil's error diagnostics (sent to stdout).
    if [[ "${first_rule}" == "is-root" ]] &&
        ! /usr/bin/plutil -extract 'rule.1' raw -o /dev/null - &>/dev/null <<<"${plist_output}"; then
        log "Verified: ${DAEMONS_MODIFY_RIGHT} rule is \"is-root\" only."
    else
        log "WARNING: ${DAEMONS_MODIFY_RIGHT} rule did not verify as expected (first_rule is '${first_rule}')."
        exit 1
    fi
}

##############################################
# Main function.
# Arguments:
#   None
# Outputs:
#   Runs main logic.
##############################################
function main() {
    if daemons_modify_is_restricted; then
        log "${DAEMONS_MODIFY_RIGHT} already restricted to \"is-root\" only. No changes needed."
    else
        restrict_daemons_modify_right
        verify_daemons_modify
    fi
    log "Done."
}

###############
##### MAIN ####
###############
main
