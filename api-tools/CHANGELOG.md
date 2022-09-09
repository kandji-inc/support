# CHANGE LOG

All notable changes to api-tools are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to Year Notation Versioning.


## Types of Changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.


## [2022-09-01]

- `Added`

    - [new] Added a script to interact with and generate reports against Apple integrations
    - [new] Added a script to interact with device actions endpoints
    - [new] Added a script to interact with and generate reports against the device details API
    - [new] Added a script to interact with and generate reports against the device parameters API
    - Added `--name` to the `app-install-report` script allowing the user to search for a specific installed app by name.
    - Added blueprint name to reporting output in relevent scripts
    - Added addtional error handling in the `update-device-record` script

- `Changed`

    - Updated how a Kandji tenant and region are entered in scripts. Now the user just needs to enter a tenant subdomain and region. From there the scripts will create the correct base URL for the user.
    - Pagination functionality has been added to relevant scripts where the List devices endpoint is being called.