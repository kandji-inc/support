#!/usr/bin/env zsh

################################################################################################
# Created by Kandji, Inc. | support@kandji.io
################################################################################################
#
#   Last Updated on 2026-09-28 - Corey Willis
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - macOS Golden Gate 27
#   - macOS Tahoe 26
#   - macOS Sequoia 15
#
################################################################################################
# Software Information
################################################################################################
#
#   Checks whether Homebrew is installed and reports the installed version. Set PASS_WHEN
#   below based on your needs:
#   "installed" if you want a Pass status when Homebrew is installed, or "not_installed"
#   if you want a Pass status when Homebrew is not installed. With "installed", Homebrew
#   must also report its version. Any other result is Error, which generates an alert and
#   runs the Remediation Script if one is added.
#   See README.md in this folder.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Kandji, Inc.
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

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Pass when Homebrew is installed, or when it is not installed.
PASS_WHEN="installed" # installed, not_installed

########################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##########################
########################################################################################

homebrew_paths=(
    /opt/homebrew/bin/brew
    /opt/homebrew/Homebrew/bin/brew
    /usr/local/bin/brew
    /usr/local/Homebrew/bin/brew
)

found_brew=""
homebrew_version=""
for brew_path in "${homebrew_paths[@]}"; do
    if [[ -f "$brew_path" && -x "$brew_path" ]]; then
        found_brew="$brew_path"
        break
    fi
done

if [[ -n "$found_brew" ]]; then
    if [[ "$found_brew" == /opt/homebrew/* ]]; then
        brew_prefix="/opt/homebrew"
    else
        brew_prefix="/usr/local"
    fi

    git_path="${brew_prefix}/opt/git/bin/git"
    [[ -x "$git_path" ]] || git_path="/Library/Developer/CommandLineTools/usr/bin/git"
    if [[ ! -x "$git_path" ]]; then
        dev_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
        if [[ -n "$dev_dir" && "$dev_dir" != "/" ]]; then
            git_path="${dev_dir}/usr/bin/git"
        fi
    fi
    if [[ -x "$git_path" && "$git_path" != "/usr/bin/git" ]]; then
        # brew and its Git are owned by the Homebrew user. Do not execute them as root.
        brew_owner="$(/usr/bin/stat -L -f %Su "$found_brew" 2>/dev/null || true)"
        if [[ -n "$brew_owner" && "$brew_owner" != "root" ]]; then
            if [[ "$(/usr/bin/id -u)" == "0" ]]; then
                owner_home="$(/usr/bin/dscl . -read "/Users/${brew_owner}" NFSHomeDirectory 2>/dev/null |
                    /usr/bin/awk '{print $2}')"
                if [[ -n "$owner_home" && -d "$owner_home" ]]; then
                    homebrew_version="$(/usr/bin/sudo -u "$brew_owner" -H -- /usr/bin/env -i \
                        HOME="$owner_home" \
                        USER="$brew_owner" \
                        LOGNAME="$brew_owner" \
                        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
                        HOMEBREW_GIT_PATH="$git_path" \
                        "$found_brew" --version 2>/dev/null | /usr/bin/head -n 1)"
                fi
            else
                homebrew_version="$(HOMEBREW_GIT_PATH="$git_path" "$found_brew" --version 2>/dev/null |
                    /usr/bin/head -n 1)"
            fi
            homebrew_version="${homebrew_version#Homebrew }"
        fi
    fi
    # Without Git, brew reports ">=4.3.0 (shallow or no git repository)".
    if [[ ! "$homebrew_version" =~ ^[0-9]+\.[0-9]+ ]]; then
        homebrew_version=""
    fi
fi

# Accept "Not Installed", "not-installed", and similar.
pass_when="${PASS_WHEN:l}"
pass_when="${pass_when//[ -]/_}"

if [[ "$pass_when" == "installed" ]]; then
    if [[ -n "$found_brew" && -n "$homebrew_version" ]]; then
        /bin/echo "Homebrew ${homebrew_version} is installed at ${found_brew}. This is the desired outcome."
        exit 0
    elif [[ -n "$found_brew" ]]; then
        /bin/echo "Homebrew is installed at ${found_brew}, but its version could not be read. Homebrew needs Git to report its version and to update."
        exit 1
    fi
    /bin/echo "Homebrew is not installed. It should be installed."
    exit 1
elif [[ "$pass_when" == "not_installed" ]]; then
    if [[ -n "$found_brew" ]]; then
        if [[ -n "$homebrew_version" ]]; then
            /bin/echo "Homebrew ${homebrew_version} is installed at ${found_brew}. It should not be installed."
        else
            /bin/echo "Homebrew is installed at ${found_brew}. It should not be installed."
        fi
        exit 1
    fi
    /bin/echo "Homebrew is not installed."
    exit 0
fi

/bin/echo "Set PASS_WHEN to installed or not_installed."
exit 1
