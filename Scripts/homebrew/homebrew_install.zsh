#!/usr/bin/env zsh

################################################################################################
# Created by Nicholas McDonald | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created on 2020-08-10
#   Previous contributions on 2023-03-28 - Matt Wilson
#   Last Updated on 2026-09-28 - Joe Borner and Corey Willis
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
#   Adapted in part from homebrew-3.3.sh by Tony Williams.
#   https://github.com/Honestpuck/homebrew.sh/blob/master/homebrew-3.3.sh
#
#   Installs the latest stable Homebrew. See README.md in this folder.
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
# CHANGELOG
################################################################################################
#
#   1.7.0
#       - Install the latest stable Homebrew release instead of the frozen master branch
#       - Use the signed Homebrew package for a Mac with Apple silicon and macOS 15 or later
#       - Use a stable Git checkout for an Intel-based Mac and an older Mac with Apple silicon
#       - Keep an existing installation in place and update it as its current owner
#       - Repair an existing installation that has no Git repository
#       - Run brew as the owning user instead of as root
#       - Check the package signature, owner, and permissions
#       - Remove the automatic Rosetta installation because Homebrew runs natively
#       - Add brew to PATH with /etc/paths.d/homebrew
#
#   1.5.2
#       - Updated Command Line Tools for Xcode install logic to also check for any available
#         updates via Software Update, and install those if the latest available version is
#         newer than the installed version.
#
#   1.5.1
#       - Updated logic when adding and validating that brew is in the current user's PATH.
#
#   1.5.0
#       - Moved logic for the Command Line Tools for Xcode install check up in the script
#         to account for scenarios on a Mac with Apple silicon where the tools require
#         reinstallation when upgrading from one macOS version to the next.
#
################################################################################################

autoload is-at-least
setopt PIPE_FAIL

# Script version
VERSION="1.7.0"
# Signed Homebrew package requires macOS 15.
PKG_MACOS_MAJOR="15"
# Current Homebrew requires macOS Big Sur 11 or later.
HOMEBREW_MINIMUM_MACOS_MAJOR="11"
HOMEBREW_PKG_URL="https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg"
HOMEBREW_GIT_REMOTE="https://github.com/Homebrew/brew"
PKG_USER_PLIST="/var/tmp/.homebrew_pkg_user.plist"
CLI_TOOLS_GIT="/Library/Developer/CommandLineTools/usr/bin/git"
CLI_TOOLS_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Logging config
LOG_NAME="homebrew_install.log"
LOG_DIR="/Library/Logs"
LOG_PATH="$LOG_DIR/$LOG_NAME"
WORKDIR=""

########################################################################################
############################ FUNCTIONS - DO NOT MODIFY BELOW ###########################
########################################################################################

# shellcheck disable=SC2329 # Invoked by the EXIT trap.
cleanup() {
    if [[ -n "$WORKDIR" && -d "$WORKDIR" ]]; then
        /bin/rm -rf "$WORKDIR"
    fi

    /bin/rm -f "$PKG_USER_PLIST"
    /bin/rm -f "$CLI_TOOLS_PLACEHOLDER"
}

fail() {
    logging "error" "$1"
    exit 1
}

logging() {
    local log_level log_statement prefix
    log_level="$(printf "%s" "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')"
    log_statement="$2"
    prefix="$(/bin/date +"[%b %d, %Y %Z %T $log_level]:")"

    printf "%s %s\n" "$prefix" "$log_statement" | /usr/bin/tee -a "$LOG_PATH" || true
}

run_logged() {
    # Run a command, send its output to the log, and return its status.
    if ! "$@" 2>&1 | /usr/bin/tee -a "$LOG_PATH"; then
        return 1
    fi
}

lookup_owner_home() {
    local owner="$1"
    local found
    if [[ "$owner" == "$cached_home_owner" && -n "$cached_home_path" ]]; then
        return 0
    fi

    found="$(/usr/bin/dscl . -read "/Users/${owner}" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
    if [[ -z "$found" ]]; then
        return 1
    fi

    cached_home_owner="$owner"
    cached_home_path="$found"
}

run_as_owner() {
    local owner="$1"
    shift
    lookup_owner_home "$owner" || return 1

    /usr/bin/sudo -u "$owner" -H -- /usr/bin/env -i \
        HOME="$cached_home_path" \
        USER="$owner" \
        LOGNAME="$owner" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        "$@"
}

