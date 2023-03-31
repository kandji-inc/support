#!/usr/bin/env zsh

################################################################################################
# Created by Nicholas McDonald | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created on 2020-08-10
#   Last Updated on 2023-03-28 - Matt Wilson
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - 13.3
#   - 12.6
#   - 11.7.1
#   - 10.15.7
#
################################################################################################
# Software Information
################################################################################################
#
#   Inspiration for portions of this script taken from homebrew-3.3.sh.
#   Original credit to Tony Williams (Honestpuck)
#   https://github.com/Honestpuck/homebrew.sh/blob/master/homebrew-3.3.sh
#
#   This script silently installs Homebrew as the most common local user.
#   This script can be set to "every 15 minutes" or "daily" to ensure Homebrew remains
#   installed.
#
#   NOTE: This script is designed to added brew to the current user's PATH, but if a user has
#   pre-existing CLI sessions open, the brew command may not be recognized. The user will need
#   to relaunch their sessions (ex - zsh -l) or start a new session so that brew is seen in
#   their PATH.
#
#   For the latest on brew Apple Silicon compatibility,
#   see: https://github.com/Homebrew/brew/issues/7857
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
# CHANGELOG
################################################################################################
#
#   1.2.0
#       - Added check for Apple Silicon homebrew binary location
#
#   1.3.0
#       - Code refactor
#           - Moved Rosetta2 check to a function
#           - Added additional comments for clarification
#           - Changed how permissions and ownership are set for brew and dependencies
#           - Change how brew doctor is interpreted and let admin know to check logs
#             for more info. Apple Silicon has a warning showing that brew is not
#             installed at /usr/local and might have unexpected behavior some app
#             installs that have not been updated for Apple Silicon.
#       - Added separate permissions and ownership logic for brew installed on Apple
#         Silicon
#       - Added local logging to /Library/Logs/homebrew_install.log
#       - Added check for Xcode CLI tools and will install them if not present
#       - Added support for homebrew install as a standard user.
#
#   1.3.1
#       - Added logic to determine most common user if a logged-in user is not found.
#       - Added additional logic to validate OS versions for Xcode CLI tools
#         compatibility
#
#   1.4.0
#       - Refactored brew install process so that the curl command is only downloading
#         the latest brew tarball file to the correct location
#       - Added function that creates the brew environment
#       - General code refactor
#       - Added additional logging output
#
#   1.4.1
#       - Minor refactor and bug squashing
#
#   1.4.2
#       - Added -a flag to tee binary to ensure that the local log file is appended to
#         and not overwritten. (credit - Glen Arrowsmith)
#       - Added additional logging
#       - updated latest tested OS versions
#
#   1.4.3
#       - Updated logging to note where brew is not able to be called from a CLI
# session that is already in progress. Workaround was to close all CLI
#         sessions and then launch a new session.
#       - Added logic to update the user's PATH in either .zshrc or .bashrc with path
#         to the brew binary.
#
#   1.4.4
#       - Grammar fixes and updates :P
#
#   1.5.0
#       - Moved logic for xcode install check up in the script to account for scenarios
#         on Apple Silicon where cli tools require reinstalation when upgrading from
#         one macOS version to the next.
#
#   1.5.1
#       - Updated logic when adding and validating that brew is in the current user's PATH.
#
#   1.5.2
#       - Updated Xcode CLI tools install logic to also check for any avaialble updates via
#         software update, and install those if the latest available version is newer that the
#         installed version.
#
################################################################################################

# Used when comparing installed CLI tools versus latest available via softwareupate
autoload is-at-least

# Script version
VERSION="1.5.2"

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Logging config
LOG_NAME="homebrew_install.log"
LOG_DIR="/Library/Logs"
LOG_PATH="$LOG_DIR/$LOG_NAME"

########################################################################################
############################ FUNCTIONS - DO NOT MODIFY BELOW ###########################
########################################################################################

