# CrowdStrike README

<img src="_Images/CrowdStrike.png" alt="drawing" width="128"/>

Resources to aid in the deployment of the [CrowdStrike deployment KB](https://support.kandji.io/support/solutions/articles/72000560521)

## Status of the things

Item | Status
:-- | :--:
Last updated | 2024.10.14
Last version tested | 7.18.18701.0
Settings mobileconfig profiles | `pass`
AE script | `pass`
pre-install script | NA
post-install script | `pass`
installer package dl instructions | `pass`
kb article | `pass`

## Configuration profile settings snippets

### Notifications

```xml
<key>PayloadType</key>
<string>com.apple.notificationsettings</string>
<key>NotificationSettings</key>
<array>
	<dict>
		<key>BundleIdentifier</key>
		<string>com.crowdstrike.falcon.UserAgent</string>
		<key>NotificationsEnabled</key>
		<true/>
	</dict>
</array>
```

### System extension

```xml
<key>PayloadType</key>
<string>com.apple.system-extension-policy</string>
<key>AllowUserOverrides</key>
<true/>
<key>AllowedSystemExtensionTypes</key>
<dict>
	<key>X9E956P446</key>
	<array>
		<string>EndpointSecurityExtension</string>
		<string>NetworkExtension</string>
	</array>
</dict>
<key>AllowedSystemExtensions</key>
<dict>
	<key>X9E956P446</key>
	<array>
		<string>com.crowdstrike.falcon.Agent</string>
	</array>
</dict>
```

```xml
<key>PayloadType</key>
<string>com.apple.system-extensions.admin</string>
<key>AllowedTeamIdentifiers</key>
<array>
	<string>X9E956P446</string>
</array>
```

Additional settings for macOS 15 onwards

```xml
<key>NonRemovableFromUISystemExtensions</key>
<dict>
	<key>X9E956P446</key>
	<array>
		<string>com.crowdstrike.falcon.Agent</string>
	</array>
</dict>
```

### Web content filter

```xml
<key>PayloadType</key>
<string>com.apple.webcontent-filter</string>
<key>FilterType</key>
<string>Plugin</string>
<key>PluginBundleID</key>
<string>com.crowdstrike.falcon.App</string>
<key>UserDefinedName</key>
<string>Falcon</string>
<key>FilterBrowsers</key>
<false/>
<key>FilterDataProviderBundleIdentifier</key>
<string>com.crowdstrike.falcon.Agent</string>
<key>FilterDataProviderDesignatedRequirement</key>
<string>identifier "com.crowdstrike.falcon.Agent" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13] and certificate leaf[subject.OU] = "X9E956P446"</string>
<key>FilterGrade</key>
<string>inspector</string>
<key>FilterPacketProviderBundleIdentifier</key>
<string>com.crowdstrike.falcon.Agent</string>
<key>FilterPacketProviderDesignatedRequirement</key>
<string>identifier "com.crowdstrike.falcon.Agent" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13] and certificate leaf[subject.OU] = "X9E956P446"</string>
<key>FilterPackets</key>
<false/>
<key>FilterSockets</key>
<true/>
``` 

### Kernel extension

```xml
<key>PayloadType</key>
<string>com.apple.syspolicy.kernel-extension-policy</string>
<key>AllowedTeamIdentifiers</key>
<array>
	<string>X9E956P446</string>
</array>
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
			<true/>
			<key>CodeRequirement</key>
			<string>identifier "com.crowdstrike.falcon.Agent" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = X9E956P446</string>
			<key>Comment</key>
			<string>
			</string>
			<key>Identifier</key>
			<string>com.crowdstrike.falcon.Agent</string>
			<key>IdentifierType</key>
			<string>bundleID</string>
			<key>StaticCode</key>
			<false/>
		</dict>
		<dict>
			<key>Allowed</key>
			<true/>
			<key>CodeRequirement</key>
			<string>identifier "com.crowdstrike.falcon.App" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = X9E956P446</string>
			<key>Comment</key>
			<string>
			</string>
			<key>Identifier</key>
			<string>com.crowdstrike.falcon.App</string>
			<key>IdentifierType</key>
			<string>bundleID</string>
			<key>StaticCode</key>
			<false/>
		</dict>
	</array>
</dict>
<key>BluetoothAlways</key>
<array>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>Authorization</key>
		<string>Allow</string>
		<key>CodeRequirement</key>
		<string>identifier "com.crowdstrike.falcon.Agent" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = X9E956P446</string>
		<key>Identifier</key>
		<string>com.crowdstrike.falcon.Agent</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
	<dict>
		<key>Allowed</key>
		<true/>
		<key>Authorization</key>
		<string>Allow</string>
		<key>CodeRequirement</key>
		<string>identifier "com.crowdstrike.falcon.App" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = X9E956P446</string>
		<key>Identifier</key>
		<string>com.crowdstrike.falcon.App</string>
		<key>IdentifierType</key>
		<string>bundleID</string>
		<key>StaticCode</key>
		<false/>
	</dict>
</array>
```

### macOS 13 - background settings

Note: set assignment rule to `OS Version` is greater than or equal to `13.0`

```xml
<key>PayloadType</key>
<string>com.apple.servicemanagement</string>
<key>Rules</key>
<array>
	<dict>
		<key>RuleType</key>
		<string>TeamIdentifier</string>
		<key>RuleValue</key>
		<string>X9E956P446</string>
		<key>Comment</key>
		<string>CrowdStrike Team ID</string>
	</dict>
</array>
```

## Downloading the package

Download the installer package for Mac from your [CrowdStrike portal](https://falcon.crowdstrike.com/login/) by navigating to **Hosts** > **Sensor Downloads**.

## Resources
- [CrowdStrike Support](https://supportportal.crowdstrike.com/s/login)
- [CrowdStrike Article Regarding Bluetooth Support](https://supportportal.crowdstrike.com/s/article/Release-Notes-Falcon-Sensor-for-Mac-7-17-18604)
- [New MDM Requirements for macOS Sequoia](https://supportportal.crowdstrike.com/s/article/Tech-Alert-Support-for-macOS-Sequoia-15-0-1)
