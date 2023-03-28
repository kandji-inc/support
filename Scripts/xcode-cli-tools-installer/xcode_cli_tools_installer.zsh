#!/bin/zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 2021-08-19
#   Updated - 2023-03-23
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - 13.2.1
#   - 12.6.1
#   - 11.7.1
#   - 10.15.7
#
################################################################################################
# Software Information
################################################################################################
#
#   A script to install or update xcode-cli tools.
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

autoload is-at-least

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
        /bin/echo "Valid Xcode CLI tools path found."

        # current bundleid for CLI tools
        bundle_id="com.apple.pkg.CLTools_Executables"

        if /usr/sbin/pkgutil --pkgs="$bundle_id" >/dev/null; then
            # If the CLI tools pkg bundle is found, get the version

            installed_version=$(/usr/sbin/pkgutil --pkg-info="$bundle_id" |
                /usr/bin/awk '/version:/ {print $2}' |
                /usr/bin/awk -F "." '{print $1"."$2}')

            /bin/echo "Installed CLI tools version is \"$installed_version\""

        else
            /bin/echo "Unable to determine installed CLI tools version from \"$bundle_id\"."
        fi

        /bin/echo "Checking to see if there are any available CLI tool updates..."

        # Get the latest available CLI tools
        cmd_line_tools=("$(get_available_cli_tool_installs)")

    else
        /bin/echo "Valid Xcode CLI tools path was not found ..."
        /bin/echo "Getting the latest Xcode CLI tools available for install..."

        # Get the latest available CLI tools
        cmd_line_tools=("$(get_available_cli_tool_installs)")

    fi

    # if something is returned from the cli tools check
    # shellcheck disable=SC2128
    if [[ -n $cmd_line_tools ]]; then
        /bin/echo "Available Xcode CLI tools found: "
        /bin/echo "$cmd_line_tools"

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
                /bin/echo "Updating $cmd_line_tools..."
                /usr/sbin/softwareupdate --install "${cmd_line_tools}" --verbose

            else
                # if the installed version is greater than or equal to latest available
                /bin/echo "Installed version \"$installed_version\" is $version_check the latest available version \"$lastest_available_version\". No upgrade needed."
            fi

        else
            /bin/echo "Installing $cmd_line_tools..."
            /usr/sbin/softwareupdate --install "${cmd_line_tools}" --verbose
        fi

    else
        /bin/echo "Hmmmmmm...unabled to return any available CLI tools..."
        /bin/echo "May need to validate the softwareupdate command used."
    fi

    /bin/echo "Cleaning up $xclt_tmp ..."
    /bin/rm "${xclt_tmp}"
}

# call xcode_cli_tools
echo "Checking Xcode CLI tools install status ..."
xcode_cli_tools

exit 0