logging() {
    # Logging function
    #
    # Takes in a log level and log string and logs to /Library/Logs/$script_name if a
    # LOG_PATH constant variable is not found. Will set the log level to INFO if the
    # first built-in $1 is passed as an empty string.
    #
    # Args:
    #   $1: Log level. Examples "info", "warning", "debug", "error"
    #   $2: Log statement in string format
    #
    # Examples:
    #   logging "" "Your info log statement here ..."
    #   logging "warning" "Your warning log statement here ..."
    log_level=$(printf "%s" "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    script_name="$(/usr/bin/basename "$0")"
    prefix=$(/bin/date +"[%b %d, %Y %Z %T $log_level]:")

    # see if a LOG_PATH has been set
    if [[ -z "${LOG_PATH}" ]]; then
        LOG_PATH="/Library/Logs/${script_name}"
    fi

    if [[ -z $log_level ]]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [[ -z $log_statement ]]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    # echo the same log statement to stdout
    /bin/echo "$prefix $log_statement"

    # send log statement to log file
    printf "%s %s\n" "$prefix" "$log_statement" >>"$LOG_PATH"

}

check_brew_install_status() {
    # Check brew install status.
    brew_path="$(/usr/bin/find /usr/local/bin /opt -maxdepth 3 -name brew 2>/dev/null)"

    if [[ -n $brew_path ]]; then
        # If the brew binary is found, just run brew update and exit
        logging "info" "Homebrew already installed at $brew_path..."

        logging "info" "Updating homebrew ..."
        /usr/bin/su - "$current_user" -c "$brew_path update --force" |
            /usr/bin/tee -a "${LOG_PATH}"

        logging "info" "Done ..."
        exit 0

    else
        logging "info" "Homebrew is not installed..."
    fi
}

rosetta2_check() {
    # Check for and install Rosetta2 if needed.
    # $1: processor_brand

    # Determine the processor brand
    if [[ "$1" == *"Apple"* ]]; then
        logging "info" "Apple Processor is present..."

        # Check if the Rosetta service is running
        check_rosetta_status=$(/usr/bin/pgrep oahd)

        # Rosetta Folder location
        # Condition check to see if the Rosetta folder exists. This check was added
        # because the Rosetta2 service is already running in macOS versions 11.5 and
        # greater without Rosseta2 actually being installed.
        rosetta_folder="/Library/Apple/usr/share/rosetta"

        if [[ -n $check_rosetta_status ]] && [[ -e $rosetta_folder ]]; then
            logging "info" "Rosetta2 is installed... no action needed"

        else
            logging "info" "Rosetta is not installed... installing now"

            # Installs Rosetta
            /usr/sbin/softwareupdate --install-rosetta --agree-to-license |
                /usr/bin/tee -a "${LOG_PATH}"
        fi

    else
        logging "info" "Apple Processor is not present...Rosetta2 is not needed"
    fi
}

get_available_cli_tool_installs() {
    # Return the latest available CLI tools.

    # Get the OS build year
    build_year=$(/usr/bin/sw_vers -buildVersion | cut -c 1,2)

    if [[ "$build_year" -ge 19 ]]; then
        # for Catalina or newer
        cmd_line_tools=$(/usr/sbin/softwareupdate --list |
            /usr/bin/awk '/\*\ Label: Command Line Tools/ { $1=$1;print }' |
            /usr/bin/sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' |
            /usr/bin/cut -c 9- | /usr/bin/grep -vi beta | /usr/bin/sort -n)

    else
        # For Mojave or older
        cmd_line_tools=$(/usr/sbin/softwareupdate --list |
            /usr/bin/awk '/\*\ Command Line Tools/ { $1=$1;print }' |
            /usr/bin/grep -i "macOS" |
            /usr/bin/sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | /usr/bin/cut -c 2-)
    fi

    # return rsponse from softwareupdate reguarding CLI tools.
    /bin/echo "$cmd_line_tools"
}

xcode_cli_tools() {
    # Check for and install Xcode CLI tools

    # Trick softwareupdate into giving us everything it knows about Xcode CLI tools by
    # touching the following file to /tmp
    xclt_tmp="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    /usr/bin/touch "$xclt_tmp"

    # Run xcrun command to check for a valid Xcode CLI tools path
    /usr/bin/xcrun --version >/dev/null 2>&1

    # shellcheck disable=SC2181
    if [[ "$?" -eq 0 ]]; then
        logging "" "Valid Xcode CLI tools path found."

        # current bundleid for CLI tools
        bundle_id="com.apple.pkg.CLTools_Executables"

        if /usr/sbin/pkgutil --pkgs="$bundle_id" >/dev/null; then
            # If the CLI tools pkg bundle is found, get the version

            installed_version=$(/usr/sbin/pkgutil --pkg-info="$bundle_id" |
                /usr/bin/awk '/version:/ {print $2}' |
                /usr/bin/awk -F "." '{print $1"."$2}')

            logging "" "Installed CLI tools version is \"$installed_version\""

        else
            logging "" "Unable to determine installed CLI tools version from \"$bundle_id\"."
        fi

        logging "" "Checking to see if there are any available CLI tool updates..."

        # Get the latest available CLI tools
        cmd_line_tools=("$(get_available_cli_tool_installs)")

    else
        logging "" "Valid Xcode CLI tools path was not found ..."
        logging "" "Getting the latest Xcode CLI tools available for install..."

        # Get the latest available CLI tools
        cmd_line_tools=("$(get_available_cli_tool_installs)")

    fi

    # if something is returned from the cli tools check
    # shellcheck disable=SC2128
    if [[ -n $cmd_line_tools ]]; then
        logging "" "Available Xcode CLI tools found: "
        logging "" "$cmd_line_tools"

        if (($(/usr/bin/grep -c . <<<"${cmd_line_tools}") > 1)); then
            cmd_line_tools_output="${cmd_line_tools}"
            cmd_line_tools=$(/bin/echo "${cmd_line_tools_output}" | /usr/bin/tail -1)

            # get version number of the latest CLI tools installer.
            lastest_available_version=$(/bin/echo "${cmd_line_tools_output}" | /usr/bin/tail -1 | /usr/bin/awk -F "-" '{print $2}')
        fi

        if [[ -n $installed_version ]]; then
            # If an installed CLI tools version is returned

            # compare latest version to installed version using is-at-least
            version_check="$(is-at-least "$lastest_available_version" "$installed_version" &&
                /bin/echo "greater than or equal to" || /bin/echo "less than")"

            if [[ $version_check == *"less"* ]]; then
                # if the installed version is less than available
                logging "" "Updating $cmd_line_tools..."
                /usr/sbin/softwareupdate --install "${cmd_line_tools}" --verbose

            else
                # if the installed version is greater than or equal to latest available
                logging "" "Installed version \"$installed_version\" is $version_check the latest available version \"$lastest_available_version\". No upgrade needed."
            fi

        else
            logging "" "Installing $cmd_line_tools..."
            /usr/sbin/softwareupdate --install "${cmd_line_tools}" --verbose
        fi

    else
        logging "warning" "Hmmmmmm...unabled to return any available CLI tools..."
        logging "warning" "May need to validate the softwareupdate command used."
    fi

    logging "Cleaning up $xclt_tmp ..."
    /bin/rm "${xclt_tmp}"
}

