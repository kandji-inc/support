#!/usr/bin/env zsh

################################################################################################
# Created by Chris Jantze | support@kandji.io | Kandji, Inc.
################################################################################################
# Created on 2026-08-21
################################################################################################
# Tested macOS Versions
################################################################################################
#
#
################################################################################################
# Software Information
################################################################################################
#
#   Prism API export example using zshell.
#
#   DESCRIPTION
#
#       This script demonstrates the Prism export endpoints. Instead of paginating
#       through a category a page at a time, an export asks the Kandji API to render the
#       whole category to a CSV file and then hands back a temporary link to download it
#       once the file is ready.
#
#       There are four steps:
#
#           1. Start the export      POST /v1/prism/export
#           2. Wait for it to finish GET  /v1/prism/export/{export_id}
#           3. Download the file     GET  the signed_url from step 2
#           4. Process the records   read the downloaded CSV
#
#       param: category
#
#       The Prism category to export. One of the following:
#
#           activation_lock          installed_profiles
#           application_firewall     kernel_extensions
#           apps                     launch_agents_and_daemons
#           cellular                 local_users
#           certificates             ms_compliance
#           desktop_and_screensaver  startup_settings
#           device_information       system_extensions
#           filevault                transparency_database
#           gatekeeper_and_xprotect
#
#       Note: the names are not always what you would guess. It is "filevault" and not
#             "file_vault", and "apps" and not "applications".
#
#       param: blueprint_ids
#
#       A list of blueprint IDs to limit the export to. An empty array exports devices
#       from every blueprint.
#
#       param: device_families
#
#       A list of device families to limit the export to, for example ("Mac" "iPhone").
#       An empty array exports every device family.
#
#       param: filter
#
#       An optional JSON object used to limit which records are exported. Each key is an
#       attribute name and each value is an object of operator to value, for example
#
#           '{"app_name": {"like": ["Safari"]}}'
#
#       The supported operators are is_null, in, not_in, like, and not_like. The "in" and
#       "not_in" operators cannot be combined on the same attribute.
#
#       param: columns
#
#       An optional list of column names to include in the CSV. An empty array returns
#       every column in the category. Set with EXPORT_COLUMNS below.
#
#   THINGS WORTH KNOWING
#
#       - The export always produces a CSV file with a header row. There is currently no
#         way to ask for a different format.
#
#       - One CSV record is not the same thing as one line. A quoted field may contain
#         a newline, and the Copyright column on Apple's own applications does exactly
#         that, so counting lines will overcount records on any real tenant.
#
#       - The status of an export is one of "pending", "success", or "failed". There is
#         no percent complete and no record count, so an export that is actively running
#         still reads as "pending". Keep checking until the status changes.
#
#       - The signed_url is a temporary link that carries its own credentials in the
#         query string, so request it WITHOUT the Kandji Authorization header. Sending
#         one will conflict with the credentials already on the link. The link is good
#         for 48 hours.
#
#       - The API accepts a sort_by value but does not currently apply it, so it is left
#         out of this example. Sort the records after downloading them instead.
#
#   RESOURCES
#
#       - https://support.kandji.io/kb/kandji-api
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

# The Prism category to export. See the list of categories above.
CATEGORY="apps"

# Limit the export to specific blueprints. An empty array exports every blueprint.
BLUEPRINT_IDS=()

# Limit the export to specific device families, for example ("Mac" "iPhone"). An empty
# array exports every device family.
DEVICE_FAMILIES=()

# Limit the export to records matching a filter, as a JSON object. For example
# '{"app_name": {"like": ["Safari"]}}'. An empty object exports every record.
FILTER='{}'

# Limit the export to specific columns. An empty array returns every column.
# NOTE: not named `COLUMNS` on purpose -- `$COLUMNS` is a special zsh parameter holding
# the terminal width, and assigning an array to it is an error.
EXPORT_COLUMNS=()

# How long to wait between checks on a pending export, and how long to keep checking
# before giving up. Both are in seconds.
POLL_INTERVAL=5
POLL_TIMEOUT=900

# Where the downloaded export file is written
OUTPUT_DIR="${PWD}"

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

