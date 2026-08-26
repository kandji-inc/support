#!/usr/bin/env python3

"""Prism API export example using python."""

################################################################################################
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
#       A list of blueprint IDs to limit the export to. An empty list exports devices
#       from every blueprint.
#
#       param: device_families
#
#       A list of device families to limit the export to, for example ["Mac", "iPhone"].
#       An empty list exports every device family.
#
#       param: filter
#
#       An optional dict used to limit which records are exported. Each key is an
#       attribute name and each value is a dict of operator to value, for example
#
#           {"app_name": {"like": ["Safari"]}}
#
#       The supported operators are is_null, in, not_in, like, and not_like. The "in" and
#       "not_in" operators cannot be combined on the same attribute.
#
#       param: columns
#
#       An optional list of column names to include in the CSV. An empty list returns
#       every column in the category.
#
#   THINGS WORTH KNOWING
#
#       - The export always produces a CSV file with a header row. There is currently no
#         way to ask for a different format.
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

import csv
import json
import pathlib
import sys
import time

import requests
from requests.adapters import HTTPAdapter

########################################################################################
######################### UPDATE VARIABLES BELOW #######################################
########################################################################################

SUBDOMAIN = ""  # bravewaffles, example, company_name

# us("") and eu - this can be found in the Kandji settings on the Access tab
REGION = ""

# Kandji Bearer Token (API Key from your tenant settings)
TOKEN = ""

# The Prism category to export. See the list of categories above.
CATEGORY = "apps"

# Limit the export to specific blueprints. An empty list exports every blueprint.
BLUEPRINT_IDS = []

# Limit the export to specific device families, for example ["Mac", "iPhone"]. An empty
# list exports every device family.
DEVICE_FAMILIES = []

# Limit the export to records matching a filter, for example
# {"app_name": {"like": ["Safari"]}}. An empty dict exports every record.
FILTER = {}

# Limit the export to specific columns. An empty list returns every column.
COLUMNS = []

# How long to wait between checks on a pending export, and how long to keep checking
# before giving up. Both are in seconds.
POLL_INTERVAL = 5
POLL_TIMEOUT = 900

########################################################################################
######################### DO NOT MODIFY BELOW THIS LINE ################################
########################################################################################

# Kandji API base URL
if REGION in ["", "us"]:
    BASE_URL = f"https://{SUBDOMAIN}.api.kandji.io/api"

elif REGION in ["eu"]:
    BASE_URL = f"https://{SUBDOMAIN}.api.{REGION}.kandji.io/api"

else:
    sys.exit(f'\nUnsupported region "{REGION}". Please update and try again\n')

# API headers used in the requests
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json;charset=utf-8",
    "Cache-Control": "no-cache",
}

# Where the downloaded export is written
HERE = pathlib.Path.cwd()


def http_errors(resp, resp_code, err_msg):
    """Handle HTTP errors."""
    # 400
    if resp_code == requests.codes["bad_request"]:
        print(f"\n\t{err_msg}")
        print(f"\tResponse msg: {resp.text}\n")
    # 401
    elif resp_code == requests.codes["unauthorized"]:
        print("Make sure that you have the required permissions to access this data.")
        print(
            "Depending on the API platform this could mean that access has just been "
            "blocked."
        )
        sys.exit(f"\t{err_msg}")
    # 403
    elif resp_code == requests.codes["forbidden"]:
        print("The api key may be invalid or missing.")
        sys.exit(f"\t{err_msg}")
    # 404
    elif resp_code == requests.codes["not_found"]:
        print("\nWe cannot find the one that you are looking for...")
        print("Move along...")
        print(f"\tError: {err_msg}")
        print(f"\tResponse msg: {resp}")
        print(
            "\tPossible reason: It could be the endpoint is not correct."
        )
    # 429
    elif resp_code == requests.codes["too_many_requests"]:
        print("You have reached the rate limit ...")
        print("Try again later ...")
        sys.exit(f"\t{err_msg}")
    # 500
    elif resp_code == requests.codes["internal_server_error"]:
        print("The service is having a problem...")
        sys.exit(err_msg)
    # 503
    elif resp_code == requests.codes["service_unavailable"]:
        print("Unable to reach the service. Try again later...")
    else:
        print("Something really bad must have happened...")
        print(err_msg)
        sys.exit()


