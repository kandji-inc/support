# Okta Verify

## About

This is a custom mobile config profile that can be used to deploy EDR plugin configuration for Okta Verify. This configuration profile can be deployed along side the Kandji ODT integration settings.

At present, the Okta EDR integration for macOS only supports CrowdStrike ZTA. (see this[ Okta KB](https://help.okta.com/oie/en-us/content/topics/identity-engine/devices/edr-integration-plugin-macos.htm) for more details.)

## Deployment

Upload the `okta_verify_edr_plugin.mobileconfig` profile in this repo to Kandji as a [custom configuration profile](https://support.kandji.io/support/solutions/articles/72000573519-custom-profile-overview). You can right-click [this link](https://raw.githubusercontent.com/kandji-inc/support/main/Configuration%20Profiles/okta-verify/okta_verify_edr_plugin.mobileconfig) and select Save link as… to download the mobileconfig file directly.

## Payload settings

This payload covers the following preference domains.

- `com.okta.mobile.auth-service-extension`
- `com.okta.mobile`

```xml
<dict>
    <key>OktaVerify.Plugins</key>
    <array>
        <string>com.crowdstrike.zta</string>
    </array>
    <key>com.crowdstrike.zta</key>
    <dict>
		<key>name</key>
        <string>com.crowdstrike.zta</string>
        <key>description</key>
        <string>File based EDR integration between Okta Verify and the Crowdstrike Falcon agent.</string>
        <key>location</key>
        <string>/Library/Application Support/Crowdstrike/ZeroTrustAssessment/data.zta</string>
		<key>format</key>
        <string>JWT</string>
        <key>type</key>
        <string>file</string>
    </dict>
	<key>PayloadType</key>
	<string>com.okta.mobile.auth-service-extension</string>
</dict>
<dict>
    <key>OktaVerify.Plugins</key>
    <array>
        <string>com.crowdstrike.zta</string>
    </array>
    <key>com.crowdstrike.zta</key>
    <dict>
        <key>description</key>
        <string>File based EDR integration between Okta Verify and the Crowdstrike Falcon agent.</string>
        <key>format</key>
        <string>JWT</string>
        <key>location</key>
        <string>/Library/Application Support/Crowdstrike/ZeroTrustAssessment/data.zta</string>
        <key>name</key>
        <string>com.crowdstrike.zta</string>
        <key>type</key>
        <string>file</string>
    </dict>
	<key>PayloadType</key>
	<string>com.okta.mobile</string>
</dict>
```
