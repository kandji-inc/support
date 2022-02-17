# Privileges Checker

## ABOUT

This code is designed for use as an add-on to the [SAP Privileges](https://github.com/SAP/macOS-enterprise-privileges) application

### Background 

- Privileges has some limited functionality for enforcing demotion of rights once granted:
    - The `Toggle Privileges` option selected from the Dock icon will revoke rights after a set number of minutes
    - However, if Privileges is invoked via any other method (launching the .app from Dock, executing the CLI, etc.), there is no built-in timer to expire rights 
    - Additionally, if the `RequireAuthentication` or `ReasonRequired` keys are set, the Dock toggle ability is disabled outright

### Functionality

- Using this code, an IT admin can automatically set the current user's rights back to standard no matter how they were granted or which preference keys are enabled
    - **IMPORTANT**: There is one exception: if the `EnforcePrivileges` key is set with any value, that disables `PrivilegesCLI` and overrides this code's ability to demote users
- This program first checks the console user's privilege level (if one is logged in)
- Then, using the `PrivilegesCLI` within `Privileges.app`, demotes the user if they are an admin after a set number of minutes

### Workflow

1. Launch Agent runs in the background and invokes the privilegeschecker.zsh script every 30 seconds
2. `privilegeschecker` validates if the current console user is an admin
3. If no, the script takes no further action and exits
4. If yes, the script waits for the specified number of minutes before revoking administrative rights

## PREREQS

- SAP Privileges Auto App is installed
    - This can also be used with [Privileges sourced directly from the vendor](https://github.com/SAP/macOS-enterprise-privileges/releases)
- *OPTIONAL*: Configuration Profile deployed with `DockToggleTimeout` key value set under the preference domain `corp.sap.privileges` ([see here](https://github.com/SAP/macOS-enterprise-privileges/blob/main/application_management/example_profiles/DockToggleTimeout/Example_DockToggleTimeout.mobileconfig) for an example profile)
    - `USE_PROFILE_TIMEOUT` option must be set to `True` in `install_privileges_checker.zsh` to use this profile value for enforcing timeout 
    - If Configuration Profile is not found and/or `DockToggleTimeout` key not present, rights revocation will fall back to the local `MINUTES_TO_WAIT` definition set within `install_privileges_checker.zsh`
    - **NOTE:** If Privileges is configured with the `DockToggleTimeout` payload, but Privileges Checker is not deployed, timed rights revocation will *only* occur if a user right-clicks the Privileges Dock icon and selects `Toggle privileges`

## USAGE

- While we strongly encourage deploying Privileges Checker with an audit and remediation workflow, it is possible to deploy alone as an audit script:
    - **For audit and remediation**:
        - Add a new library item and select custom script
        - Below the audit script field, click **Add Remediation Script**
        - Copy and paste `audit_privileges_checker.zsh` from this repo into the audit script field
        - Copy and paste `install_privileges_checker.zsh` from this repo into the remediation script field 
        - Scope your script, set execution frequency (recommended is **every 15 minutes** or **daily**), and hit save
    - **For audit only**:
        - Add a new library item and select custom script
        - Copy and paste `install_privileges_checker.zsh` from this repo into the audit script field 
        - Scope your script, set execution frequency (recommended is **once per device**), and hit save
- The `install_privileges_checker.zsh` code will create the enforcement script and Launch Agent
- The Launch Agent will immediately activate if a user is logged in, otherwise trigger at next login
    - Launch Agent runs every 30 seconds and will revoke rights after the timeout set via Config Profile or in the local script
    - **WARNING:** Since this immediately activates, it *will* revoke rights for the console user after set timeout has expired

## TROUBLESHOOTING

- Both Privileges Checker and Privileges Checker Audit write to the Unified Log and print to stdout
    - To see in real time what Privileges Checker and Audit is doing behind the scenes, run: `/usr/bin/log stream --predicate 'eventMessage CONTAINS "Privileges Checker"'`
        - This will return logs for both `Privileges Checker` and `Privileges Checker Audit` as they are written
    - To see a historical record of Privileges Checker and Audit, run: `/usr/bin/log show --predicate 'eventMessage CONTAINS "Privileges Checker"' --last 30m`
        - This will return logs for both `Privileges Checker` and `Privileges Checker Audit` from the last 30 minutes of activity

## CHANGELOG

- (1.0.1)
   - Modified the `remove_privs_function` so that it can both remove or add admin privileges
   - Updated the function name to `modify_user_privileges`
- (1.0.2)
   - Bug fix where current user uid was unabled to be determined in some edge cases
   - Some additional code refactoring
- (1.0.3)
   - Changed time to wait to minutes
- (1.0.4)
   - Added support for Config Profile key/value pair
   - Added script execution timeout
   - Improved method for deriving current user
   - Improved logging
   - Improved security for agent and script
