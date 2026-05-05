#!/usr/bin/env zsh

################################################################################################
# Created by Chris Jantze | support@kandji.io | Kandji, Inc.
################################################################################################
# Created on 2026-05-04
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   26.4.1
#
################################################################################################
# Software Information
################################################################################################
#
#   Prism API cursor pagination example using zshell.
#
#   DESCRIPTION
#
#       This script uses a combination of the limit and cursor parameters to
#       demonstrate the use of pagination to control the number of records returned per
#       Prism API call and how to call the next batch of application records until all
#       application records are returned.
#
#       param: limit
#
#       The limit parameter controls the maximum number of items that may be returned
#       for a single request. This parameter can be thought of as the page size. If no
#       limit is specified, the default limit is set to 300 records per request.
#
#       param: cursor
#
#       Opaque pagination token for retrieving the next page of results.
#        - This value is obtained from the `cursor` field of a previous response.
#        - The cursor encodes the current position in the result set based on the
#          underlying sort order.
#        - Clients must treat this value as opaque and should not attempt to parse or modify it.
#        - Cursors are only valid for the same query parameters and ordering.
#        - If not provided, the request returns the first page of results.
#
#       Note: Custom ordering is not currently supported.
#       Note: Cursor-based pagination provides consistent performance and avoids the
#             limitations of offset-based pagination for large datasets.
#
#   RESOURCES
#
#       In very simple terms, pagination is the act of splitting large amounts of data
#       into multiple smaller pieces. For example, whenever you go to the questions
#       page in Stack Overflow, you see something like this at the bottom
#
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

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Kandji tenant subdomain
SUBDOMAIN="" # accuhive

# tenant region
REGION="" # us, eu

# Kandji Bearer Token
TOKEN=""

# Content type used in API requests
CONTENT_TYPE="application/json;charset=utf-8"

########################################################################################
###################################### FUNCTIONS #######################################
########################################################################################

function install_jq() {
    # Download and install jq

    # univeral install hosted by Kandji
    universal_jq_release="https://github.com/kandji-inc/support/raw/main/UniversalJQ/JQ-1.8.1-UNIVERSAL.pkg.tar.gz"

    # jq temp download location
    jq_tmp="/private/tmp/jq.tar.gz"

    # installed binary
    installed_jq="/Library/KandjiSE/jq"

    jq_bin="/usr/local/bin/jq"

    /usr/bin/curl -L "${universal_jq_release}" -o "${jq_tmp}"

    # Expand our tarball into tmp
    /usr/bin/tar -xf "${jq_tmp}" -C /private/tmp

    # Locate our extracted JQ package and install it
    /usr/bin/find -L /private/tmp -iname "jq*pkg" -exec sudo /usr/sbin/installer \
        -pkg {} -target / \;

    sudo /bin/mkdir -p "/usr/local/bin"
    sudo /bin/mv "${installed_jq}" "${jq_bin}"
    sudo /bin/chmod a+x "${jq_bin}"
}