set_brew_prefix() {
    # Set the homebrew prefix.
    # Set the brew prefix to either the Apple Silicon location or the Intel location based on the
    # processor_brand information
    #
    # $1: proccessor brand information
    local brew_prefix

    if [[ $1 == *"Apple"* ]]; then
        # set brew prefix for apple silicon
        brew_prefix="/opt/homebrew"
    else
        # set brew prefix for Intel
        brew_prefix="/usr/local"
    fi

    # return the brew_prefix
    /bin/echo "$brew_prefix"
}

create_brew_environment() {
    # Create the brew environment.
    # Create the directories needed by brew, set the ownership, and set permissions.
    # $1: brew_prefix
    # $2: current_user
    logging "info" "Creating directories required by brew ..."
    /bin/mkdir -p "${1}/Caskroom" "${1}/Cellar" "${1}/Frameworks" "${1}/Homebrew" "${1}/bin" "${1}/etc" "${1}/include" "${1}/lib" "${1}/opt" "${1}/sbin" "${1}/man/man1" "${1}/share/doc" "${1}/share/man/man1" "${1}/share/zsh/site-functions" "${1}/var" "${1}/var/homebrew/linked"

    logging "info" "Creating symlink to ${1}/bin/brew ..."
    /bin/ln -s "${1}/Homebrew/bin/brew" "${1}/bin/brew"

    logging "info" "Setting homebrew ownership to $2 ..."
    /usr/sbin/chown -R "$2" "${1}/Cellar" "${1}/Caskroom" "${1}/Frameworks" "${1}/Homebrew" "${1}/bin" "${1}/bin/brew" "${1}/etc" "${1}/include" "${1}/lib" "${1}/man" "${1}/opt" "${1}/sbin" "${1}/share" "${1}/var"

    logging "info" "Setting permissions for brew directories and files ..."
    /bin/chmod -R 755 "${1}/Homebrew" "${1}/Cellar" "${1}/Caskroom" "${1}/Frameworks" "${1}/bin" "${1}/bin/brew" "${1}/etc" "${1}/include" "${1}/lib" "${1}/man" "${1}/opt" "${1}/sbin" "${1}/share" "${1}/var"

}