run_git_as_owner() {
    local owner="$1"
    local repository="$2"
    local git_path="$3"
    shift 3
    run_as_owner "$owner" /usr/bin/env GIT_CONFIG_GLOBAL=/dev/null \
        "$git_path" -C "$repository" -c core.hooksPath=/dev/null "$@"
}

retry() {
    local attempts="$1"
    local pause=2
    shift

    local attempt=1
    while (( attempt <= attempts )); do
        if "$@"; then
            return 0
        fi

        if (( attempt == attempts )); then
            return 1
        fi

        logging "warning" "Retrying in ${pause} seconds..."
        /bin/sleep "$pause"
        pause=$((pause * 2))
        attempt=$((attempt + 1))
    done
}

require_root() {
    if [[ "$(/usr/bin/id -u)" != "0" ]]; then
        fail "Run this script as root."
    fi
}

check_macos() {
    local product_version major
    product_version="$(/usr/bin/sw_vers -productVersion)"
    major="${product_version%%.*}"

    if [[ ! "$major" =~ ^[0-9]+$ ]] || (( major < HOMEBREW_MINIMUM_MACOS_MAJOR )); then
        fail "Current Homebrew requires a Mac with macOS Big Sur 11 or later. This Mac has ${product_version:-an unknown version} installed."
    fi

    macos_major="$major"
    logging "info" "macOS ${product_version}"
}

set_architecture() {
    # hw.optional.arm64 reports the Mac's native CPU even when this process is
    # running under Rosetta. uname alone would choose the Intel prefix in that case.
    local apple_silicon
    apple_silicon="$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null || true)"

    if [[ "$apple_silicon" == "1" || "$(/usr/bin/uname -m)" == "arm64" ]]; then
        architecture="arm64"
        brew_prefix="/opt/homebrew"
    elif [[ "$(/usr/bin/uname -m)" == "x86_64" ]]; then
        architecture="x86_64"
        brew_prefix="/usr/local"
    else
        logging "info" "Processor architecture: $(/usr/bin/uname -m)"
        exit 1
    fi

    brew_bin="${brew_prefix}/bin/brew"
    logging "info" "Processor architecture: ${architecture}"
    logging "info" "Homebrew prefix: ${brew_prefix}"
}

select_current_user() {
    local candidate uid fallback_users
    current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" |
        /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' |
        /usr/bin/awk -F '@' '{print $1}')

    if [[ -z "$current_user" ]]; then
        logging "info" "No user is logged in. Selecting the most common local user."
        fallback_users="$(/usr/sbin/ac -p | /usr/bin/sort -nrk 2 | /usr/bin/grep -E -v "total|admin|root|mbsetup|adobe" || true)"
        current_user=""
        while read -r candidate _; do
            [[ -z "$candidate" ]] && continue
            uid="$(/usr/bin/id -u "$candidate" 2>/dev/null || true)"
            if [[ "$uid" =~ ^[0-9]+$ ]] && (( uid >= 501 )); then
                current_user="$candidate"
                break
            fi
        done <<< "$fallback_users"
    fi

    if [[ -z "$current_user" ]] || ! /usr/bin/dscl . -read "/Users/${current_user}" >/dev/null 2>&1; then
        fail "No local user was found to own Homebrew."
    fi

    if [[ " $(/usr/bin/id -Gn "$current_user") " == *" admin "* ]]; then
        current_group="admin"
    else
        current_group="$(/usr/bin/id -gn "$current_user")"
    fi

    logging "info" "Local user: ${current_user}"
}

