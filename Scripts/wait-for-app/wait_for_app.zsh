#!/usr/bin/env zsh

################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Iru, Inc.
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

#
#   Wait for a particular app to install before moving on.
#

# How long to wait in seconds before quitting
# Example -- 300 Checks * 5 seconds between each check = 1500 seconds or 15 minutes
TOTAL_CHECKS=300

# The app that you are looking for
APP_NAME="Iru Self Service.app"

wait_for_app() {
    # Wait for a particular app install before moving on
    # $1: name of app

    COUNT=0

    # Initialize the varialbe
    APP_DIR=""

    while [[ ! -d ${APP_DIR} ]]; do
        # If the line ends in ".app" echo to stdout

        # Populate the varialbe with the location for the app
        APP_DIR="/Applications/${1}"

        if [[ -d ${APP_DIR} ]]; then
            # If the directory exists, let the user know and exit

            echo "${1} installed!!!"
            echo "Moving on ..."
            break

        elif [[ ! -d "$APP_DIR" ]] && [[ $COUNT -eq ${TOTAL_CHECKS} ]]; then
            #statements

            echo "${1} not installed ..."
            echo "Quitting after 15 minutes ..."
            break

        else

            # Let the user know that the app has not installed yet
            echo "${1} not installed yet ..."
            echo "Waiting 5 seconds before checking again ..."
            /bin/sleep 5

        fi

        COUNT=$((COUNT + 1))

    done

}

echo "calling function ..."
wait_for_app "$APP_NAME"

/echo "Opening $APP_NAME ..."
/usr/bin/open "/Applications/$APP_NAME"

exit 0
