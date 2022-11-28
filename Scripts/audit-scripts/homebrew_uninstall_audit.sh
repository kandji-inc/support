#!/bin/zsh

#
# Audit script to detect the presence of Homebrew. This script is designed to exit with
# a 1 if Homebrew is found so that a remediation script can be called to uninstall homebrew from
# the target system. Used by itself, this script will generate an Alert that Hombrew is installed.
#

# Search for brew on the system
# Searches both the intel and apple silicon common paths for brew binary
echo "Looking for brew binary ..."
brew_path="$(/usr/bin/find /usr/local/bin /opt -maxdepth 3 -name brew 2>/dev/null)"

# Verify that Homebew is on the system. If found the script will exit with a 1 to initiate a remediation script to remove Homebrew from the system.
if [[ -n "$brew_path" ]]; then
    # If brew found on intel
    echo "Homebrew installed at $brew_path ..."
    exit 1
else
    echo "Homebrew is not installed ..."
    exit 0
fi