resolve_existing_brew() {
    local brew_directory target_directory linked_brew
    brew_repository=""
    brew_owner=""
    linked_brew=0

    # An older install keeps brew in Homebrew/bin and may be missing the bin/brew link.
    if [[ ! -x "$brew_bin" && -x "${brew_prefix}/Homebrew/bin/brew" ]]; then
        if [[ -e "$brew_bin" && ! -L "$brew_bin" ]]; then
            return 1
        fi
        /bin/mkdir -p "${brew_prefix}/bin" || fail "Could not create ${brew_prefix}/bin."
        /bin/ln -sfn ../Homebrew/bin/brew "$brew_bin" || fail "Could not link ${brew_bin}."
        linked_brew=1
    fi

    if [[ ! -f "$brew_bin" || ! -x "$brew_bin" ]]; then
        return 1
    fi

    brew_directory="$(/usr/bin/dirname "$brew_bin")"

    if [[ -L "$brew_bin" ]]; then
        target_directory="$(/usr/bin/dirname "$(/usr/bin/readlink "$brew_bin")")"
        brew_repository="$(cd "$brew_directory" && cd "$target_directory/.." && /bin/pwd -P)"
    else
        brew_repository="$(cd "$brew_directory/.." && /bin/pwd -P)"
    fi

    if [[ ! -e "${brew_repository}/bin/brew" ]]; then
        fail "Could not find the Homebrew repository for ${brew_bin}."
    fi

    case "$brew_repository" in
        /opt/homebrew | /opt/homebrew/Homebrew | /usr/local/Homebrew) ;;
        *) fail "Homebrew at ${brew_repository} is not in a supported location." ;;
    esac

    brew_owner="$(/usr/bin/stat -f %Su "$brew_repository")"
    if [[ "$brew_owner" == "root" ]]; then
        fail "Homebrew at ${brew_repository} is owned by root and cannot be updated."
    fi
    if [[ "$linked_brew" -eq 1 ]]; then
        /usr/sbin/chown -h "${brew_owner}:$(/usr/bin/id -gn "$brew_owner")" "$brew_bin" ||
            fail "Could not set the owner of ${brew_bin}."
    fi

    logging "info" "Homebrew at ${brew_bin} is owned by ${brew_owner}."
    return 0
}

usable_git() {
    local candidate developer_dir
    local -a candidates

    candidates=("$CLI_TOOLS_GIT")
    developer_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    if [[ -n "$developer_dir" && "$developer_dir" != "/" ]]; then
        candidates+=("${developer_dir}/usr/bin/git")
    fi

    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" && "$candidate" != "/usr/bin/git" ]]; then
            printf "%s\n" "$candidate"
            return 0
        fi
    done

    return 1
}

# A selected developer directory is usable when it contains Git or clang.
# Command Line Tools keep clang in usr/bin. Xcode keeps it in the toolchain.
# Do not call xcrun here. xcrun opens the Command Line Tools prompt when the
# selected directory is missing.
developer_dir_is_usable() {
    local developer_dir="$1"
    [[ -n "$developer_dir" && "$developer_dir" != "/" ]] || return 1
    [[ -x "${developer_dir}/usr/bin/git" || -x "${developer_dir}/usr/bin/clang" || -x "${developer_dir}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" ]]
}

developer_dir_is_xcode() {
    local developer_dir="$1"
    developer_dir_is_usable "$developer_dir" || return 1
    [[ "$developer_dir" != "/Library/Developer/CommandLineTools" ]] || return 1
    [[ -x "${developer_dir}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" || "$developer_dir" == *.app/Contents/Developer ]]
}

cli_tools_label() {
    /usr/bin/awk '
        /[Bb]eta/ { next }
        /Label: Command Line Tools/ { sub(/^.*Label: /, ""); print }
        /\* Command Line Tools/ && $0 !~ /Label:/ { sub(/^ *\* */, ""); print }
    ' | /usr/bin/sort -V | /usr/bin/tail -n 1
}

install_cli_label() {
    local label="$1"
    local previous_dir
    previous_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    logging "info" "Installing ${label}..."
    /usr/bin/touch "$CLI_TOOLS_PLACEHOLDER"
    if ! run_logged /usr/sbin/softwareupdate --install "$label" --verbose; then
        fail "Could not install ${label}."
    fi
    if developer_dir_is_xcode "$previous_dir"; then
        logging "info" "Left the selected Xcode developer directory unchanged."
        return 0
    fi
    if ! /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools; then
        fail "Could not select the Command Line Tools for Xcode."
    fi
}

check_xcode_license() {
    local output xcode_path
    xcode_path="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    if ! developer_dir_is_xcode "$xcode_path"; then
        return 0
    fi

    if ! output="$(/usr/bin/xcrun clang 2>&1)" && [[ "$output" == *"license"* ]]; then
        fail "The Xcode license has not been accepted. Run xcodebuild -license."
    fi
}

# brew runs xcrun whenever a developer directory is selected. That opens the
# Command Line Tools prompt when the tools are not actually installed.
# shellcheck disable=SC2329 # Invoked by run_brew.
clear_incomplete_command_line_tools() {
    local developer_dir
    developer_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    if developer_dir_is_usable "$developer_dir"; then
        return 0
    fi

    if [[ -L /Library/Developer/CommandLineTools ]]; then
        /bin/rm -f /Library/Developer/CommandLineTools
    elif [[ -d /Library/Developer/CommandLineTools && ! -x /Library/Developer/CommandLineTools/usr/bin/clang ]]; then
        /bin/rm -rf /Library/Developer/CommandLineTools
    fi
    /usr/bin/xcode-select --reset >/dev/null 2>&1 || true
}

