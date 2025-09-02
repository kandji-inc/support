# Microsoft Defender Kandji Exclusions

> [!WARNING]
> A recent issue with Microsoft Defender for Endpoint on macOS ignores valid tamper protection exclusions, resulting in failures when applying a client upgrade
>
> Defender `101.25072.0011` and later includes a fix for this issue, but may require temporarily setting `tamper-protection` to `disabled` or `audit` in order to apply this update (see [Microsoft's docs to update tamper protection](https://learn.microsoft.com/en-us/defender-endpoint/tamperprotection-macos#configure-tamper-protection-on-macos-devices))

## ABOUT

`add_kandji_exclusions.zsh` automatically adds Microsoft Defender tamper protection exclusions for Kandji components to macOS configuration profile (`.mobileconfig`) files, enabling Kandji to manage Microsoft Defender updates and installations.

> [!IMPORTANT]
> This script only supports **Microsoft Defender for Mac** configuration profiles, where [tamper protection is configured and enforced via MDM](https://learn.microsoft.com/en-us/defender-endpoint/mac-preferences#tamper-protection)
>
> The script will validate that the profile contains the expected payload type (`com.microsoft.wdav`) before making any modifications

### Background

- Microsoft Defender's tamper protection can interfere with legitimate system management tools like Kandji
- Without proper exclusions, Kandji components may be flagged as suspicious or blocked from functioning, potentially preventing Microsoft Defender updates and installations
- This script automatically adds the necessary exclusions to prevent false positives while maintaining security

### Functionality

- IT admins can automatically add tamper protection exclusions for required Kandji components
- This script creates timestamped backups before making any changes and handles existing exclusions to avoid duplicates
- Supports both interactive (drag-and-drop) and command-line usage modes

#### What Gets Added

This script updates an existing configuration profile to exclude the below services from tamper protection:

- `kandji-cli` - Kandji Command Line Interface
- `kandji-daemon` - Kandji Background Service
- `kandji-library-manager` - Kandji Library Management Component

Each exclusion includes:
- **signingId**: The component's unique identifier
- **path**: Full path to the binary
- **teamId**: Kandji's Apple-issued team identifier

### Workflow

1. The IT admin provides a Microsoft Defender `.mobileconfig` file (via drag-and-drop or command line)
2. The script validates the file and creates a backup
3. Existing exclusions are scanned and analyzed
4. New Kandji exclusions are added only if they don't already exist
5. Partial matches are identified and resolved
6. A summary of operations is displayed
7. Upload and deploy the updated `.mobileconfig` in their Kandji tenant

## PREREQS

- Must be run on macOS
- Microsoft Defender configuration profile (`.mobileconfig`) file

## USAGE

### Interactive Mode
From a Terminal session, invoke the script without any arguments.
```
zsh ./add_kandji_exclusions.zsh
```
The script will prompt you to drag and drop a `.mobileconfig` file.

### Command Line Mode
From a Terminal session, invoke the script followed by your `.mobileconfig` path

```
zsh ./add_kandji_exclusions.zsh /path/to/profile.mobileconfig
```

## TROUBLESHOOTING

### Common Issues

1. **"Incorrect PayloadType"**: Ensure you're using a Microsoft Defender profile
2. **"Failed to create backup"**: Check file permissions
3. **"File is not valid"**: Ensure the file has a `.mobileconfig` extension

### Verification

After running the script, you can verify the exclusions were added by:
1. Opening the modified `.mobileconfig` file in an IDE or text editor
2. Checking the `tamperProtection.exclusions` array
3. Verifying each Kandji component has proper `path`, `signingId`, and `teamId` values

### Expected Results

After successful execution, you should see one of these messages:

- **"Successfully Added All Kandji Exclusions"** - All exclusions were added
- **"All Kandji Exclusions Already Exist"** - No changes needed
- **"Partially Added Kandji Exclusions"** - Some exclusions were added, others already existed

## RELATED DOCUMENTATION

- [Microsoft Defender for Mac Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/microsoft-defender-endpoint-mac)
- [Tamper Protection for macOS](https://learn.microsoft.com/en-us/defender-endpoint/tamperprotection-macos)
- [Tamper Protection FAQ](https://learn.microsoft.com/en-us/defender-endpoint/faqs-on-tamper-protection)

## CHANGELOG

- (1.0.0) - Initial release by Noah Anderson
- (Updated) - Enhanced by Daniel Chapa with improved exclusion handling and partial match resolution