function start_export() {
    # Start an export and set export_id to the ID assigned to it.
    #
    # The export options are sent as a JSON body rather than as URL parameters. The body
    # is assembled with jq rather than by pasting strings together so that category
    # names, filters, and column names are escaped correctly.
    #
    # NOTE: `typeset -g` is required here -- a bare `typeset`/`declare` inside a zsh
    # function makes the variable local and shadows the global, leaving callers with
    # nothing.
    typeset -g export_id

    local http_code
    local payload
    local blueprints_json
    local families_json
    local columns_json

    # turn the zsh arrays into JSON arrays. `--args` is used rather than joining the
    # values by hand because it produces a correct `[]` for an empty array and escapes
    # any value that needs it.
    blueprints_json=$(${jq_path} -n -c '$ARGS.positional' --args "${BLUEPRINT_IDS[@]}")
    families_json=$(${jq_path} -n -c '$ARGS.positional' --args "${DEVICE_FAMILIES[@]}")
    columns_json=$(${jq_path} -n -c '$ARGS.positional' --args "${EXPORT_COLUMNS[@]}")

    # --argjson is used for the arrays and the filter so they land in the body as JSON
    # rather than as quoted strings.
    payload=$(${jq_path} -n -c \
        --arg category "${CATEGORY}" \
        --argjson blueprint_ids "${blueprints_json}" \
        --argjson device_families "${families_json}" \
        --argjson filter "${FILTER}" \
        --argjson columns "${columns_json}" \
        '{category: $category, blueprint_ids: $blueprint_ids,
          device_families: $device_families, filter: $filter, columns: $columns}')

    http_code=$(/usr/bin/curl --silent --request POST \
            --output "${tmp_response}" \
            --write-out '%{http_code}' \
            --url "${BASE_URL}/v1/prism/export" \
            --header "Authorization: Bearer ${TOKEN}" \
            --header "Content-Type: ${CONTENT_TYPE}" \
        --data "${payload}")

    # bail early on non-2xx so we surface auth/network errors instead of letting jq
    # trip over a non-JSON or oddly-shaped error body.
    if [[ "${http_code}" != 2* ]]; then
        echo "API error ${http_code} from ${BASE_URL}/v1/prism/export" >&2
        echo "A common cause is a category name that does not exist." >&2
        echo "Response:" >&2
        /bin/cat "${tmp_response}" >&2
        exit 1
    fi

    export_id=$(${jq_path} -r '.id // ""' "${tmp_response}")

    if [[ -z "${export_id}" || "${export_id}" == "null" ]]; then
        echo "The export could not be started..." >&2
        /bin/cat "${tmp_response}" >&2
        exit 1
    fi
}

function wait_for_export() {
    # Check on an export until it finishes, then set export_path and export_signed_url.

    typeset -g export_path
    typeset -g export_signed_url

    # NOTE: not named `status` on purpose -- `$status` is a zsh builtin alias for `$?`,
    # so using it as a variable name here would fight the shell.
    local export_status
    local http_code
    local waited=0

    while true; do
        http_code=$(/usr/bin/curl --silent --request GET \
                --output "${tmp_response}" \
                --write-out '%{http_code}' \
                --url "${BASE_URL}/v1/prism/export/${export_id}" \
                --header "Authorization: Bearer ${TOKEN}" \
            --header "Content-Type: ${CONTENT_TYPE}")

        if [[ "${http_code}" != 2* ]]; then
            echo "API error ${http_code} checking on export ${export_id}" >&2
            echo "Response:" >&2
            /bin/cat "${tmp_response}" >&2
            exit 1
        fi

        export_status=$(${jq_path} -r '.status // ""' "${tmp_response}")
        export_path=$(${jq_path} -r '.path // ""' "${tmp_response}")
        export_signed_url=$(${jq_path} -r '.signed_url // ""' "${tmp_response}")

        if [[ "${export_status}" == "failed" ]]; then
            echo "The export failed..." >&2
            echo "Reason: $(${jq_path} -r '.error_msg // "none given"' "${tmp_response}")" >&2
            exit 1
        fi

        # a finished export is only useful once the download link is attached to it
        if [[ "${export_status}" == "success" && -n "${export_signed_url}" ]]; then
            return 0
        fi

        if [[ "${export_status}" != "pending" && "${export_status}" != "success" ]]; then
            echo "Unexpected export status \"${export_status}\"" >&2
            /bin/cat "${tmp_response}" >&2
            exit 1
        fi

        if (( waited >= POLL_TIMEOUT )); then
            echo "The export was still \"${export_status}\" after ${POLL_TIMEOUT} seconds..." >&2
            echo "A large export may just need more time. Raise POLL_TIMEOUT and try" >&2
            echo "again, or check back on this export using its ID." >&2
            echo "    Export ID: ${export_id}" >&2
            exit 1
        fi

        /bin/sleep "${POLL_INTERVAL}"
        (( waited += POLL_INTERVAL ))
        echo "    Still working on it. ${waited} seconds so far..."
    done
}

