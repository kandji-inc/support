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

## [2023-04-06]

## Changed

- Update some of the print statements to be more clear.

### Fixed

- Fixed issue where a parameter was not found in the `update_device_record` script.

## [2023-02-07]

### Added

- Added the ability to send the lock action to devices in the `device_actions` script.
- Added ability to limit a search to a blueprint in the `device_actions` script.

## [2023-02-03]

### Added

- Added query support for an OS Version, Processor type, and device-based activation lock in the `device_details` script.
- Added ability to limit a search to a single device or blueprint in the `device_details` script.

### Changed

- Added support for adding multiple queries in the `device_details` script. You can now combine two or more queries in a single run.
- Change `device_details_report` to `device_details`
- Change `app_install_report` to `installed_apps`
- Updated logic for determining Kandji tenant region in all scripts.
- Updated API base URLs to support new API URL scheme.

## [2022-10-21]

### Added

- Added a pagnination example using zshell with `limit` and `offset`.

### Changed

- Updated logic to determine the base url for the API depending on where the Kandji tenant is located.
- Updated README

## [2022-09-01]

### Added

- Added a script to interact with and generate reports against Apple integrations
- Added a script to interact with device actions endpoints
- Added a script to interact with and generate reports against the device details API
- Added a script to interact with and generate reports against the device parameters API
- Added `--name` to the `app-install-report` script allowing the user to search for a specific installed app by name.
- Added blueprint name to reporting output in relevent scripts
- Added addtional error handling in the `update-device-record` script

### Changed

- Updated how a Kandji tenant and region are entered in scripts. Now the user just needs to enter a tenant subdomain and region. From there the scripts will create the correct base URL for the user.
- Pagination functionality has been added to relevant scripts where the List devices endpoint is being called.
