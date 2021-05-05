#!/bin/bash

######################################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Solutions Engineering
######################################################################################################
# Created on 08/10/2020 updated on 05/04/2021
######################################################################################################
# Software Information
######################################################################################################
# WARNING:
# Installing Homebrew as root is not supported using the official installation method. 
# Running or Installing Homebrew as root is dangerous and is not officially supported.
# 
# Modified portions of AutoBrew are used heavily in this script.
# Original credit for AutoBrew goes to Kenny Botelho
# https://github.com/kennyb-222/AutoBrew/blob/main/AutoBrew.sh
#
# This script silently installs homebrew as the most common local user.
# This script can be set to "every 15 minutes" or "daily" to ensure homebrew remains installed
######################################################################################################
# License Information
######################################################################################################
# Copyright 2020 Kandji, Inc. 
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

mostCommonUser=$(/usr/bin/last -t console | /usr/bin/awk '!/_mbsetupuser|root|wtmp/' | /usr/bin/cut -d" " -f1 | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/head -n1 | /usr/bin/grep -o '[a-zA-Z].*')

if [ -e "/usr/local/bin/brew" ]; then 
	echo "Brew is already installed..."
	exit 0
else 
	echo "Brew is not yet installed..."
fi

if [ "${mostCommonUser}" = "" ]; then
	echo "There is no common user other than root or _mbsetupuser... try again later"
	exit 0
fi

echo "${mostCommonUser} is the most common console user... installing homebrew as this user"

# Set environment variables
HOME="$(mktemp -d)"
export HOME
export USER=root
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
BREW_INSTALL_LOG=$(mktemp)

# Verify the TargetUser is valid
if /usr/bin/dscl . -read "/Users/${mostCommonUser}" 2>&1 >/dev/null; then
	/bin/echo "Validated ${mostCommonUser}"
else
	/bin/echo "Specified user \"${mostCommonUser}\" is invalid"
	exit 1
fi

#Determine the processor brand
processorBrand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

if [[ "${processorBrand}" = *"Apple"* ]]; then
	echo "Apple Processor is present..."
	#Check if the Rosetta service is running
	checkRosettaStatus=$(/bin/launchctl list | /usr/bin/grep "com.apple.oahd-root-helper")
	
	if [[ "${checkRosettaStatus}" != "" ]]; then
		echo "Rosetta is installed... no action needed"
	else
		echo "Rosetta is not installed... installing now"
		#Installs Rosetta
		/usr/sbin/softwareupdate --install-rosetta --agree-to-license
		
		#Checks the outcome of the Rosetta install
		if [[ $? -eq 0 ]]; then
			echo "Rosetta installed..."
		else
			echo "Rosetta install failed..."
			exit 1
		fi
	fi
else
	echo "Apple Processor is not present... rosetta not needed"
fi


# Install Homebrew | strip out all interactive prompts
/bin/bash -c "$(curl -fsSL \
	https://raw.githubusercontent.com/Homebrew/install/master/install.sh | \
	sed "s/abort \"Don't run this as root\!\"/\
	echo \"WARNING: Running as root...\"/" | \
	sed 's/  wait_for_user/  :/')" 2>&1 | tee "${BREW_INSTALL_LOG}"

# Reset Homebrew permissions for target user
brew_file_paths=$(/usr/bin/sed '1,/==> This script will install:/d;/==> /,$d' \
	"${BREW_INSTALL_LOG}")
brew_dir_paths=$(/usr/bin/sed '1,/==> The following new directories/d;/==> /,$d' \
	"${BREW_INSTALL_LOG}")
# Get the paths for the installed brew binary
brew_bin=$(echo "${brew_file_paths}" | grep "/bin/brew")
brew_bin_path=${brew_bin%/brew}
# shellcheck disable=SC2086
/usr/sbin/chown -R "${mostCommonUser}":admin ${brew_file_paths} ${brew_dir_paths}
/usr/bin/chgrp admin ${brew_bin_path}/
/bin/chmod g+w ${brew_bin_path}

# Unset home/user environment variables
unset HOME
unset USER

# Finish up Homebrew install as target user
/usr/bin/su - "${mostCommonUser}" -c "${brew_bin} update --force"

# Run cleanup before checking in with the doctor
/usr/bin/su - "${mostCommonUser}" -c "${brew_bin} cleanup"

# Check for missing PATH
get_path_cmd=$(/usr/bin/su - "${mostCommonUser}" -c "${brew_bin} doctor 2>&1 | /usr/bin/grep 'export PATH=' | /usr/bin/tail -1")

# Add Homebrew's "bin" to target user PATH
if [ -n "${get_path_cmd}" ]; then
	/usr/bin/su - "${mostCommonUser}" -c "${get_path_cmd}"
fi

# Check Homebrew install status, check with the doctor status to see if everything looks good
if /usr/bin/su - "${mostCommonUser}" -i -c "${brew_bin} doctor"; then
	echo 'Homebrew Installation Complete! Your system is ready to brew.'
	exit 0
else
	echo 'Homebrew Installation Failed'
	exit 1
fi