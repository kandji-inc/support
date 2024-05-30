# Sophos Endpoint README

<img src="_Images/Sophos.png" alt="drawing" width="128"/>

Resources to aid in the deployment of the [Sophos Endpoint deployment KB](https://support.kandji.io/support/solutions/articles/72000560513)

## Status of the things

Item | Status
:-- | :--
Last updated | 2024.05.29
latest version tested | `1.7.0`
Settings mobileconfig profiles | `pass`
AE script | `pass`
pre-install script | NA
post-install script | `pass`
installer package dl instructions | `pass`
kb article | `pass`

## Configuration profile settings snippets

### Notifications

```xml
<key>NotificationSettings</key>
	<array>
		<dict>
			<key>BundleIdentifier</key>
			<string>com.sophos.endpoint.uiserver</string>
			<key>NotificationsEnabled</key>
			<true/>
		</dict>
		<dict>
			<key>BundleIdentifier</key>
			<string>com.sophos.enc.sophos-encryption-agent</string>
			<key>NotificationsEnabled</key>
			<true/>
		</dict>
	</array>
</key>
```

### System extension

```xml
<key>PayloadType</key>
<string>com.apple.system-extension-policy</string>
<key>AllowUserOverrides</key>
<true/>
<key>AllowedTeamIdentifiers</key>
	<array>
		<string>2H5GFH3774</string>
	</array>
```

### Kernel extension

```xml
<key>PayloadType</key>
<string>com.apple.syspolicy.kernel-extension-policy</string>
<key>AllowUserOverrides</key>
<true/>
<key>AllowedSystemExtensions</key>
<dict>
	<key>2H5GFH3774</key>
	<array>
		<string>com.sophos.endpoint.networkextension</string>
		<string>com.sophos.endpoint.scanextension</string>
	</array>
</dict>
```

### PPPC

```xml
<key>PayloadType</key>
<string>com.apple.TCC.configuration-profile-policy</string>
<key>Services</key>
<dict>
	<key>SystemPolicyAllFiles</key>
	<key>SystemPolicyAllFiles</key>
	<array>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.endpoint.scanextension" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.endpoint.scanextension</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.liveresponse" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>Sophos Central only</string>
		<key>Identifier</key>
		<string>com.sophos.liveresponse</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.autoupdate" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>Sophos OPM only</string>
		<key>Identifier</key>
		<string>com.sophos.autoupdate</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.macendpoint.CleanD" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.macendpoint.CleanD</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.SophosScanAgent" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.SophosScanAgent</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.macendpoint.SophosServiceManager" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.macendpoint.SophosServiceManager</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.endpoint.uiserver" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>Sophos Central only</string>
		<key>Identifier</key>
		<string>com.sophos.endpoint.uiserver</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.SDU4OSX" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.SDU4OSX</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.endpoint.SophosAgent" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.endpoint.SophosAgent</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.sophos.SophosAntiVirus" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.sophos.SophosAntivirus</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>CodeRequirement</key>
		<string>identifier "com.Sophos.macendpoint.SophosSXLD" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "2H5GFH3774"</string>
		<key>Comment</key>
		<string>All Sophos products</string>
		<key>Identifier</key>
		<string>com.Sophos.macendpoint.SophosSXLD</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
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
	<string>2H5GFH3774</string>
	<key>Comment</key>
	<string>Sophos Team ID</string>
</dict>
</array>
```

## Downloading the package

1. Login to your **[Sophos Admin Portal](https://central.sophos.com/manage/login)**.
1. Go to **Devices > Installers**.
1. Under **Endpoint Protection**, click **Download Complete macOS Installer**.

## Resources
- [macOS Ventura known compatability issues](https://support.sophos.com/support/s/article/KB-000044555?language=en_US&c__displayLanguage=en_US)
- [Sophos Support Portal](https://support.sophos.com/)