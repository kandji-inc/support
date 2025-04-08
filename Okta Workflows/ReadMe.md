# Kandji Connector Action Card Details
You can use the Kandji connector to integrate Kandji device management with Okta Workflows to help automate critical components of the user lifecycle that are prone to friction or manual error.

The first step is to [Authorize your Kandji tenant for Okta Workflows](https://support.kandji.io/kb/authorize-your-kandji-tenant-for-okta-workflows).

After you set up a Kandji connection, you can use the following Kandji connector action cards in a Workflow.

The following actions are available, full details are provided further below.
* [Custom API Action](#Custom-API-Action)
* [Clear Passcode](#Clear-Passcode)
* [Create Blueprint](#Create-Blueprint)
* [Create Note](#Create-Note)
* [Erase Device](#Erase-Device)
* [Get ADE Integration](#Get-ADE-Integration)
* [Get Activation Lock Bypass Codes](#Get-Activation-Lock-Bypass-Codes)
* [Get Blueprint](#Get-Blueprint)
* [Get Device](#Get-Device)
* [Get FileVault Recovery Key](#Get-FileVault-Recovery-Key)
* [Get Mac Unlock PIN](#Get-Mac-Unlock-PIN)
* [List ADE Integrations](#List-ADE-Integrations)
* [List ADE Devices](#List-ADE-Devices)
* [List Blueprints](#List-Blueprints)
* [List Device Apps](#List-Device-Apps)
* [List Device Library Items](List-Device-Library-Items)
* [List Device Notes](#List-Device-Notes)
* [List Devices](#List-Devices)
* [Lock Device](#Lock-Device)
* [Manage Apple Remote Desktop](#Manage-Apple-Remote-Desktop)
* [Play Lost Mode Sound](#Play-Lost-Mode-Sound)
* [Reinstall Kandji Agent](#Reinstall-Kandji-Agent)
* [Restart Device](#Restart-Device)
* [Send MDM Blank Push](#Send-MDM-Blank-Push)
* [Set Device Name](#Set-Device-Name)
* [Shutdown Device](#Shutdown-Device)
* [Turn Off Lost Mode](#Turn-Off-Lost-Mode)
* [Turn On Lost Mode](#Turn-On-Lost-Mode)
* [Unlock Local User Account](#Unlock-Local-User-Account)
* [Update Device](#Update-Device)
* [Update Inventory](#Update-Inventory)
* [Update Lost Mode Location](#Update-Lost-Mode-Location)
---

### Custom API Action
Make an authenticated HTTP request to the Kandji API.

> **Note**: This action is unlike other Kandji cards; refer to [Kandji's API documentation](https://api-docs.kandji.io/).

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Request Type | Supported HTTP methods: <br>- **GET**: Retrieves data from web service. Returns 200 OK on success <br>- **POST**: Sends data to web service (e.g. file upload). Returns 200 OK on success <br>- **PUT**: Stores data at specific location (idempotent). Returns 200/201/204 <br>- **PATCH**: Partial modifications. Returns 200/204 <br>- **DELETE**: Removes resource. Returns 200 OK | Dropdown | TRUE |

**Inputs**
| Field | Definition | Type | Required |
|---|---|---|---|
| Relative URL | Specify the relative URL to the API following `/v1` | String | TRUE |
| Query | Additional query parameters in object format | Object | FALSE |
| Headers | Additional headers beyond authorization/content-type | Object | FALSE |
| Body | Request body in JSON format | Object | FALSE |

**Outputs**
| Field       | Definition                                                                               | Type   |
|-------------|-------------------------------------------------------------------------------------------|--------|
| Status Code | HTTP status code indicating operation result                                              | Number |
| Headers     | Response headers (e.g. `{"Content-type":"application/json"}`)                             | Object |
| Body        | Data returned from request                                                               | Object |

---

### Clear Passcode
Clear the iOS or iPadOS device passcode.

**Input**
| Field    | Description                                      | Type   | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of iOS/iPadOS device | String | TRUE     |

**Output**
| Field       | Description                                                                 | Type   |
|-------------|-----------------------------------------------------------------------------|--------|
| Status Code | Operation result with detailed status explanations                         | Text   |

---

### Create Blueprint
Create a Blueprint.

**Inputs**
| Field                  | Description                                                                 | Type    | Required |
|------------------------|-----------------------------------------------------------------------------|---------|----------|
| Name                   | Unique blueprint name                                                      | String  | TRUE     |
| Enrollment Code Active | Enable manual enrollment                                                   | Boolean | TRUE     |
| Enrollment Code        | Custom enrollment code (auto-generated if empty)                           | String  | FALSE    |
| Color                  | Blueprint color code                                                       | String  | FALSE    |
| Description            | Blueprint description                                                      | String  | FALSE    |
| Icon                   | Blueprint icon code                                                        | String  | FALSE    |

**Outputs**
| Field               | Description                     | Type   |
|---------------------|---------------------------------|--------|
| Blueprint           | New blueprint object            | Object |
| Status Code         | Creation operation status       | Number |

---

### Create Note
Create a note in Kandji for the device.

**Inputs**
| Field     | Description                                                                 | Type   | Required |
|-----------|-----------------------------------------------------------------------------|--------|----------|
| Device ID | Kandji-specific device ID of iOS/iPadOS device to send MDM command | String | TRUE     |
| Note      | Text contents of the note                                                  | String | TRUE     |

**Outputs**
| Field       | Description                                                                 | Type   |
|-------------|-----------------------------------------------------------------------------|--------|
| Status Code | Operation result with HTTP status codes and explanations                   | Number |
| Note        | JSON object containing the created note details                             | Object |

---

### Erase Device
Send Erase Device MDM command.

**Inputs**
| Field             | Description                                      | Type          | Required          |
|-------------------|--------------------------------------------------|---------------|-------------------|
| Device ID         | Kandji-specific device ID         | String        | TRUE              |
| PIN               | 6-digit unlock code (macOS only)                | Number        | TRUE (macOS)      |
| PreserveDataPlan  | Maintain cellular plan (iOS/iPadOS only)         | Boolean       | TRUE (iOS/iPadOS) |
| DisallowProximity | Block proximity setup (iOS/iPadOS only)          | Boolean       | TRUE (iOS/iPadOS) |

**Outputs**
| Field       | Description                          | Type   |
|-------------|--------------------------------------|--------|
| Status Code | Operation result code and explanation| Number |
| PIN         | Generated unlock code                | String |

---

### Get ADE Integration
Given an Automated Device Enrollment (ADE) integration token, return information about the integration.

**Input**
| Field        | Description                          | Type   | Required |
|--------------|--------------------------------------|--------|----------|
| ADE Token ID | ID of Automated Device Enrollment Token | String | TRUE     |

**Outputs**
| Field                          | Description                          | Type   |
|--------------------------------|--------------------------------------|--------|
| Default Blueprint ID           | Blueprint ID                         | String |
| Default Blueprint Name         | Blueprint name                       | String |
| Default Blueprint Color        | Blueprint color code                 | String |
| Default Blueprint Icon         | Blueprint icon code                  | String |
| Access Token Expiry            | Token expiration date                | Date   |
| Server Name                    | Kandji server name                   | String |
| Server UUID                    | Server unique identifier             | String |
| Organization Name              | Organization name                    | String |
| Organization Email             | Organization contact email          | String |
| Organization Phone             | Organization contact phone          | String |
| Stoken File Name               | Security token file name             | String |
| Last Device Sync              | Last sync timestamp                  | Date   |
| Default Email                  | Default contact email                | String |
| Default Phone                  | Default contact phone                | String |
| Days Left                      | Days until token expiration          | Number |
| Status                         | Integration status                   | String |
| Status Reason                  | Status details                       | String |
| Status Received At             | Status timestamp                     | Date   |
| Apple TV Device Count         | Number of Apple TV devices           | Number |
| iPad Device Count              | Number of iPad devices               | Number |
| iPhone Device Count           | Number of iPhone devices             | Number |
| Mac Device Count              | Number of Mac devices                | Number |
| Total Device Count            | Total managed devices                | Number |

---

### Get Activation Lock Bypass Codes
Get the Activation Lock Bypass Code for a Mac.

**Input**
| Field     | Description                          | Type   | Required |
|-----------|--------------------------------------|--------|----------|
| Device ID | Kandji-specific Mac device ID        | String | TRUE     |

**Outputs**
| Field                                   | Description                          | Type   |
|-----------------------------------------|--------------------------------------|--------|
| User-Based Activation Lock Bypass Code | For personal Apple ID locks          | String |
| Device-Based Activation Lock Bypass Code| For MDM-enabled device locks        | String |

---

### Get Blueprint
Get a Blueprint by Blueprint ID or by name.

**Input**
| Field          | Description                          | Type   | Required |
|----------------|--------------------------------------|--------|----------|
| Blueprint ID   | Unique blueprint identifier          | String | FALSE    |
| Blueprint Name | Blueprint display name               | String | FALSE    |

**Outputs**
| Field                  | Description                          | Type   |
|------------------------|--------------------------------------|--------|
| Status Code            | HTTP operation result               | String |
| ID                     | Blueprint unique ID                  | String |
| Name                   | Blueprint name                      | String |
| Icon                   | Icon code reference                 | String |
| Color                  | Color code value                    | String |
| Description            | Blueprint description               | String |
| Parameters             | JSON configuration parameters        | List   |
| Count                  | Number of assigned devices          | Number |
| Missing                | Number of missing devices           | Number |
| Enrollment Code        | Manual enrollment code              | String |
| Enrollment Code Active | Code activation status              | Boolean|
| Alerts Count           | Number of active alerts             | String |

---

### Get Device
Retrieve device information.

**Options**
| Field    | Definition                          | Type     | Required |
|----------|--------------------------------------|----------|----------|
| Details  | Level of device details to return   | Dropdown | TRUE     |

**Input**
| Field    | Definition                | Type   | Required |
|----------|--------------------------|--------|----------|
| Device ID | Kandji-specific device ID | String | TRUE     |

**Outputs (Basic)**
| Field               | Description                          | Type    |
|---------------------|--------------------------------------|---------|
| Device ID           | Unique device identifier            | String  |
| Device Name         | Name of device                      | String  |
| Model               | Device model                        | String  |
| Platform            | Apple platform type                 | String  |
| OS Version          | Operating system version            | String  |
| Last Check-in       | Last MDM check-in timestamp        | Date    |

**Outputs (Full)**
| Field               | Description                          | Type    |
|---------------------|--------------------------------------|---------|
| General Info        | Device identification details       | Object  |
| MDM Status          | Management platform information      | Object  |
| Activation Lock     | Security status                      | Object  |
| FileVault           | Encryption status                    | Object  |

---

### Get FileVault Recovery Key
Get the FileVault Recovery Key for a Mac.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of a Mac | String | TRUE |

**Output**
| Field | Description | Type | 
|---|---|---|
| Key | FileVault recovery key | String |

---

### Get Mac Unlock PIN
Get the PIN for a locked Mac.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of a Mac | String | TRUE |

---

### List ADE Integrations
Return a list of configured Automated Device Enrollment (ADE) integrations.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include: <ul><li>First 200 Records.</li><li>Stream All Records. If you choose streaming, you must select a Helper Flow to run for every ADE Integration.</li></ul> | Dropdown | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON list of objects, one object per ADE Integration. <br>Appears when **First 200 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of ADE Integrations. <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List ADE Devices
Given an Automated Device Enrollment (ADE) integration token, return a list of all devices associated with that token, as well as their enrollment status. When the mdm_device key value is null, this indicates that the device is awaiting enrollment into Kandji.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | 	Whether to return results directly or to stream results. Options include:<ul><li>First 300 Records.</li><li>Stream All Records. If you choose streaming, you must select a Helper Flow to run for every ADE Device.</li></ul> | Dropdown | TRUE |

**Inputs**
| Field | Description | Type | Required |
|---|---|---|---|
| ADE Token ID | ID of ADE Token | String | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON list of objects, one object per ADE Device.<br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of ADE Devices<br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Blueprints
List Blueprints.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | 	Whether to return results directly or to stream results. Options include:<ul><li>First 200 Records.</li><li>Stream All Records. If you choose streaming, you must select a Helper Flow to run for every Blueprint.</li></ul> | Dropdown | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON list of objects, one object per Blueprint<br>Appears when **First 200 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of Blueprints<br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Device Apps
Given a Device ID, return a list of all installed apps for the device. For iOS, iPadOS, and tvOS, this lists third-party apps installed on this device. Built-in iOS, iPadOS, and tvOS apps are not inventoried.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID	| String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Apps | List of JSON objects, one object per app | List |

---

### List Device Library Items
Given a Device ID, return a list of all the Library Items and their statuses for the device.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Items List | List of JSON objects, one object per Library Item | List |

---

### List Device Notes
Given a Device ID, return a list of all the Library Items and their statuses for the device.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Items List | List of JSON objects, one object per Library Item | List |

---

### List Devices
Get a list of all enrolled devices. Optional query parameters can be specified to filter the results. All search fields are optional.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First Matching Record</li><li>First 200 Matching Records</li><li>Stream Matching Records. If you choose streaming, you must choose a Helper flow to run for every device.</li></ul> | Dropdown | TRUE |

**Inputs**
| Field | Description | Type | Required |
|---|---|---|---|
| User Email | Email address of the user associated with the device contains the specified string; this returns all email addresses that contain the string | String | FALSE |
| User Email - Exact | Exact email address of the user associated with the device | String | FALSE |
| User Name | Name of the user assigned to the device | String | FALSE |
| Kandji User ID | Kandji-specific user ID of the user assigned to the device | Number | FALSE |
| Device ID | Kandji-specific device ID	| String | FALSE |
| Device Name | Device name	| String | FALSE |
| Serial Number | Device serial number | String | FALSE |
| MAC Address | MAC Address of the primary network interface of the device | String | FALSE |
| Asset Tag | Asset tag	| String | FALSE |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String | FALSE |
| Model | Device model | String | FALSE |
| OS Version | Version of the OS | String | FALSE |
| Blueprint ID | ID of the Blueprint the device is assigned to | String | FALSE |

**Outputs for "First Matching Records"**
| Field	| Definition | Type |
|---|---|---|
| The following appear when First Matching Record is selected from the Result Set field.|
| Device ID	| Kandji-specific device ID | String |
| Device Name | Device name | String |
| Model | Device model | String |
| Serial Number | Device serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| OS Version | Version of the OS | String |
| Last Check-in | Date of last MDM check-in	| Date |
| User | JSON object for assigned Kandji user | Object |
| Asset Tag | Asset tag | String |
| Blueprint ID | Blueprint ID the device is assigned to | String |
| Agent Installed | Whether the Kandji Agent is installed | Boolean |
| Is Missing | Whether the device is missing from Kandji | Boolean |
| Is Removed | Whether the device was removed from Kandji | Boolean |
| Agent Version | Version of the Kandji Agent | String |
| First Enrollment | When the device was first enrolled with Kandji | Date |
| Last Enrollment | When the device was last enrolled with Kandji | Date |
| Blueprint Name | Name of the Blueprint the device is assigned to | String |
| Devices | JSON list of objects, one object per device.<br>Appears when *First 200 Records* is selected from the **Result Set** field. | List |

**Output for "First 200 Matching Records"**
| Field | Definition | Type |
|---|---|---|
| Devices | JSON list of objects, one object per device | List |

---

### Lock Device
Send an MDM command to lock a device. For a Mac computer, a 6-digit PIN will be returned.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the Mac computer to send the MDM command to | String | TRUE |
| Lock Message | Lock message to show on device lock screen | String | FALSE |
| Phone Number | Phone number to show on device lock screen | String | FALSE |

**Outputs**
| Field | Description | Type |
|---|---|---|
| Device ID | Kandji-specific device ID of a Mac | String |
| Device Name | Device name	| String |
| Serial Number	| Device serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| User Email | Email address of the user associated with the device | String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>200 OK</li><li>400 Bad Request: "Command already running" - The command may already be running in a Pending state waiting on the device.</li><li>401 Unauthorized: Invalid access token. This can happen if the token was revoked, the required permissions are missing, or the token has expired.</li><li>404 Not found: Unable to locate the resource in the Kandji tenant.</li</ul>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |
| Message | Message | String |
| PIN | Lock PIN for Mac computer | String |

---

### Manage Apple Remote Desktop
Use MDM to turn on or turn off Apple Remote Desktop for a Mac.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the Mac computer to send the MDM command to | String | TRUE |
| Manage Remote Desktop | Send an MDM command to control the Remote Management status on a Mac. This MDM command turns Remote Management on or off with Observe and Control permissions given to all users. | Dropdown | TRUE |

**Outputs**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<br><ul><li>200 OK</li><li>400 Bad Request (See Body below)</li><li>401 Unauthorized: Invalid access token. This can happen if the token was revoked, the required permissions are missing, or the token has expired.</li><li>404 Not found": Unable to locate the resource in the Kandji tenant.</li></ul>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | String |
| Body | Potential explanation for a 400 Bad Request result:<ul><li>"Command already running": The command may already be running in a Pending state waiting on the device.</li><li>"Command is not allowed for current device": Remote Desktop may already be in the desired configuration on the Mac or the command may not be compatible with the target device.</li></ul> | String |

---

### Play Lost Mode Sound
Send the MDM command to an iOS or iPadOS device in Lost Mode to play the Lost Mode sound. The sound plays until two minutes have elapsed, Lost Mode is turned off on the device or the user turns off the sound on the device.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of a Mac | String | TRUE |

**Outputs**
| Field | Description | Type |
|---|---|---|
| Device ID | Kandji-specific device ID of a Mac | String |
| Device Name | Device name	| String |
| Serial Number	| Device serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| User Email | Email address of the user associated with the device | String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. | String |
| Message | Message | String |

---

### Reinstall Kandji Agent
Reinstall the Kandji Agent. An MDM command will be triggered. This request is only applicable to Mac computers.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the Mac computer to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul><br>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Restart Device

Restart a device. An MDM command will be triggered.
**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul><br>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Send MDM Blank Push
Initiate a blank MDM push. An MDM command will be triggered.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul><br>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Set Device Name
Send an MDM command to set the device name.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |
| Device Name | Name to assign to the device | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul><br>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Shutdown Device
Shut down a device. An MDM command will be triggered.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Turn Off Lost Mode
Turn off Managed Lost Mode for an iOS or iPadOS device.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String |
| Device Name | Device name | String |
| Serial Number | Serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| User Email | Email address of the user associated with the device	String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. | String |
| Message | Message to be displayed on the lock screen | String |

---

### Turn On Lost Mode
Turn on Managed Lost Mode for an iOS or iPadOS device. In addition to providing the Device ID, you must enter at least a Lock Message or Phone Number.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |
| Lock Message | Lock message | String | FALSE |
| Phone Number | Phone number | String | FALSE |
| Footnote | Footnote | String | FALSE |

**Output**
| Field | Description | Type |
|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String |
| Device Name | Device name | String |
| Serial Number | Serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| User Email | Email address of the user associated with the device	String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. | String |
| Message | Message to be displayed on the lock screen | String |

---

### Unlock Local User Account
Unlock a locked Mac user account. An MDM command will be triggered.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the Mac computer to send the MDM command to | String | TRUE |
| Username | User name of the local account to unlock | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Update Device
Update information about a device, including the assigned Blueprint, user, and asset tag. You must include the Device ID and one of the three optional inputs.

**Inputs**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to update | String | TRUE |
| Blueprint ID | Blueprint ID to assign the device to | String | FALSE |
| Kandji User ID | Kandji-specific user ID of the user to assign the device to | Number | FALSE |
| Asset tag | Asset tag to assign to the device	String | FALSE |

**Outputs**
| Field | Description | Type |
|---|---|---|
| **Device** |
| Status | Status of the request | Number |
| Device ID | Kandji-specific device ID | String |
| Device Name | Device name | String |
| Model | Device model | String |
| Serial Number | Device serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| OS Version | Version of the OS | String |
| Last Check-in	| Date of last MDM check-in | Date |
| Asset Tag | Asset tag | String |
| Blueprint ID | Blueprint ID the device is assigned to | String |
| MDM Enabled | Whether the device is enabled for MDM | Boolean |
| Agent Installed | Whether the Kandji Agent is installed | Boolean |
| Is Missing | Whether the device is missing from Kandji | Boolean |
| Is Removed | Whether the device was removed from Kandji | Boolean |
| Agent Version | Version of the Kandji Agent | String |
| First Enrollment | When the device was first enrolled with Kandji | Date |
| Last Enrollment | When the device was last enrolled with Kandji | Date |
| Blueprint Name | Name of the Blueprint the device is assigned to | String |
| **User** |
| User Email | Email address of the user associated with the device | String |
| User Name | Name in Kandji of the user assigned to the device | String |
| User ID | Kandji-specific user ID of the user to assign the device to | Number |
| User is Archived | Whether the user is archived | Boolean |

---

### Update Inventory
Start an MDM check-in for a device, initiating the daily MDM commands and MDM logic.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>A 401 Unauthorized error indicates that the HTTP request was not processed because the necessary permissions were missing.</li></ul><br>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |

---

### Update Lost Mode Location
Send the MDM command to an iOS or iPadOS device in Lost Mode to update the location data.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of the device to send the MDM command to | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Device ID | Kandji-specific device ID | String |
| Device Name | Device name | String |
| Serial Number | Device serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, AppleTV) | String |
| User Email | Email address of the user associated with the device | String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. | Number |
| Message | Message | String |