xcode_cli_tools() {
    local required="$1"
    local label installed available have_git scan scan_error update_message
    local scan_failed=0
    # softwareupdate omits the Command Line Tools until this file exists.
    /usr/bin/touch "$CLI_TOOLS_PLACEHOLDER" || fail "Could not prepare the Command Line Tools install."
    logging "info" "Checking Software Update for the Command Line Tools for Xcode..."
    if ! scan="$(/usr/sbin/softwareupdate --list 2>&1)"; then
        scan_failed=1
        scan_error="$(printf "%s\n" "$scan" | /usr/bin/tail -n 1)"
        update_message="Software Update could not be checked."
        if [[ -n "$scan_error" ]]; then
            update_message="Software Update could not be checked. ${scan_error}"
        fi
    else
        label="$(printf "%s\n" "$scan" | cli_tools_label)"
    fi
    installed="$(/usr/sbin/pkgutil --pkg-info com.apple.pkg.CLTools_Executables 2>/dev/null |
        /usr/bin/awk '/version:/ {print $2}')"
    available="${label##*-}"
    if usable_git >/dev/null; then
        have_git=1
    fi

    if [[ -n "$have_git" && -n "$installed" ]]; then
        if [[ "$scan_failed" -eq 0 && "$available" =~ ^[0-9]+(\.[0-9]+)+$ ]] && ! is-at-least "$available" "$installed"; then
            install_cli_label "$label"
        elif [[ "$scan_failed" -eq 1 ]]; then
            logging "warning" "$update_message"
            logging "info" "Command Line Tools for Xcode ${installed} are already installed."
        else
            logging "info" "Command Line Tools for Xcode ${installed} are already installed."
        fi
    elif [[ -z "$have_git" ]]; then
        if [[ -z "$label" ]]; then
            /bin/rm -f "$CLI_TOOLS_PLACEHOLDER"
            if [[ "$scan_failed" -eq 1 ]]; then
                if [[ "$required" == "required" ]]; then
                    fail "$update_message"
                fi
                logging "warning" "$update_message"
                return 0
            fi
            [[ "$required" == "required" ]] || return 0
            fail "Command Line Tools for Xcode are required, and no installer was found."
        fi
        install_cli_label "$label"
    fi

    /bin/rm -f "$CLI_TOOLS_PLACEHOLDER"
    git_bin="$(usable_git || true)"
    if [[ -z "$git_bin" && "$required" == "required" ]]; then
        fail "Git from the Command Line Tools for Xcode was not found."
    fi
    check_xcode_license
}

download_file() {
    local url="$1"
    local destination="$2"
    retry 5 /usr/bin/curl --fail --silent --show-error --location \
        --proto '=https' --proto-redir '=https' \
        --connect-timeout 30 --max-time 900 \
        --output "$destination" "$url"
}

prepare_pkg_user_plist() {
    local owner_mode lines staged
    # Build the plist in the private temp directory. chown and chmod in
    # world-writable /var/tmp would follow a symlink planted by another user.
    staged="${WORKDIR}/homebrew_pkg_user.plist"
    /bin/rm -f "$staged" || fail "Could not remove ${staged}."
    /usr/bin/defaults write "${staged%.plist}" HOMEBREW_PKG_USER "$current_user" ||
        fail "Could not set the Homebrew package user."
    /usr/sbin/chown root:wheel "$staged" || fail "Could not set the owner of ${staged}."
    /bin/chmod 600 "$staged" || fail "Could not set the permissions on ${staged}."
    /bin/chmod -N "$staged" 2>/dev/null || true

    if [[ -L "$staged" || ! -f "$staged" ]]; then
        fail "Could not create ${staged}."
    fi

    owner_mode="$(/usr/bin/stat -f '%Su %Sg %Lp' "$staged" 2>/dev/null || true)"
    lines="$(/bin/ls -led "$staged" 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
    if [[ "$owner_mode" != "root wheel 600" || "$lines" != "1" ]]; then
        fail "Could not set the required permissions on ${staged}."
    fi

    # rename replaces a symlink at the required path without following it.
    /bin/mv -f "$staged" "$PKG_USER_PLIST" || fail "Could not publish ${PKG_USER_PLIST}."
    if [[ -L "$PKG_USER_PLIST" || ! -f "$PKG_USER_PLIST" ]]; then
        fail "Could not create ${PKG_USER_PLIST}."
    fi
}