update_path() {
    # Add brew to current user PATH
    # Check for missing PATH
    get_path_cmd=$(/usr/bin/su - "$current_user" -c "$brew_prefix/bin/brew doctor 2>&1 | /usr/bin/grep 'export PATH=' | /usr/bin/tail -1")

    # Checking to see if the output returned from get_path_cmd contains the word homebrew and
    # also checking to see if brew is actually in the current user's path by runing the which
    # command.
    if echo "$get_path_cmd" | grep "homebrew" >/dev/null 2>&1 && ! /usr/bin/which brew >/dev/null 2>&1; then

        # get the shell dot rc file returned from the get_path_cmd command so that we know
        # which shell the current user is using.
        shell_rc_file=$(echo "$get_path_cmd" | awk '{print $5}' | awk -F '/' '{print $2}')

        # Check the user's shell rc file to see if homebrew has already been added to the
        # user's PATH. If we find it in there already then there is no reason to write to that
        # file again.
        if ! /usr/bin/grep "$brew_prefix/bin" "/Users/$current_user/$shell_rc_file" >/dev/null 2>&1; then
            echo "Adding brew to user's PATH..."
            echo "Using command: $get_path_cmd"
            /usr/bin/su - "$current_user" -c "${get_path_cmd}"

        else
            echo "brew path $brew_prefix/bin already in user's $shell_rc_file..."
        fi

    else
        logging "info" "brew already in user's PATH..."
    fi
}

brew_doctor() {
    # Check Homebrew install status
    #
    # if on Apple Silicon, you may see the following output from brew doctor
    #
    # Please note that these warnings are just used to help the Homebrew maintainers
    # with debugging if you file an issue. If everything you use Homebrew for is
    # working fine: please don't worry or file an issue; just ignore this. Thanks!
    #
    # Warning: Your Homebrew's prefix is not /usr/local.
    # Some of Homebrew's bottles (binary packages) can only be used with the default
    # prefix (/usr/local).
    # You will encounter build failures with some formulae.
    # Please create pull requests instead of asking for help on Homebrew's GitHub,
    # Twitter or any other official channels. You are responsible for resolving
    # any issues you experience while you are running this
    # unsupported configuration.
    #
    # $1: brew_prefix
    # $2: current_user

    /usr/bin/su - "$2" -c "$1/bin/brew doctor" 2>&1 | /usr/bin/tee -a "${LOG_PATH}"
    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logging "error" "brew doctor has errors. Review logs to see if action needs to be taken ..."
    else
        logging "info" "Homebrew installation complete! Your system is ready to brew."
    fi
}