def kandji_api(method, endpoint, params=None, payload=None):
    """Make an API request and return data.

    method   - an HTTP Method (GET, POST, PATCH, DELETE).
    endpoint - the API URL endpoint to target.
    params   - optional parameters can be passed as a dict.
    payload  - optional payload is passed as a dict and used with PATCH and POST
               methods.
    Returns a JSON data object.
    """
    attom_adapter = HTTPAdapter(max_retries=3)
    session = requests.Session()
    session.mount(BASE_URL, attom_adapter)

    try:
        response = session.request(
            method,
            BASE_URL + endpoint,
            data=payload,
            headers=HEADERS,
            params=params,
            timeout=30,
        )
        # If a successful status code is returned (200 and 300 range)
        if response:
            try:
                data = response.json()
            except Exception:
                data = response.text

        # if the request is successful exceptions will not be raised
        response.raise_for_status()

    except requests.exceptions.RequestException as err:
        http_errors(resp=response, resp_code=response.status_code, err_msg=err)
        data = {"error": f"{response.status_code}", "api resp": f"{err}"}

    return data


def start_export():
    """Start an export and return the ID assigned to it."""
    # The export options are sent as a JSON body rather than as URL parameters.
    payload = {
        "category": CATEGORY,
        "blueprint_ids": BLUEPRINT_IDS,
        "device_families": DEVICE_FAMILIES,
        "filter": FILTER,
        "columns": COLUMNS,
    }

    response = kandji_api(
        method="POST", endpoint="/v1/prism/export", payload=json.dumps(payload)
    )

    export_id = response.get("id") if isinstance(response, dict) else None

    if not export_id:
        print("The export could not be started...")
        print("A common cause is a category name that does not exist.")
        sys.exit(f"\tResponse: {response}\n")

    return export_id


def wait_for_export(export_id):
    """Check on an export until it finishes and return the finished export."""
    waited = 0

    while True:
        export = kandji_api(method="GET", endpoint=f"/v1/prism/export/{export_id}")

        if not isinstance(export, dict):
            sys.exit(f"\nUnexpected response for export {export_id}: {export}\n")

        status = export.get("status")

        if status == "failed":
            print("The export failed...")
            sys.exit(f"\tReason: {export.get('error_msg') or 'none given'}\n")

        # A finished export is only useful once the download link is attached to it.
        if status == "success" and export.get("signed_url"):
            return export

        if status not in ["pending", "success"]:
            sys.exit(f'\nUnexpected export status "{status}": {export}\n')

        if waited >= POLL_TIMEOUT:
            print(f'The export was still "{status}" after {POLL_TIMEOUT} seconds...')
            print("A large export may just need more time. Raise POLL_TIMEOUT and try")
            print("again, or check back on this export using its ID.")
            sys.exit(f"\tExport ID: {export_id}\n")

        time.sleep(POLL_INTERVAL)
        waited += POLL_INTERVAL
        print(f"    Still working on it. {waited} seconds so far...")


def download_export(export):
    """Download a finished export and return the path it was written to."""
    # The path looks like "<bucket>/<tenant_id>/<file_name>" so only the last part of it
    # is useful here.
    local_path = HERE / export["path"].rsplit("/", 1)[-1]

    # The signed URL already carries its own credentials in the query string. Sending
    # the Kandji Authorization header would conflict with them, so HEADERS is not used
    # on this request.
    with requests.get(export["signed_url"], stream=True, timeout=300) as response:
        response.raise_for_status()

        with open(local_path, "wb") as downloaded:
            for chunk in response.iter_content(chunk_size=8192):
                downloaded.write(chunk)

    return local_path


def process_record(record):
    """Process one record from the export.

    record - a dict keyed by the column names from the CSV header row.

    TODO: Replace the body of this function with whatever you need to do with each
    record. As written it does nothing at all.
    """


def process_export(file_path):
    """Hand each record in the export to process_record and return the record count."""
    count = 0

    with open(file_path, newline="", encoding="utf-8") as csv_file:
        for record in csv.DictReader(csv_file):
            process_record(record)
            count += 1

    return count


def main():
    """Do the main logic."""
    print("")
    print(f"Base URL: {BASE_URL}")
    print(f"Category: {CATEGORY}")
    print("")

    print("Starting the export...")
    export_id = start_export()
    print(f"    Export ID: {export_id}")

    print("Waiting for the export to finish...")
    export = wait_for_export(export_id)

    print("Downloading the export...")
    file_path = download_export(export)
    print(f"    Export file: {file_path}")

    print("Processing the export...")
    record_count = process_export(file_path)
    print(f"    Records processed: {record_count}")
    print("")


if __name__ == "__main__":
    main()
