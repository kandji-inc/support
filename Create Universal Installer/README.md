# Create Universal Installer

## ABOUT
- `ZSH` program will create a combined Universal macOS Installer component package (`.pkg`)
- Builds from separate Apple silicon and Intel `.app` bundles for the same title
- Program supports download URLs for either two `.zip` files or two `.dmg` files, both containing `.app` bundles
- Code will validate Apple silicon executable type is `arm64` and Intel `x86_64` prior to build
- Package contains logic to place the native `.app` in `/Applications` for the proper Mac architecture
- Includes required security validation of the Developer ID authority and the Team Identifier for the `.app` 
- Includes optional checks to confirm versions and bundle IDs match between the two `.app` bundles (default)
    - Can be disabled for titles with differing versions between architectures

### Background 
- With Apple's hardware transition from Intel processors to Apple silicon in Mac computers, most vendors have rewritten their software to run natively on this new architecture
- Numerous vendors have rewritten their apps to be **Universal**, capable of running on either Intel or Apple silicon chips
    - These Universal titles are straightforward to deploy, since the app will run on any modern Mac, regardless of processor type
- Others have opted to release architecture-specific installs, either capable of running on a Mac with Apple silicon, or an Intel-based Mac, *but not both*
    - This introduces added complexity for MacAdmins with mixed fleets
        - They must scope the correct architecture type to be delivered to the proper chipset for their Mac computers
        - Alternatively, they can install the Intel `.app` on all Macs in their environment
            - With translation of the `.app` via Rosetta 2, it will typically run on Apple silicon, but deliver subpar performance and extra power consumption relative to the native `.app`

---

- In short, this project aims to:
    - Enable users of any technical ability to easily create a deployable Universal package for apps that do not publish Universal binaries
        - Given download URLs for two `.zip` or `.dmg` files both containing a `.app`
        - Using tools that ship with any version of macOS
        - That can be deployed en masse via any macOS software distribution tool
        - Providing an easy method to bundle and distribute separate architecture installs with reduced complexity

## USAGE
`/bin/zsh /path/to/create_universal_package.zsh`

- Can be run with the following flags
    - `--help`: displays help with usage instructions and exits
    - `--nomatch`: disables the requirement that version + bundle IDs must match across the `.app` bundles
        - If flag is set, the version associated with the built `.pkg` will be that of the Apple silicon `.app`
    - `--verbose`: runs the script with `set -x`, delivering very verbose output during execution

- Values can be hardcoded prior to script execution, or entered interactively if left blank
    - See [Required Values](#Required-Values) below for more information

### Required Values
- `application_name` 
    - Name of the app
        - Used to name the constructed Universal PKG
        - Used to name the (optionally created) dedicated script, directly invocable in the future to build a Universal package for the desired title
- `apple_download` 
    - URL download location to a `.zip` or `.dmg` containing a `.app` built for Apple silicon (`arm64`)
        - Code will validate application bundle sourced from `apple_download` will run natively on Apple silicon hardware
- `intel_download` 
    - URL download location to a `.zip` or `.dmg` containing a `.app` built for Intel arch (`x86_64`)
        - Code will validate application bundle sourced from `intel_download` will run natively on Intel-based hardware
- `dev_id_authority` 
    - Used to validate security of the Developer ID Authority matches the downloaded `.app` bundles
        - Can be identified/populated by running the below against the desired .app
        - `/usr/bin/codesign -dvv "/Applications/EXAMPLE.app" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs`
- `team_identifier` 
    - Used to validate security of the Team Identifier matches the downloaded `.app` bundles 
        - Can be identified/populated by running the below against the desired .app
            - `/usr/bin/codesign -dvv "/Applications/EXAMPLE.app" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2`
- `match_versions` 
    - By default, package will only build if both Intel + Apple silicon `.app` bundles have identical versions and bundle identifiers
    - To disable this functionality, (e.g. for apps with differing version #s between archs), set this `false`
    - If set to `false`, the version associated with the built `.pkg` will be that of the Apple silicon `.app`

### NOTE 
**Any or all of these values can be left blank and populated interactively when the script is run**
- If either security variable is undefined, the script will run and report the `codesign` output from the downloaded `.app` bundles
    - If the source is trusted for the provided download, that value can be copied/pasted into the input prompt for Dev ID and/or Team ID
- If at least one value is populated interactively, the program will offer to create a new script named with
    - `application_name_` as a prefix (e.g. `EXAMPLE_create_universal_package.zsh`)
    - The CLI inputted values written as hardcoded variable definitions in the new script
- If a script prefixed with `application_name_` already exists in the same directory, the program will prompt to update any values provided interactively
- This is to facilitate faster testing/construction of Universal packages for dedicated apps

## PERMISSIONS
- Group permissions for the `.app` copied into `/Applications` should not be modified from how they were originally set by the vendor
- Owner permissions will be `root` due to package installation occurring with elevated permissions

## CHANGELOG
- (1.0.0)
   - Initial publication

## CREDITS
- This project takes inspiration from [AutoPkg](https://github.com/autopkg/autopkg)