install_apple_silicon() {
    local package signature prefix_owner
    package="${WORKDIR}/Homebrew.pkg"

    logging "info" "Downloading the latest stable Homebrew package..."
    if ! download_file "$HOMEBREW_PKG_URL" "$package"; then
        fail "Could not download the Homebrew package."
    fi

    logging "info" "Checking the Homebrew package signature..."
    if ! signature="$(/usr/sbin/pkgutil --check-signature "$package" 2>&1)"; then
        fail "The Homebrew package signature check failed."
    fi
    printf "%s\n" "$signature" >>"$LOG_PATH"
    if [[ "$signature" != *"Developer ID Installer: "*"(927JGANW46)"* ]]; then
        fail "The Homebrew package is not signed by Homebrew."
    fi
    if ! /usr/sbin/spctl --assess --type install "$package"; then
        fail "The Homebrew package did not pass the Gatekeeper check."
    fi

    logging "info" "Setting the package installation user to ${current_user}..."
    prepare_pkg_user_plist

    logging "info" "Installing Homebrew..."
    if ! run_logged /usr/sbin/installer -pkg "$package" -target /; then
        fail "The Homebrew package installation failed."
    fi

    prefix_owner="$(/usr/bin/stat -f %Su /opt/homebrew 2>/dev/null || true)"
    if [[ "$prefix_owner" != "$current_user" ]]; then
        fail "Homebrew is owned by ${prefix_owner:-an unknown user}, not ${current_user}."
    fi

    /bin/rm -f "$PKG_USER_PLIST"
}

provision_homebrew_directories() {
    local directory mode path
    local -a directories
    directories=(
        bin etc include lib sbin share opt var
        Frameworks
        etc/bash_completion.d lib/pkgconfig
        share/aclocal share/doc share/info share/locale share/man
        share/man/man1 share/man/man2 share/man/man3 share/man/man4
        share/man/man5 share/man/man6 share/man/man7 share/man/man8
        share/zsh share/zsh/site-functions
        var/log var/homebrew var/homebrew/linked
        Cellar Caskroom
    )

    if [[ "$architecture" != "arm64" ]]; then
        directories+=(Homebrew)
    fi

    if [[ "$current_group" == "staff" ]]; then
        mode="755"
    else
        mode="775"
    fi

    if [[ -L "$brew_prefix" ]]; then
        fail "${brew_prefix} is a symlink."
    fi

    logging "info" "Preparing ${brew_prefix} for ${current_user}..."
    if [[ "$architecture" == "arm64" ]]; then
        if ! /usr/bin/install -d -o "$current_user" -g "$current_group" -m "$mode" "$brew_prefix"; then
            fail "Could not create ${brew_prefix}."
        fi
    fi

    for directory in "${directories[@]}"; do
        path="${brew_prefix}/${directory}"
        if [[ -L "$path" ]]; then
            fail "${path} is a symlink."
        fi
        if ! /usr/bin/install -d -o "$current_user" -g "$current_group" -m "$mode" "$path"; then
            fail "Could not create ${path}."
        fi
    done

    if ! /bin/chmod go-w "${brew_prefix}/share/zsh" "${brew_prefix}/share/zsh/site-functions"; then
        fail "Could not set the permissions on ${brew_prefix}/share/zsh."
    fi
}

# A non-admin account is usually in staff. Group write would let another local user replace bin/brew.
remove_group_write() {
    local owner="$1"
    shift
    if [[ " $(/usr/bin/id -Gn "$owner") " == *" admin "* || "$(/usr/bin/id -gn "$owner")" != "staff" ]]; then
        return 0
    fi
    /bin/chmod -R go-w "$@"
}

remove_stale_master() {
    local owner="$1"
    local repository="$2"
    if [[ -z "$git_bin" ]]; then
        logging "warning" "Git from the Command Line Tools for Xcode was not found. Leaving Git refs unchanged."
        return 0
    fi
    if ! run_git_as_owner "$owner" "$repository" "$git_bin" show-ref --verify --quiet refs/remotes/origin/master; then
        return 0
    fi

    logging "info" "Removing stale origin/master..."
    run_git_as_owner "$owner" "$repository" "$git_bin" update-ref -d refs/remotes/origin/master ||
        fail "Could not remove stale origin/master."
}