########################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW ##########################
########################################################################################

# Do not modify the below, there be dragons. Modify at your own risk.

logging "info" "--- Start homebrew install log ---"
logging "info" "Script verion: $VERSION"
/bin/echo "Log file at /Library/Logs/homebrew_install.log"

# Get the processor brand information
processor_brand="$(/usr/sbin/sysctl -n machdep.cpu.brand_string)"

# Get the current logged in user excluding loginwindow, _mbsetupuser, and root
current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" |
    /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' |
    /usr/bin/awk -F '@' '{print $1}')

# Make sure that we can find the most recent logged-in user
if [[ $current_user == "" ]]; then
    logging "info" "Current user not logged in ..."
    logging "info" "Attempting to determine the most common user..."

    # Because someone other than the current user was returned, we are going to look at
    # who uses this Mac the most, then set the current user to that user.
    current_user=$(/usr/sbin/ac -p | /usr/bin/sort -nk 2 |
        /usr/bin/grep -E -v "total|admin|root|mbsetup|adobe" | /usr/bin/tail -1 |
        /usr/bin/xargs | /usr/bin/cut -d " " -f1)
fi

logging "info" "Most common user: $current_user"

# Verify the current_user is valid
if /usr/bin/dscl . -read "/Users/$current_user" >/dev/null 2>&1; then
    logging "info" "$current_user is a valid user ..."

else
    logging "error" "Specified user \"$current_user\" is invalid"
    exit 1

fi

logging "info" "Checking to see if Xcode cli tools are needed ..."
xcode_cli_tools

logging "info" "Checking to see if Rosetta2 is needed ..."
rosetta2_check "$processor_brand"

logging "info" "Checking to see if Homebrew is already installed on this Mac ..."
check_brew_install_status

logging "info" "Determining Homebrew path prefix ..."
brew_prefix=$(set_brew_prefix "$processor_brand")

logging "info" "Creating the Homebrew directory at $brew_prefix/Homebrew ..."
/bin/mkdir -p "$brew_prefix/Homebrew"

logging "info" "Downloading homebrew ..."

# Using curl to download the latest release of homebrew tarball and put it in
# brew_prefix/Homebrew If brew updates to master to main, the url will need to be
# adjusted.
/usr/bin/curl --fail --silent --show-error --location \
    --url "https://github.com/Homebrew/brew/tarball/master" |
    /usr/bin/tar xz --strip 1 -C "$brew_prefix/Homebrew" | /usr/bin/tee -a "${LOG_PATH}"

# checking to see if brew was downloaded successfully
if [[ -f "$brew_prefix/Homebrew/bin/brew" ]]; then
    logging "info" "Homebrew binary found at $brew_prefix/Homebrew/bin/brew ..."
    logging "info" "Creating the brew environment ..."
    create_brew_environment "$brew_prefix" "$current_user"

else
    logging "info" "Homebrew binary not found ..."
    /bin/echo "Check $LOG_PATH for more details ..."
    exit 1

fi

logging "info" "Running brew update --force ..."
/usr/bin/su - "$current_user" -c "$brew_prefix/bin/brew update --force" 2>&1 |
    /usr/bin/tee -a "${LOG_PATH}"

logging "info" "Running brew cleanup ..."
/usr/bin/su - "$current_user" -c "$brew_prefix/bin/brew cleanup" 2>&1 |
    /usr/bin/tee -a "${LOG_PATH}"

# updated the user's PATH var to add brew binary location
logging "info" "Checking to see if brew is in current user's PATH..."
update_path

logging "info" "Running brew doctor to validate the install ..."
brew_doctor "$brew_prefix" "$current_user"

logging "info" "If the user has any existing CLI sessions running brew doctor may not see that brew is in the user's PATH."
logging "info" "The user may need to restart or open a new CLI session before brew will be recognized in their path."
logging "info" "Otherwise, brew can be called directly with $brew_prefix/bin/brew"

logging "info" "--- End homebrew install log ---"

exit 0
