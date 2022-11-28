#!/usr/bin/env zsh

#
#   Audit script to detect the presence of Homebrew.
#
#   This script is designed to exit with a 1 if Homebrew is not found so that a remediation
#   script can be called to install homebrew on the target system. Used by itself, this
#   script will generate an Alert that Hombrew is not installed.
#

# Check brew insall status.
brew_path="$(/usr/bin/find /usr/local/bin /opt -maxdepth 3 -name brew 2>/dev/null)"

if [[ -n $brew_path   ]]; then
    # If the brew binary is found just run brew update and exit
    /bin/echo "Homebrew already installed at $brew_path ..."
    /bin/echo "Done ..."
    exit 0

else
    /bin/echo "Homebrew is not installed ..."
    exit 1
fi