setup_git_repository() {
    local owner="$1"
    local repository="$2"
    local latest_tag

    git_repo() {
        run_git_as_owner "$owner" "$repository" "$git_bin" "$@"
    }

    logging "info" "Downloading the latest stable Homebrew release..."
    git_repo -c init.defaultBranch=main init --quiet || fail "Could not create the Homebrew Git repository."
    if ! git_repo config remote.origin.url "$HOMEBREW_GIT_REMOTE" ||
        ! git_repo config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" ||
        ! git_repo config --bool fetch.prune true ||
        ! git_repo config --bool core.autocrlf false ||
        ! git_repo config --bool core.symlinks true; then
        fail "Could not configure the Homebrew Git repository."
    fi

    retry 5 git_repo fetch --quiet --force origin || fail "Could not download Homebrew."
    retry 5 git_repo fetch --quiet --force --tags origin || fail "Could not download Homebrew release tags."
    remove_stale_master "$owner" "$repository"
    git_repo remote set-head origin --auto || true

    latest_tag="$(git_repo -c column.ui=never tag --list --sort=-version:refname |
        /usr/bin/grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | /usr/bin/head -n 1 || true)"
    if [[ -z "$latest_tag" ]]; then
        fail "Could not determine the latest Homebrew release."
    fi

    logging "info" "Checking out Homebrew ${latest_tag}..."
    git_repo checkout --quiet --force -B stable "$latest_tag" || fail "Could not check out Homebrew ${latest_tag}."
    remove_group_write "$owner" "$repository" || fail "Could not remove group write from ${repository}."

    if [[ -d "${repository}/share/zsh" ]]; then
        /bin/chmod go-w "${repository}/share/zsh" "${repository}/share/zsh/site-functions" ||
            fail "Could not set the permissions on ${repository}/share/zsh."
    fi
    unfunction git_repo
}

install_from_git() {
    xcode_cli_tools required
    if [[ "$architecture" == "arm64" ]]; then
        brew_repository="$brew_prefix"
    else
        brew_repository="${brew_prefix}/Homebrew"
    fi

    provision_homebrew_directories
    setup_git_repository "$current_user" "$brew_repository"

    if [[ "$architecture" != "arm64" ]]; then
        if ! /bin/ln -sfn ../Homebrew/bin/brew "$brew_bin"; then
            fail "Could not link ${brew_bin}."
        fi
        if ! /usr/sbin/chown -h "${current_user}:${current_group}" "$brew_bin"; then
            fail "Could not set the owner of ${brew_bin}."
        fi
    fi
}

# shellcheck disable=SC2329 # Invoked by run_logged.
run_brew() {
    local brew_path="${brew_prefix}/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    local git_path="$git_bin"
    local -a brew_env

    # /usr/bin/git is an xcrun stub. Point brew at a real git, or at the git it
    # is about to install, so it never executes that stub.
    if [[ -z "$git_path" || ! -x "$git_path" ]]; then
        git_path="$(usable_git || true)"
    fi
    if [[ -z "$git_path" ]]; then
        git_path="${brew_prefix}/opt/git/bin/git"
    fi
    git_bin="$git_path"

    clear_incomplete_command_line_tools
    brew_env=(
        HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT=1
        HOMEBREW_NO_ENV_HINTS=1
        NONINTERACTIVE=1
        HOMEBREW_GIT_PATH="$git_path"
        PATH="$brew_path"
    )
    run_as_owner "$brew_owner" /usr/bin/env "${brew_env[@]}" "$brew_bin" "$@"
}

prepare_homebrew_cache() {
    local cache cache_owner
    lookup_owner_home "$brew_owner" || fail "Could not find the home folder for ${brew_owner}."
    cache="${cached_home_path}/Library/Caches/Homebrew"
    if [[ -L "${cached_home_path}/Library/Caches" || -L "$cache" ]]; then
        fail "${cache} is a symlink."
    fi
    if [[ ! -d "$cache" ]] && ! run_as_owner "$brew_owner" /bin/mkdir -p "$cache"; then
        /bin/mkdir -p "$cache" || fail "Could not create ${cache}."
    fi
    cache_owner="$(/usr/bin/stat -f %Su "$cache" 2>/dev/null || true)"
    if [[ "$cache_owner" != "$brew_owner" ]]; then
        /usr/sbin/chown -R "$brew_owner" "$cache" || fail "Could not set the owner of ${cache}."
    fi
    remove_group_write "$brew_owner" "$cache" || fail "Could not remove group write from ${cache}."
}