function get_apps() {
    # Return application inventory from the Prism apps endpoint.
    #
    # This function will call the /v1/prism/apps endpoint and return a JSON object
    # containing all records. If pagination is needed to return all records, limit and
    # cursor are used to get all pages.

    # limit - set the number of records to return per API call
    limit=300
    # cursor - starts from the beginning of the collection and is used to retrieve the
    # next batch of records until all records are returned
    cursor=""

    count=0

    # reset the shared `data` array (declared at the top level) so repeat calls
    # don't accumulate. returning the array via stdout doesn't scale -- large
    # tenants overflow ARG_MAX -- so callers read `${data[@]}` directly.
    # NOTE: `typeset -g` is required here -- a bare `declare`/`typeset` inside a
    # zsh function makes the array local and shadows the global, leaving callers
    # with an empty array.
    typeset -g -a data

    # write the response body to a tempfile and feed jq from the file. piping the
    # body through a shell variable can mangle control chars / CRLFs and cause jq
    # parse errors on otherwise-valid responses.
    tmp_response="$(/usr/bin/mktemp)"
    trap "/bin/rm -f '${tmp_response}'" EXIT

    # loop until no app records are returned in the response or no cursor is returned.
    while true; do
        # return application inventory using limit and cursor.
        # use --data-urlencode with -G so opaque cursor tokens are encoded safely.
        http_code=$(/usr/bin/curl --silent --request GET -G \
                --output "${tmp_response}" \
                --write-out '%{http_code}' \
                --data-urlencode "limit=${limit}" \
                --data-urlencode "cursor=${cursor}" \
                --url "${BASE_URL}/v1/prism/apps" \
                --header "Authorization: Bearer ${TOKEN}" \
            --header "Content-Type: ${CONTENT_TYPE}")

        # bail early on non-2xx so we surface auth/network errors instead of letting
        # jq trip over a non-JSON or oddly-shaped error body.
        if [[ "${http_code}" != 2* ]]; then
            echo "API error ${http_code} from ${BASE_URL}/v1/prism/apps" >&2
            echo "Response:" >&2
            /bin/cat "${tmp_response}" >&2
            exit 1
        fi

        ((count++))

        # number of items returned in this page
        items_count=$(${jq_path} '.data | length' "${tmp_response}")

        # check to see if the response is empty meaning that no apps were returned
        # for the specified tenant.
        if [[ "${items_count}" == "0" ]]; then
            # make sure that apps were returned from kandji on the first page
            if [[ "${count}" = 1 ]]; then
                echo "No applications found in the ${SUBDOMAIN} tenant..." >&2
                exit 0
            fi
            break
        fi

        # base64 encode each record from .data and append to the data array
        for record in $(${jq_path} -r '.data[] | @base64' "${tmp_response}"); do
            # shellcheck disable=SC2206
            data+=(${record})
        done

        # update the cursor for the next request. if it is missing or empty we are done.
        cursor=$(${jq_path} -r '.cursor // ""' "${tmp_response}")
        if [[ -z "${cursor}" || "${cursor}" == "null" ]]; then
            break
        fi
    done
}

########################################################################################
###################################### MAIN LOGIC ######################################
########################################################################################

# Kandji API base URL
if [[ -z ${REGION} || ${REGION} == "us" ]]; then
    BASE_URL="https://${SUBDOMAIN}.api.kandji.io/api"
elif [[ ${REGION} == "eu" ]]; then
    BASE_URL="https://${SUBDOMAIN}.api.${REGION}.kandji.io/api"
else
    echo "Unsupported region: ${REGION}. Please update and try again."
    exit 1
fi

# look for jq -- restrict to files (follow symlinks for Homebrew's bin/jq) and take
# the first match, since `find -name jq` also matches directories like
# /opt/homebrew/opt/jq and /opt/homebrew/Cellar/jq.
jq_path="$(/usr/bin/find -L /usr/local/bin /bin /opt/homebrew -maxdepth 3 \
    -name jq -type f 2>/dev/null | /usr/bin/head -n 1)"

if [[ -z ${jq_path} ]]; then
    echo "Did not find jq in PATH. Attempting to install..."
    install_jq

    # set jq path
    jq_path="$(/usr/bin/find -L /usr/local/bin /bin /opt/homebrew -maxdepth 3 \
        -name jq -type f 2>/dev/null | /usr/bin/head -n 1)"
    echo "jq installed at ${jq_path}."

else
    echo "jq path found at ${jq_path}"
fi

echo ""
echo "Base URL: ${BASE_URL}"
echo ""

# Get the total number of apps
echo "Getting application inventory from Iru..."

# shared array populated by get_apps; each entry is a base64-encoded JSON record.
declare -a data

get_apps || exit 1

echo "Total application records returned: ${#data[@]:#}"