function download_export() {
    # Download a finished export and set export_file to the path it was written to.

    typeset -g export_file

    local http_code

    # the path looks like "<bucket>/<tenant_id>/<file_name>" so only the last part of it
    # is useful here. `:t` is the zsh "tail" modifier, the equivalent of basename.
    export_file="${OUTPUT_DIR}/${export_path:t}"

    # NOTE: this request deliberately does NOT send the Authorization header. The signed
    # URL already carries its own credentials in the query string and adding a bearer
    # token will conflict with them.
    http_code=$(/usr/bin/curl --silent --location \
            --output "${export_file}" \
            --write-out '%{http_code}' \
        --url "${export_signed_url}")

    if [[ "${http_code}" != 2* ]]; then
        echo "Download failed with ${http_code} for export ${export_id}" >&2
        exit 1
    fi
}

function process_record() {
    # Process one record from the export.
    #
    # The record is the raw text of one CSV record. It may span more than one line --
    # see the note in process_export below.
    #
    # NOTE: splitting this on "," is NOT safe. A field such as "Some, App" holds a
    # comma inside quotes, so splitting on the separator would produce the wrong number
    # of values. Use a real CSV parser if you need individual fields.
    #
    # TODO: replace the body of this function with whatever you need to do with each
    # record. As written it does nothing at all.

    # shellcheck disable=SC2034
    local record="${1}"

    # echo "${record}"
}

function process_export() {
    # Read the downloaded CSV and hand each record to process_record.
    #
    # reset the shared `data` array (declared at the top level) so repeat calls don't
    # accumulate. returning the array via stdout doesn't scale -- large tenants overflow
    # ARG_MAX -- so callers read `${data[@]}` directly.
    # NOTE: `typeset -g` is required here -- a bare `declare`/`typeset` inside a zsh
    # function makes the array local and shadows the global, leaving callers with an
    # empty array.
    typeset -g -a data
    typeset -g csv_header

    local line
    local buffer=""
    local in_record=0
    local quotes
    local entry
    local -a records

    data=()
    records=()

    # Reassemble logical CSV records. A record is NOT the same thing as a line: a
    # quoted field is allowed to contain a newline, and the Copyright column on
    # Apple's own applications does exactly that --
    #
    #     "Copyright (c) 2014-2024 Apple Inc.
    #     All rights reserved."
    #
    # is one field spanning two lines. Reading the file a line at a time would count
    # those as two records and inflate the total.
    #
    # Counting the double quotes accumulated so far tells us whether a quoted field is
    # still open: an odd count means the record continues on the next line. An escaped
    # quote ("") contributes two, so it does not disturb the parity.
    while IFS= read -r line; do
        if (( in_record )); then
            buffer="${buffer}"$'\n'"${line}"
        else
            buffer="${line}"
            in_record=1
        fi

        # strip every character that is not a double quote, then count what is left
        quotes="${buffer//[^\"]/}"
        if (( ${#quotes} % 2 == 0 )); then
            records+=("${buffer}")
            buffer=""
            in_record=0
        fi
    done < "${export_file}"

    # a record left open at end of file means the CSV was truncated mid-field. keep it
    # rather than dropping it silently.
    if (( in_record )); then
        echo "    Warning: the last record ended mid-field. The file may be truncated." >&2
        records+=("${buffer}")
    fi

    if (( ${#records[@]} == 0 )); then
        return 0
    fi

    # the first logical record is the header row, which names the columns
    csv_header="${records[1]}"

    # everything after the header is data. records go into the array as-is rather than
    # base64 encoded: they are assembled here in the loop instead of being streamed one
    # per line out of another command, so there is no line-based transport to survive.
    data=("${records[@]:1}")

    for entry in "${data[@]}"; do
        process_record "${entry}"
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
echo "Category: ${CATEGORY}"
echo ""

# shared tempfile for API response bodies. one file and one trap for the whole script --
# registering an EXIT trap inside each function would mean the last one wins and the
# earlier tempfiles leak.
tmp_response="$(/usr/bin/mktemp)"
trap "/bin/rm -f '${tmp_response}'" EXIT

# shared array populated by process_export; each entry is the raw text of one CSV
# record, which may span more than one line if a quoted field contains a newline.
declare -a data

echo "Starting the export..."
start_export || exit 1
echo "    Export ID: ${export_id}"

echo "Waiting for the export to finish..."
wait_for_export || exit 1

echo "Downloading the export..."
download_export || exit 1
echo "    Export file: ${export_file}"

echo "Processing the export..."
process_export || exit 1
echo "    Records processed: ${#data[@]}"
echo ""
