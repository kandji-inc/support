# Bitdefender README

<img src="bitdefender_icon.png" alt="drawing" width="128"/>

Resources to aid in the deployment of the [Bitdefender deployment KB](https://support.kandji.io/kb/deploying-bitdefender-endpoint-security-tool-as-a-custom-app)

## Status of the things

Item | Status
:-- | :--
Last updated | 2023.04.12
latest version tested | `7.14.26.200010`
Settings snippets | `pass`
Settings mobileconfig profiles | `pass`
AE script | `pass`
pre-install script | NA
post-install script | `pass`
installer package dl instructions | `pass`
certificate generation script | `pass`
kb article | `pass`

## Configuration profile settings snippets

### Notifications

```xml
<dict>
<key>NotificationSettings</key>
<array>
	<dict>
		<key>BundleIdentifier</key>
		<string>com.bitdefender.networkinstaller</string>
		<key>NotificationsEnabled</key>
		<true/>
	</dict>
	<dict>
		<key>BundleIdentifier</key>
		<string>com.bitdefender.epsecurity.BDLDaemonApp</string>
		<key>NotificationsEnabled</key>
		<true/>
	</dict>
	<dict>
		<key>BundleIdentifier</key>
		<string>com.bitdefender.EndpointSecurityforMac</string>
		<key>NotificationsEnabled</key>
		<true/>
	</dict>
</array>
</dict>
```

### System extension

```xml
<key>AllowUserOverrides</key>
<true/>
<key>AllowedSystemExtensions</key>
<dict>
	<key>GUNFMW623Y</key>
	<array>
		<string>com.bitdefender.cst.net.dci.dci-network-extension</string>
	</array>
</dict>
<key>PayloadType</key>
<string>com.apple.system-extension-policy</string>
```

### Kernel extension

```xml
<key>PayloadType</key>
<string>com.apple.syspolicy.kernel-extension-policy</string>
<key>AllowNonAdminUserApprovals</key>
<true/>
<key>AllowUserOverrides</key>
<true/>
<key>AllowedTeamIdentifiers</key>
<array>
	<string>GUNFMW623Y</string>
</array>
```

### Network content filter

```xml
<key>FilterPacketProviderBundleIdentifier</key>
<string>com.bitdefender.cst.net.dci.dci-network-extension</string>
<key>FilterPacketProviderDesignatedRequirement</key>
<string>anchor apple generic and identifier "com.bitdefender.cst.net.dci.dci-network-extension" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = GUNFMW623Y)</string>
<key>FilterPackets</key>
<true/>
<key>FilterSockets</key>
<false/>
<key>FilterType</key>
<string>Plugin</string>
<key>PayloadType</key>
<string>com.apple.webcontent-filter</string>
<key>PluginBundleID</key>
<string>com.bitdefender.epsecurity.BDLDaemonApp</string>
<key>UserDefinedName</key>
<string>Bitdefender</string>
```

### PPPC

```xml
<key>PayloadType</key>
<string>com.apple.TCC.configuration-profile-policy</string>
<key>Services</key>
<dict>
	<key>SystemPolicyAllFiles</key>
	<array>
		<dict>
			<key>Allowed</key>
			<integer>1</integer>
			<key>CodeRequirement</key>
			<string>anchor apple generic and identifier "com.bitdefender.epsecurity.BDLDaemonApp" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = GUNFMW623Y)</string>
			<key>Identifier</key>
			<string>com.bitdefender.epsecurity.BDLDaemonApp</string>
			<key>IdentifierType</key>
			<string>bundleID</string>
			<key>StaticCode</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>Allowed</key>
			<integer>1</integer>
			<key>CodeRequirement</key>
			<string>identifier "com.bitdefender.EndpointSecurityforMac" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = GUNFMW623Y</string>
			<key>Identifier</key>
			<string>com.bitdefender.EndpointSecurityforMac</string>
			<key>IdentifierType</key>
			<string>bundleID</string>
			<key>StaticCode</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>Allowed</key>
			<integer>1</integer>
			<key>CodeRequirement</key>
			<string>identifier BDLDaemon and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = GUNFMW623Y</string>
			<key>Identifier</key>
			<string>/Library/Bitdefender/AVP/BDLDaemon</string>
			<key>IdentifierType</key>
			<string>Path</string>
			<key>StaticCode</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>Allowed</key>
			<integer>1</integer>
			<key>CodeRequirement</key>
			<string>anchor apple generic and identifier "com.bitdefender.cst.net.dci.dci-network-extension" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = GUNFMW623Y)</string>
			<key>Identifier</key>
			<string>com.bitdefender.cst.net.dci.dci-network-extension</string>
			<key>IdentifierType</key>
			<string>bundleID</string>
			<key>StaticCode</key>
			<integer>0</integer>
		</dict>
	</array>
</dict>
```

### macOS 13 - background settings

Note: set assigment rule to `OS Version` is greater than or equal to `13.0`

```xml
<key>PayloadType</key>
<string>com.apple.servicemanagement</string>
<key>Rules</key>
<array>
	<dict>
		<key>RuleType</key>
		<string>TeamIdentifier</string>
		<key>RuleValue</key>
		<string>GUNFMW623Y</string>
		<key>Comment</key>
		<string>Bitdefender Team ID</string>
	</dict>
</array>
```

## Downloading the package

1. Login to [Bitdefender gravity zone](https://gravityzone.bitdefender.com/).
1. On the left-hand navigation under Network, click **Packages**.
1. Click **Add**.
1. Configure settings for the installer. (make sure to set an uninstall password - this password will also be used in the create of the [certificate](https://www.bitdefender.com/business/support/en/77209-157498-install-security-agents---use-cases.html#UUID-00e93090-1040-8119-d7cf-c48320a8d6b7) used by Bitdender), click **Save**.
1. Select the package that was just built and click **Download**.
1. Select the install type, if deploying to both Intel and Apple Silicon devices download both installers.

## Using the bitdefender_cert_generator.zsh script

Bitdefender requires that a PFX certificate be created and deployed to macOS. This section is based on this <a href="https://www.bitdefender.com/business/support/en/77209-157498-install-security-agents---use-cases.html#UUID-00e93090-1040-8119-d7cf-c48320a8d6b7"> Bitdefender KB</a>. Please see the KB article for more information.

This script can be used to generate a `.pfx` certificate that can be uploaded to Kandji in a [Certificate profile library item](https://support.kandji.io/kb/certificate-profile).

1. Open the script in a text editor or IDE like VScode, BBEdit, or Nova.
1. Fill in the certificate information section of the script.

    ```bash
    ################################################################################################
    ####################################### VARIABLES ##############################################
    ################################################################################################
    
    # Cert info
    COUNTRY=""                               # US - 2 letter country code
    STATE=""                                 # Georgia - state or province
    LOCAL=""                                 # Atlanta - locality name
    ORG_NAME="Endpoint"                      # Leave as default
    CERT_NAME="Kandji Bitdenfender CA SSL"   # Leave as default
    ```

1. Save the updated script to your Desktop.
1. Open **Terminal.app**.
1. Enter `zsh` and then drag the script file into the window.

    It should look something like this.

    ```text
    zsh '/Users/<your_username>/Desktop/bitdefender/bitdefender_cert_generator.zsh'
    ```

1. When prompted, enter and verify the password used in the Bitdefender installer settings you defined in your Bitdefender portal.
1. When the script is finished, you should see the password hash used to generate the certificate. Copy this hash and paste it in the password field when creating the Certificate library item in Kandji.

    ```text
    Password hash: 626cacdec63355c2680dbd6747c8d755
    ```

1. A Finder.app window should open to your Desktop, showing the `certificate.pfx` file.
1. Upload this certificate to Kandji in a [Certificate profile library item](https://support.kandji.io/kb/certificate-profile).

## Resources

- [Bitdefender certificate requirements](https://www.bitdefender.com/business/support/en/77209-157498-install-security-agents---use-cases.html#UUID-00e93090-1040-8119-d7cf-c48320a8d6b7)
- macOS Big Sur+ considerations - https://www.bitdefender.com/support/changes-to-bitdefender-endpoint-security-for-mac-in-macos-big-sur-2626.html
