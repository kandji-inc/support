#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 06/24/2024
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Custom script to assign Configuration ID to TeamViewer Host install via Kandji
# NOTE: Configuration ID (config_id) must be defined below by user prior to runtime
# Script first confirms user-defined Configuration ID is set
# Checks for existing TeamView Host install; if not, creates placeholder entry to assign ID
# Once assigned, script triggers Kandji to install TeamViewer Host Auto App if not yet installed
# If TeamViewer Host is already installed, script relaunches GUI TeamViewer Host processes
# NOTE: If not yet installed, ensure Auto App 'TeamViewer Host' is first scoped to Kandji devices 
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

##############################
########## VARIABLES #########
##############################

###################################################################################################
###################################### USER DEFINED VARIABLE ######################################
###################################################################################################

# Configuration ID to assign to TeamViewer Host
# See below KB article for how to generate/obtain Host Configuration ID
# https://teamviewer.com/en-us/global/support/knowledge-base/teamviewer-classic/modules/custom-host
config_id=""

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

kandji_bin="/usr/local/bin/kandji"
tv_host_path="/Applications/TeamViewerHost.app"
tv_host_aa_name="TeamViewer Host"
bundle_id_prefix="com.teamviewer"

##############################
########## FUNCTIONS #########
##############################

##############################################
# Checks if Configuration ID is provided; if 
# not, alerts with error and exit 1
# If not prefaced with 'idc', adds it
# Globals:
#   config_id
# Assigns:
#   config_id
# Returns:
#   Exit 1 if no Config ID defined
##############################################
function check_format_config_id() {
    
    if [[ -z ${config_id} ]]; then
        echo "ERROR: No Configuration ID provided!"
        echo "Exiting..."
        exit 1
    fi

    # Preface config_id with 'idc' if not present
    if ! /usr/bin/grep -q "^idc" <<< ${config_id}; then
        config_id="idc${config_id}"
    fi
}

##############################################
# Checks if TeamViewer Host is installed; if
# not, creates placeholder entry for xattr
# to write Configuration ID and sets global
# var tv_host_installed to false; else sets
# to true if TeamViewer Host already installed
# Globals:
#  tv_host_path
#  tv_host_installed
# Outputs:
#   Placeholder dir for TV Host app if missing
# Assigns:
#   tv_host_installed (bool)
##############################################
function check_create_tv_host() {

    if [[ ! -d "${tv_host_path}" ]]; then
        echo "Creating placeholder entry for TeamViewer Host"
        /bin/mkdir -p "${tv_host_path}"
        tv_host_installed=false
    else
        echo "TeamViewer Host already installed"
        tv_host_installed=true
    fi
}

##############################################
# Runs xattr to write Configuration ID to
# TeamViewer Host (real or placeholder)
# If unsuccessful, exits with error
# Outputs:
#   Writes Config ID extended attr to TV Host
##############################################
function write_config() {

    echo "Writing Configuration ID to TeamViewer Host..."
    /usr/bin/xattr -w com.TeamViewer.ConfigurationId "${config_id}" "${tv_host_path}"

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to write Configuration ID to TeamViewer Host!"
        echo "Exiting..."
        exit 1
    fi
}

##############################################
# Invokes Kandji binary to trigger install of
# TV Host; gets stdin from and redirects
# to /dev/null in bg to allow parallel
# execution without hanging Kandji binary
# Outputs:
#   Triggers TeamViewer Host install to disk
##############################################
function kandji_self_call() {

    echo "Triggering Auto App install of ${tv_host_aa_name}..."

    # Redirecting stderr/out to /dev/null and bg'ing the Kandji proc
    # This allows the agent to end its run without waiting for our script exec
    # We also provide stdin from /dev/null as well, allowing us to detach from any active TTY connections
    # Serves to inform our program any input will not be coming from a terminal session
    "${kandji_bin}" library --item "${tv_host_aa_name}" -F < /dev/null > /dev/null 2>&1 &
}

##############################################
# Checks if TeamViewer Host is installed; if
# so, relaunches GUI procs; if not, triggers
# Kandji library run to install TV Host
# Globals:
#   bundle_id_prefix
#   kandji_bin
#   tv_host_installed
#   tv_host_aa_name
# Outputs:
#   Relaunches TV Host GUI if installed
#   Installs TV Host if not installed
# Returns:
#   kandji_self_call if TV Host not installed
#   Exit 1 if TV Host not scoped to Mac
##############################################
function relaunch_or_install() {

    # Check if installed (true/false)
    if ${tv_host_installed}; then
        # If so, relaunch TeamViewer GUI procs
        /bin/launchctl print ${bundle_id_prefix} 2>&1  | /usr/bin/grep gui | /usr/bin/xargs -I {} /bin/launchctl kickstart -k "{}"
    else
        # Validate Kandji library item is scoped to Mac
        kandji_lib_items=$(${kandji_bin} library --list)
        if [[ -z $(/usr/bin/grep -o "${tv_host_aa_name}" <<< "${kandji_lib_items}") ]]; then
            echo "${tv_host_aa_name} not scoped to Mac! Cannot complete install..."
            exit 1
        fi
        # Once confirmed, trigger Kandji library run to install TV Host
        kandji_self_call
    fi
}

##############################################
# Main function to handle script execution
# Validates appropriate run permissions (sudo)
# Confirms defined Config ID and existing TV
# Host install; assigns Config ID to TV Host
# and either relaunches or installs fresh
# Globals:
#  EUID
# Returns:
#  Exit 0 on successful completion
#  Exit 1 if non-root exec or other error 
##############################################
function main() {
    # Check invocation perms
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Script must be run with sudo or as root"
        exit 1
    fi

    # Confirm Configuration ID is provided
    check_format_config_id

    # Check if TeamViewer Host is installed
    # If not, create placeholder entry for xattr
    check_create_tv_host

    # Write Configuration ID to TeamViewer Host
    write_config
    
    # Relaunch TeamViewer GUI if already installed
    # Otherwise trigger Kandji library install of Auto App
    relaunch_or_install

    exit 0
}

###############
##### MAIN ####
###############
main
