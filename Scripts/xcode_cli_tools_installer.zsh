#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created - 2021-08-19
#   Updated - 2022-04-07
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   - 12.3.1
#   - 11.6.5
#   - 10.15.7
#
###################################################################################################
# Software Information
###################################################################################################
#
#   A script to install xcode-cli tools.
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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

xcode_cli_tools() {
    # Check for and install Xcode CLI tools
    # Run command to check for an Xcode cli tools path
    /usr/bin/xcrun --version >/dev/null 2>&1

    # check to see if there is a valide CLI tools path
    if [[ $? -eq 0 ]]; then
        /bin/echo "Valid Xcode path found. No need to install Xcode CLI tools ..."

    else
        /bin/echo "Valid Xcode CLI tools path was not found ..."

        # finded out when the OS was built
        build_year=$(/usr/bin/sw_vers -buildVersion | cut -c 1,2)

        # Trick softwareupdate into giving use everything it knows about xcode cli tools
        xclt_tmp="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

        # create the file above
        /bin/echo "Creating $xclt_tmp ..."
        /usr/bin/touch "${xclt_tmp}"

        if [[ "${build_year}" -ge 19 ]]; then
            # for Catalina or newer
            /bin/echo "Getting the latest Xcode CLI tools available ..."
            cmd_line_tools=$(/usr/sbin/softwareupdate -l | /usr/bin/awk '/\*\ Label: Command Line Tools/ { $1=$1;print }' | /usr/bin/sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | /usr/bin/cut -c 9- | /usr/bin/grep -vi beta | /usr/bin/sort -n)

        else
            # For Mojave or older
            /bin/echo "Getting the latest Xcode CLI tools available ..."
            cmd_line_tools=$(/usr/sbin/softwareupdate -l | /usr/bin/awk '/\*\ Command Line Tools/ { $1=$1;print }' | /usr/bin/grep -i "macOS" | /ussr/bin/sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | /usr/bin/cut -c 2-)

        fi

        /bin/echo "Available Xcode CLI tools found: "
        /bin/echo "$cmd_line_tools"

        if (($(/usr/bin/grep -c . <<<"${cmd_line_tools}") > 1)); then
            cmd_line_tools_output="${cmd_line_tools}"
            cmd_line_tools=$(printf "${cmd_line_tools_output}" | /usr/bin/tail -1)

            /bin/echo "Latest Xcode CLI tools found: $cmd_line_tools"
        fi

        # run softwareupdate to install xcode cli tools
        /bin/echo "Installing the latest Xcode CLI tools ..."

        # Sending this output to the local homebrew_install.log as well as stdout
        /usr/sbin/softwareupdate -i "${cmd_line_tools}" --verbose

        # cleanup the temp file
        /bin/echo "Cleaning up $xclt_tmp ..."
        /bin/rm "${xclt_tmp}"

    fi
}

# call xcode_cli_tools
echo "Checking to see if xcode cli tools install status ..."
xcode_cli_tools

exit 0
