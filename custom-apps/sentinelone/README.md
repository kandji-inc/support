# SentinelOne README

<img src="_Images/SentinelOne.png" alt="drawing" width="128"/>

Resources to aid in [Deploying SentinelOne as a Custom App](https://support.kandji.io/support/solutions/articles/72000560520-deploying-sentinelone-as-a-custom-app)

## Status of the things

Item | Status
:-- | :--
Last updated | 2024.03.22
AE script | `pass`
pre-install script | `pass`
post-install script | `pass`
kb article | `pass`

## Configuration profile settings snippets

### Notifications

```xml
<key>NotificationSettings</key>
<array>
	<dict>
		<key>AlertType</key>
		<integer>2</integer>
		<key>BadgesEnabled</key>
		<true/>
		<key>BundleIdentifier</key>
		<string>com.sentinelone.SentinelAgent</string>
		<key>CriticalAlertEnabled</key>
		<false/>
		<key>NotificationsEnabled</key>
		<true/>
		<key>PreviewType</key>
		<integer>0</integer>
		<key>ShowInCarPlay</key>
		<false/>
		<key>ShowInLockScreen</key>
		<false/>
		<key>ShowInNotificationCenter</key>
		<true/>
		<key>SoundsEnabled</key>
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
<key>AllowedTeamIdentifiers</key>
	<array>
		<string>4AYE5J54KN</string>
	</array>
```

### Webcontent Filter
```xml
<key>PayloadType</key>
<string>com.apple.webcontent-filter</string>
<key>PluginBundleID</key>
<string>com.sentinelone.extensions-wrapper</string>
<key>FilterDataProviderBundleIdentifier</key>
<string>com.sentinelone.network-monitoring</string>
<key>FilterDataProviderDesignatedRequirement</key>
<string>anchor apple generic and identifier "com.sentinelone.network-monitoring" and (certificate leaf[field.1.2.840.113635.100.6.1.9] or certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13] and certificate leaf[subject.OU] = "4AYE5J54KN")</string>
<key>FilterPackets</key>
<false/>
<key>FilterSockets</key>
<true/>
<key>FilterType</key>
<string>Plugin</string>
<key>UserDefinedName</key>
<string>SentinelOne</string>
```

### PPPC

```xml
<dict>
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
				<string>anchor apple generic and identifier "com.sentinelone.sentineld" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "4AYE5J54KN")</string>
				<key>Identifier</key>
				<string>com.sentinelone.sentineld</string>
				<key>IdentifierType</key>
				<string>bundleID</string>
				<key>StaticCode</key>
				<false/>
			</dict>
			<dict>
				<key>Allowed</key>
				<true/>
				<key>CodeRequirement</key>
				<string>anchor apple generic and identifier "com.sentinelone.sentineld-helper" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "4AYE5J54KN")</string>
				<key>Identifier</key>
				<string>com.sentinelone.sentineld-helper</string>
				<key>IdentifierType</key>
				<string>bundleID</string>
				<key>StaticCode</key>
				<false/>
			</dict>
			<dict>
				<key>Allowed</key>
				<true/>
				<key>CodeRequirement</key>
				<string>anchor apple generic and identifier "com.sentinelone.sentineld-shell" and (certificate leaf[field.1.2.840.113635.100.6.1.9] or certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13] and certificate leaf[subject.OU] = "4AYE5J54KN")</string>
				<key>Identifier</key>
				<string>com.sentinelone.sentineld-shell</string>
				<key>IdentifierType</key>
				<string>bundleID</string>
				<key>StaticCode</key>
				<false/>
			</dict>
			<dict>
				<key>Allowed</key>
				<true/>
				<key>CodeRequirement</key>
				<string>anchor apple generic and identifier "com.sentinelone.sentinel-shell" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "4AYE5J54KN")</string>
				<key>Identifier</key>
				<string>com.sentinelone.sentinel-shell</string>
				<key>IdentifierType</key>
				<string>bundleID</string>
				<key>StaticCode</key>
				<false/>
			</dict>
		</array>
	</dict>
</dict>
```