update_homebrew() {
    logging "info" "Updating Homebrew..."
    prepare_homebrew_cache
    if [[ -z "$git_bin" ]]; then
        git_bin="$(usable_git || true)"
    fi
    if [[ -z "$git_bin" && -x "${brew_prefix}/opt/git/bin/git" ]]; then
        git_bin="${brew_prefix}/opt/git/bin/git"
    fi
    if [[ -z "$git_bin" ]]; then
        xcode_cli_tools
    fi
    if [[ -d "${brew_repository}/.git" ]]; then
        remove_stale_master "$brew_owner" "$brew_repository"
    fi
    run_logged run_brew update --force || return 1
    # Record the release tag now that Git is available. Later brew --version
    # reads this instead of reporting a shallow repository.
    run_logged run_brew --version || true
}

configure_path() {
    local path_file expected
    # /usr/local/bin is already on the default macOS PATH.
    if [[ "$brew_prefix" != "/opt/homebrew" ]]; then
        return 0
    fi

    path_file="/etc/paths.d/homebrew"
    expected="${brew_prefix}/bin"

    if [[ -L "$path_file" ]]; then
        fail "${path_file} is a symlink."
    fi
    if ! /bin/mkdir -p /etc/paths.d; then
        fail "Could not create /etc/paths.d."
    fi
    if ! printf "%s\n" "$expected" >"$path_file"; then
        fail "Could not write ${path_file}."
    fi
    if ! /usr/sbin/chown root:wheel "$path_file"; then
        fail "Could not set the owner of ${path_file}."
    fi
    if ! /bin/chmod 644 "$path_file"; then
        fail "Could not set the permissions on ${path_file}."
    fi
    logging "info" "Added ${expected} to ${path_file}."
}

brew_doctor() {
    local developer_dir
    developer_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    # brew doctor runs xcrun, which opens the Command Line Tools prompt when
    # the tools are not installed.
    if ! developer_dir_is_usable "$developer_dir"; then
        logging "info" "Skipped brew doctor. No Xcode developer directory is selected, and brew doctor opens the install prompt."
        return 0
    fi

    logging "info" "Running brew doctor..."
    if ! run_logged run_brew doctor; then
        logging "warning" "brew doctor reported a problem."
    fi
}

refuse_homebrew_install() {
    local reason
    if [[ ! -f /etc/homebrew/brew.no_install ]]; then
        return 0
    fi

    reason="$(/bin/cat /etc/homebrew/brew.no_install 2>/dev/null || true)"
    if [[ -n "$reason" ]]; then
        fail "Homebrew cannot be installed because ${reason}."
    fi
    fail "Homebrew cannot be installed because /etc/homebrew/brew.no_install exists."
}

########################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##########################
########################################################################################

trap cleanup EXIT
require_root
WORKDIR="$(/usr/bin/mktemp -d /tmp/homebrew-install.XXXXXX)" || fail "Could not create a temporary directory."

logging "info" "--- Start homebrew install log ---"
logging "info" "Script version: ${VERSION}"
/bin/echo "Log file at ${LOG_PATH}"

check_macos
set_architecture
select_current_user

if resolve_existing_brew; then
    if [[ ! -d "${brew_repository}/.git" ]]; then
        logging "info" "Existing Homebrew has no Git repository. Repairing it..."
        xcode_cli_tools required
        setup_git_repository "$brew_owner" "$brew_repository"
    fi
else
    refuse_homebrew_install
    if [[ "$architecture" == "arm64" ]] && (( macos_major >= PKG_MACOS_MAJOR )); then
        install_apple_silicon
    else
        install_from_git
    fi

    if ! resolve_existing_brew; then
        fail "Homebrew was not found at ${brew_bin} after installation."
    fi
fi

if ! update_homebrew; then
    fail "Homebrew update failed."
fi

configure_path
brew_doctor

if [[ "$brew_prefix" == "/opt/homebrew" ]]; then
    logging "info" "Open shells must be restarted before brew is on PATH. brew is at ${brew_bin}."
else
    logging "info" "brew is at ${brew_bin}."
fi
logging "info" "--- End homebrew install log ---"
exit 0
