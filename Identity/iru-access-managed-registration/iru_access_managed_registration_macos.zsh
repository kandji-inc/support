#!/bin/zsh

################################################################################################
# Software Information
################################################################################################
#
#   Provisions an Iru Access MDM connection client secret on a managed Mac so the
#   device can register without user interaction. Edit regToken and regTokenDomain in
#   USER INPUT before you upload the script to your MDM, then deploy it with no
#   command-line arguments. The script checks whether the secret is already registered
#   for your domain and applies it only when needed.
#
#   Deploy through your MDM as a custom script. Run on a schedule after Iru Access
#   is installed.
#
#   For details, see:
#   https://docs.iru.com/en/identity/authentication/deploy-iru-access
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

################################################################################################
###################################### USER INPUT ##############################################
################################################################################################

# Replace with your MDM connection's client secret and your Iru domain.
regToken="mdm-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
regTokenDomain="yourcompany.iru.com"

################################################################################################
########################### FUNCTIONS - DO NOT MODIFY BELOW ####################################
################################################################################################

# Set logging - Send logs to stdout as well as Unified Log
# Usage: logging "LEVEL" "Message..."
# Use 'log show --process "logger"' to view log activity.
logging() {
    script_id="iru_access_managed_registration_macos"
    timestamp=$(/bin/date +"%m-%d-%Y %H:%M:%S")

    /bin/echo "${timestamp} ${1}: ${2}"
    /usr/bin/logger "${script_id}: [${1}] ${2}"
}

################################################################################################
###################################### VARIABLES ###############################################
################################################################################################

iruAccessCLI="/Applications/Iru Access.app/Contents/MacOS/iru-access"

################################################################################################
############################## MAIN LOGIC - DO NOT MODIFY BELOW ################################
################################################################################################

set -euo pipefail

# Current list of registered secrets
listOutput="$("${iruAccessCLI}" manage --list 2>/dev/null || true)"

# Existing hash for this domain, if any
existingHash="$(
    /bin/echo "${listOutput}" \
    | /usr/bin/awk -v domain="${regTokenDomain}" '
        index($1, domain":") == 1 {
            split($1, a, ":");
            print a[2];
        }
    '
)"

# SHA-256 of the current token
currentHash="$(/usr/bin/printf '%s' "${regToken}" | /usr/bin/shasum -a 256 | /usr/bin/awk '{print $1}')"

# Already registered with this token? Nothing to do.
if [[ -n "${existingHash}" && "${existingHash}" == "${currentHash}" ]]; then
    logging "INFO" "MDM registration token already registered"
    exit 0
fi

logging "INFO" "Setting registration token for domain: ${regTokenDomain}"
"${iruAccessCLI}" manage --secret "${regToken}" --domain "${regTokenDomain}"

exit $?
