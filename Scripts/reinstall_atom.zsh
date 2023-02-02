#!/usr/bin/env zsh

################################################################################################
# Created by Noah Anderson | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 2023-02-01 
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.2
#   13.1
#   12.6.3
#   11.7.3
#   11.7.2
#   10.15.7
#
################################################################################################
# Software Information
################################################################################################
#
# Script looks for an install of Atom with a revoked certificate (newer than minor version 60)
# If found, validates reinstall is scoped and available from Kandji (exit 1 if not)
# NOTE: Atom Auto App must be scoped for Continuous Enforcement or available in Self Service 
# Creates temporary file and writes heredoc to force reinstall Atom
# Calls script which will pause 10 seconds, run kandji library, and then self destruct + exit
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2023 Kandji, Inc.
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

############################
##########VARIABLES#########
############################

#Assign path to kandji binary for invocation
path_to_kagent="/usr/local/bin/kandji"
#Assign expected path to Atom Info.plist
path_to_atom_info="/Applications/Atom.app/Contents/Info.plist"
#Get full and minor versions of Atom
atom_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${path_to_atom_info}" 2>/dev/null)
atom_minor=$(/usr/bin/cut -d "." -f2 <<< "${atom_version}")

############################
##########FUNCTIONS#########
############################

##############################################
# Conducts prechecks to validate if Atom is
# 1. Installed
# 2. Newer than minor version 60
# 3. Eligible for reinstall via Kandji
# Returns:
#   exit 0 if Atom not installed
#   exit 0 if Atom installed and valid version
#   exit 1 if Atom requires reinstall but Mac 
#   does not have Atom scoped to execute
##############################################
function prechecks() {

    if [[ ! -f "${path_to_atom_info}" ]]; then
        echo "Atom is not installed... exiting"
        exit 0
    fi

    #Is Atom newer than minor v. 60?
    if [[ ${atom_minor} -gt 60 ]]; then
        echo "Identified Atom version ${atom_version} with revoked certificate"
    else
        echo "Installed version of Atom unaffected by cert revocation"
        exit 0
    fi

    #Confirm Atom install is in-scope for this Mac
    atom_check=$("${path_to_kagent}" library --list | /usr/bin/grep "Atom")

    if [[ ! "${atom_check}" ]]; then
        echo "Atom version has expired certificate, but Auto App not scoped for install"
        echo "Exiting with error"
        exit 1
    fi
}

##############################################
# Generates a temporary file using mktemp
# Writes a heredoc to above temp file
# Contents of file are to sleep 10 and then
# run kandji library to force install Atom
# Kandji library is sent to bg & disowned
# Temp file deletes itself and exits 0
# Outputs:
#   Creates and writes heredoc to temp file
##############################################
function create_tmp_exec() {

    #Create temp file for execution
    tmp_file=$(/usr/bin/mktemp)

    #Write out heredoc to temp location created above
    /bin/cat > "${tmp_file}" <<EOF
    #!/bin/zsh
    sleep 10

    "${path_to_kagent}" library --item "Atom" -F & disown
EOF
    /bin/cat >> "${tmp_file}" <<"EOF"

    #Self-destruct this script
    /bin/rm "${0}"

    exit 0
EOF

}

##############################################
# Invokes zsh run of temp file created in 
# func create_tmp_exec
# Script execution gets stdin from/redirects
# to /dev/null in bg to allow parallel 
# execution without hanging the kandji binary
# Outputs:
#   Reinstalls Atom after 10 second delay
##############################################
function kandji_self_call() {

    echo "Triggering force reinstall of Atom..."

    #Redirecting stderr/out to /dev/null and bg'ing the proc that calls our script
    #This allows the kandji agent to end its run without waiting for our script exec
    #We also provide stdin from /dev/null as well, allowing us to detach from any active TTY connections 
    #Also serves to inform our program any input is not coming from a terminal session
    /bin/zsh "${tmp_file}" < /dev/null > /dev/null 2>&1 &
}

##############################################
# Main invocation of reinstall_atom
# Returns:
#   exit 0 if successful, non-zero on error
##############################################
function main() {

    prechecks

    create_tmp_exec

    kandji_self_call

    exit 0
}

#############
#####MAIN####
#############
main
