#!/bin/zsh

########################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Solutions Engineering
########################################################################################
#
# Created on 11/24/2020
# Updated on 09/24/2021 - David Larrea and Matt Wilson
# Updated on 12/01/2022 - Matt Wilson
#
########################################################################################
# Tested macOS Versions
########################################################################################
#
#   13.0.1
#   12.6
#   11.7.1
#
########################################################################################
# Software Information
########################################################################################
#
# This script checks the architecture of a macOS Device, if the Mac is running on Apple
# Silicon The script then checks if Rosetta is installed, and if not, installs it
# silently
#
########################################################################################
# License Information
########################################################################################
# Copyright 2022 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
########################################################################################

# Determine the processor brand
processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

# Determine the processor brand
if [[ "$processor_brand" == *"Apple"* ]]; then
    /bin/echo "Apple Processor is present..."

    # Check if the Rosetta service is running
    check_rosetta_status=$(/usr/bin/pgrep oahd)

    # Rosetta Folder location
    # Condition to check to see if the Rosetta folder exists. This check was added
    # because the Rosetta2 service is already running in macOS versions 11.5 and
    # greater without Rosseta2 actually being installed.
    rosetta_folder="/Library/Apple/usr/share/rosetta"

    if [[ -n $check_rosetta_status ]] && [[ -e $rosetta_folder ]]; then
        /bin/echo "Rosetta2 is installed... no action needed"
    else
        # Installs Rosetta
        /bin/echo "Rosetta is not installed... installing now"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

else
    /bin/echo "Apple Processor is not present...Rosetta2 is not needed"
fi

exit 0
