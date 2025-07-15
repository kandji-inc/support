# Kandji Connector Action Card Details
You can use the Kandji connector to integrate Kandji device management with Okta Workflows to help automate critical components of the user lifecycle that are prone to friction or manual error.

The first step is to [Authorize your Kandji tenant for Okta Workflows](https://support.kandji.io/kb/authorize-your-kandji-tenant-for-okta-workflows).

After you set up a Kandji connection, you can use the following Kandji connector action cards in a Workflow.

The following actions are available, full details are provided further below.
* [Custom API Action](#Custom-API-Action)
* [Assign Library Item](#Assign-Library-Item)
* [Clear Passcode](#Clear-Passcode)
* [Create Blueprint](#Create-Blueprint)
* [Create Note](#Create-Note)
* [Create Tag](#Create-Tag)
* [Erase Device](#Erase-Device)
* [Get Activation Lock Bypass Codes](#Get-Activation-Lock-Bypass-Codes)
* [Get ADE Integration](#Get-ADE-Integration)
* [Get Blueprint](#Get-Blueprint)
* [Get Device](#Get-Device)
* [Get FileVault Recovery Key](#Get-FileVault-Recovery-Key)
* [Get Mac Recovery Lock Password](#Get-Mac-Recovery-Lock-Password)
* [Get Mac Unlock PIN](#Get-Mac-Unlock-PIN)
* [Get Threats Summary](#Get-Threats-Summary)
* [List ADE Devices in ADE Integration](#List-ADE-Devices-in-ADE-Integration)
* [List ADE Integrations](#List-ADE-Integrations)
* [List Blueprints](#List-Blueprints)
* [List Custom Apps](#List-Custom-Apps)
* [List Device Activity](#List-Device-Activity)
* [List Device Apps](#List-Device-Apps)
* [List Device Library Items](List-Device-Library-Items)
* [List Device Notes](#List-Device-Notes)
* [List Devices](#List-Devices)
* [List Library Item Activity](#List-Library-Item-Activity)
* [List Library Item Statuses](#List-Library-Item-Statuses)
* [List Library Items](#List-Library-Items)
* [List Tags](#List-Tags)
* [List Users](#List-Users)
* [Lock Device](#Lock-Device)
* [Manage Apple Remote Desktop](#Manage-Apple-Remote-Desktop)
* [Play Lost Mode Sound](#Play-Lost-Mode-Sound)
* [Reinstall Kandji Agent](#Reinstall-Kandji-Agent)
* [Remove Library Item](#Remove-Library-Item)
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
* [Update Tag](#Update-Tag)
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
| Relative URL | Specify the relative URL to the API following `/v1` <br>e.g. for a licensing request, use `/settings/licensing` | String | TRUE |
| Query | Additional query parameters in object format | Object | FALSE |
| Headers | Additional headers beyond authorization/content-type | Object | FALSE |
| Body | Request body in JSON format | Object | FALSE |

**Outputs**
| Field       | Definition                                                                                | Type   |
|-------------|-------------------------------------------------------------------------------------------|--------|
| Status Code | HTTP status code indicating operation result                                              | Number |
| Headers     | Response headers (e.g. `{"Content-type":"application/json"}`)                             | Object |
| Body        | Data returned from request                                                                | Object |

---

### Assign Library Item
Given a Library Item ID and a Blueprint ID, assign the Library Item to the Blueprint. To assign a Library Item to an Assignment Map, you must also provide the Assignment Node ID.

**Input**
| Field    | Description                                      | Type   | Required |
|---|---|---|---|
| Library Item ID | Unique Library Item identifier  | String | TRUE     |
| Blueprint ID | Unique Blueprint identifier | String | TRUE     |
| Assignment Node ID | Unique Assignment Node identifier | String | FALSE     |

**Output**
| Field       | Description                                                                               | Type   |
|-------------|-------------------------------------------------------------------------------------------|--------|
| Library Item IDs | Operation result with a list of Library Item IDs assigned to the Blueprint.          | String   |

---

### Clear Passcode
Clear the iOS or iPadOS device passcode.

**Input**
| Field    | Description                                      | Type   | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of iOS/iPadOS device | String | TRUE     |

**Output**
| Field       | Description                                                                               | Type   |
|-------------|-------------------------------------------------------------------------------------------|--------|
| Status Code | Operation result with detailed status explanations                                        | String   |

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
| Note      | Text contents of the note                                                   | String | TRUE     |

**Outputs**
| Field       | Description                                                                 | Type   |
|-------------|-----------------------------------------------------------------------------|--------|
| Status Code | Operation result with HTTP status codes and explanations                   | Number |
| Note        | JSON object containing the created note details                             | Object |

---

### Create Tag
Create a Tag. You can create only one tag per request.

**Inputs**
| Field     | Description                                                                 | Type   | Required |
|-----------|-----------------------------------------------------------------------------|--------|----------|
| Name | Unique tag name | String | TRUE     |

**Outputs**
| Field                          | Description                          | Type   |
|--------------------------------|--------------------------------------|--------|
| Tag ID           | Unique identifier for the tag                         | String |
| Tag Name           | Unique name for the tag                         | String |

---

### Erase Device
Send Erase Device MDM command.

**Inputs**
| Field             | Description                                      | Type          | Required          |
|-------------------|--------------------------------------------------|---------------|-------------------|
| Device ID         | Kandji-specific device ID                        | String        | TRUE              |
| PIN               | 6-digit unlock code (macOS only)                | Number        | TRUE (macOS)      |
| PreserveDataPlan  | Maintain cellular plan (iOS/iPadOS only)         | Boolean       | TRUE (iOS/iPadOS) |
| DisallowProximity | Block proximity setup (iOS/iPadOS only)          | Boolean       | TRUE (iOS/iPadOS) |
| ReturnToService > Enabled   | A boolean that determines if ReturnToService will be used | Boolean       | TRUE (iOS/iPadOS) |
| ReturnToService > Profile ID   | Wi-Fi Profile ID for Return to Service  | String       | FALSE |


**Outputs**
| Field       | Description                          | Type   |
|-------------|--------------------------------------|--------|
| Device ID   | Unique identifier for the device     | String |
| Device Name | Unique name for the device           | String |
| Serial Number | Unique serial number for the device | String |
| Platform | The platform of the device                | String |
| User Email | The email associated with the device user | String |
| Status Code | Operation result code and explanation| Number |
| Message | The message for the response                | String |
| PIN         | Generated unlock code                | String |

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
| SToken File Name               | Security token file name             | String |
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

### Get Blueprint
Get a Blueprint by Blueprint ID or by name.

**Input**
| Field          | Description                          | Type   | Required |
|----------------|--------------------------------------|--------|----------|
| Blueprint ID   | Unique Blueprint identifier          | String | FALSE    |
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
| Parameters             | JSON configuration parameters       | List   |
| Computer Count         | Number of assigned devices          | Number |
| Missing Computer Count | Number of missing devices           | Number |
| Enrollment Code        | Manual enrollment code              | String |
| Enrollment Code Active | Code activation status              | Boolean|
| Alerts Count           | Number of active alerts             | String |
| Type                   | Blueprint type                      | String |

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
| Last Check-in       | Last MDM check-in timestamp         | Date    |
| User                | The user object associated with the device | Object  |
| User Email          | The user email                      | String  |
| User Name           | The user name                       | String  |
| Asset Tag           | Device asset tag                    | String  |
| Blueprint ID        | Blueprint ID the device is assigned to | String  |
| MDM Enabled         | Whether the device is enabled for MDM | Boolean |
| Agent Installed     | Whether the agent is installed      | Boolean |
| Is Missing          | Whether the device is missing       | Boolean |
| Is Removed          | Whether the device is removed       | Boolean |
| Agent Version       | Agent version information           | String  |
| First Enrollment    | First enrollment date               | Date  |
| Last Enrollment     | Last enrollment date                | Date  |
| Blueprint Name      | Name of the Blueprint the device is assigned to | String  |
| Lost Mode Status    | Status of Lost Mode                 | String  |
| Tags                | A list of tags assigned to the device | Object  |
| Serial Number       | The unique serial number for the device | String  |


**Outputs (Full)**
| Field               | Description                          | Type    |
|---------------------|--------------------------------------|---------|
| General Info        | Device identification details       | Object  |
| MDM Status          | Management platform information      | Object  |
| Activation Lock     | Security status                      | Object  |
| FileVault           | Encryption status                    | Object  |
| Automated Device Enrollment | Automated Device Enrollment status | Object  |
| Kandji Agent        | Agent information                    | Object  |
| Hardware Overview   | Hardware information                 | Object  |
| Volumes             | Volume information                   | Object  |
| Network             | Network information                  | Object  |
| Recovery Information | Recovery information                | Object  |
| Users               | Users information                    | Object  |
| Installed Profiles  | Installed Profiles information       | Object  |
| Apple Business Manager | Apple Business Manager information | Object  |
| Security Information | Security Information                | Object  |
| Cellular            | Cellular Information                 | Object  |
| Lost Mode           | Lost Mode status                     | Object  |
| Tags                | A list of tags assigned to the device | List  |
| User                | User information                     | Object  |

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

### Get Mac Recovery Lock Password
This request returns the Recovery Lock password for a Mac with Apple Silicon, or the legacy EFI firmware password for an Intel-based Mac.
<br><br>
For more details on setting and managing Recovery passwords, see the [Configure the Recovery Password Library Item](https://support.kandji.io/support/solutions/articles/72000560472-configure-the-recovery-password-library-item) support article.


**Inputs**
| Field             | Description                                      | Type          | Required          |
|-------------------|--------------------------------------------------|---------------|-------------------|
| Device ID         | Kandji-specific device ID                        | String        | TRUE              |

**Outputs**
| Field       | Description                          | Type   |
|-------------|--------------------------------------|--------|
| Recovery Password   | Recovery Lock password for a Mac with Apple Silicon, or the legacy EFI firmware password for an Intel-based Mac     | String |

---

### Get Mac Unlock PIN
Get the PIN for a locked Mac.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID of a Mac | String | TRUE |

**Output**
| Field | Description | Type | 
|---|---|---|
| PIN | Unlock PIN | String |

---

### Get Threats Summary
Return top-level information about the number of threats detected. Return status_code of 404 if EDR is not turned on for the tenant. Return status_code of 401 if the API key does not have permission to read threats.

**Outputs**
| Field               | Description                          | Type    |
|---------------------|--------------------------------------|---------|
| Total Count         | Total count of threats               | Number  |
| Malware Count       | TCount of malware threats            | Number  |
| PUP Count           | Count of Potentially Unwanted Programs | Number  |

---

### List ADE Devices in ADE Integration
Return a list of all devices associated with an Automated Device Enrollment token, as well as their enrollment status. When the mdm_device key value is null, this indicates that the device is awaiting enrollment into Kandji.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | 	Whether to return results directly or to stream results. Options include:<ul><li>First Record.</li><li>First 300 Records.</li><li>Stream All Records. If you choose streaming, you must select a Helper Flow to run for every ADE Device.</li></ul> | Dropdown | TRUE |

**Inputs**
| Field | Description | Type | Required |
|---|---|---|---|
| ADE Token ID | ID of ADE Token | String | TRUE |
| Device Family | Family of the device | String | FALSE |
| Kandji User ID | An exact match to the unique identifier for the user | String | FALSE |
| Model | A string containing the device model | String | FALSE |
| Operating System | Family of the device | Dropdown | FALSE |
| Profile Status | Status of the profile | String | FALSE |
| Serial Number - Contains String | A unique serial number for a device | String | FALSE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Blueprint ID | ID of the Blueprint. <br>Appears when **First Record** is defined. | String |
| Kandji User ID | Kandji user id. <br>Appears when **First Record** is defined. | String |
| ADE Token ID | ADE Integration id. <br>Appears when **First Record** is defined. | String |
| Server Name | The name of the server. <br>Appears when **First Record** is defined. | String |
| Asset Tag | The asset tag. <br>Appears when **First Record** is defined. | String |
| Description | The description of the Blueprint assigned to the ADE integration. <br>Appears when **First Record** is defined. | String |
| Color | Color for the Blueprint assigned to the ADE integration. <br>Appears when **First Record** is defined. | String |
| Device Assigned By | The user the device was assigned by. <br>Appears when **First Record** is defined. | String |
| Device Assigned Date | The date the device was assigned. <br>Appears when **First Record** is defined. | Date |
| Device Family | The family of the device. <br>Appears when **First Record** is defined. | String |
| Model | The model of the device. <br>Appears when **First Record** is defined. | String |
| OS | The OS of the device. <br>Appears when **First Record** is defined. | String |
| Profile Assign Time | The date and time the profile was assigned. <br>Appears when **First Record** is defined. | Date |
| Profile Push Status | The push status of the profile. <br>Appears when **First Record** is defined. | String |
| Profile Status | The status of the profile. <br>Appears when **First Record** is defined. | String |
| ADE Device ID | The ADE Device ID. <br>Appears when **First Record** is defined. | String |
| Last Assignment Time | The date and time it was last assigned. <br>Appears when **First Record** is defined. | Date |
| Failed Assignment | Whether the assignment failed or not. <br>Appears when **First Record** is defined. | Boolean |
| Assignment Status Received At | The date and time the assignment status was received. <br>Appears when **First Record** is defined. | Date |
| Enrolled Device ID | The enrolled Device ID. <br>Appears when **First Record** is defined. | String |
| Enrolled At | The date and time the device was enrolled. <br>Appears when **First Record** is defined. | Date |
| Enrolled Device Name | The name of the enrolled device. <br>Appears when **First Record** is defined. | String |
| Enrolled Device Enrollment Status | The enrollment status of the enrolled device. <br>Appears when **First Record** is defined. | String |
| Deferred Install | Whether or not the install is deferred. <br>Appears when **First Record** is defined. | Boolean |
| Is Missing | Whether or not the device missing. <br>Appears when **First Record** is defined. | Boolean |
| Is Removed | Whether or not the device is removed. <br>Appears when **First Record** is defined. | Boolean |
| Results | JSON list of objects, one object per ADE Device.<br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of ADE Devices<br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List ADE Integrations
Return a list of configured Automated Device Enrollment (ADE) integrations.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include: <ul><li>First Record.</li><li>First 300 Records.</li><li>Stream All Records. If you choose streaming, you must select a Helper Flow to run for every ADE Integration.</li></ul> | Dropdown | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| ID | ADE Integration id. <br>Appears when **First Record** is defined. | String |
| Blueprint ID | ID of the Blueprint. <br>Appears when **First Record** is defined. | String |
| Blueprint Name | ID of the Blueprint assigned to the ADE integration. <br>Appears when **First Record** is defined. | String |
| Blueprint Icon | Icon for the Blueprint assigned to the ADE integration. <br>Appears when **First Record** is defined. | String |
| Blueprint Color | Color for the Blueprint assigned to the ADE integration. <br>Appears when **First Record** is defined. | String |
| Access Token Expiry | Token expiration date. <br>Appears when **First Record** is defined. | String |
| Server Name | The name of the server. <br>Appears when **First Record** is defined. | String |
| Server UUID | The UUID of the server. <br>Appears when **First Record** is defined. | String |
| Admin ID | The ID of the admin. <br>Appears when **First Record** is defined. | String |
| Organization Name | The name of the organization. <br>Appears when **First Record** is defined. | String |
| Organization Email Address | The email address of the organization. <br>Appears when **First Record** is defined. | String |
| Organization Phone | The phone number of the organization. <br>Appears when **First Record** is defined. | String |
| Organization Address | The address of the organization. <br>Appears when **First Record** is defined. | String |
| Organization Type | The type of organization. <br>Appears when **First Record** is defined. | String |
| SToken File Name | The file name of the SToken. <br>Appears when **First Record** is defined. | String |
| Last Device Sync | The last device sync date and time. <br>Appears when **First Record** is defined. | Date |
| Default Email Address | The default email address. <br>Appears when **First Record** is defined. | String |
| Default Phone | The default phone number. <br>Appears when **First Record** is defined. | String |
| Days Left | The number of days left. <br>Appears when **First Record** is defined. | Number |
| Status | The current status. <br>Appears when **First Record** is defined. | String |
| Status Reason | The reason for the current status. <br>Appears when **First Record** is defined. | String |
| Status Received At | The date and time that the status was received. <br>Appears when **First Record** is defined. | Date |
| iPhone Count | The number of iPhone devices. <br>Appears when **First Record** is defined. | Number |
| Mac Count | The number of Mac devices. <br>Appears when **First Record** is defined. | Number |
| iPad Count | The number of iPad devices. <br>Appears when **First Record** is defined. | Number |
| Apple TV Count | The number of Apple TV devices. <br>Appears when **First Record** is defined. | Number |
| Appleseed Beta Enrollment | Appleseed Beta Enrollment object. <br>Appears when **First Record** is defined. | Object |
| Results | JSON list of objects, one object per ADE Integration. <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of ADE Integrations. <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Blueprints
List Blueprints.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | 	Whether to return results directly or to stream results. Options include:<ul><li>First 300 Records.</li><li>Stream All Records. If you choose streaming, you must select a Helper Flow to run for every Blueprint.</li></ul> | Dropdown | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON list of objects, one object per Blueprint<br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of Blueprints<br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Custom Apps
Return a list of all Custom Apps.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include: <ul><li>First 300 Records.</li><li>Stream All Records.</li></ul> | Dropdown | TRUE |

**Output**
| Field | Definition | Type |
|---|---|---|
| Results | JSON list of Custom Apps, one object per Custom App. <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of Custom Apps. <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Device Activity
Given a Device ID, list Activity for the device (uses the Kandji Get Device Activity API call).

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include: <ul><li>First 300 Records.</li><li>Stream All Records.</li></ul> | Dropdown | TRUE |

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID | String | TRUE |

**Output**
| Field | Definition | Type |
|---|---|---|
| Results | JSON list of Device Activity records, one object per Device Activity. <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of Device Activity records. <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Device Apps
Given a Device ID, return a list of all installed apps for the device. For iOS, iPadOS, tvOS, and visionOS this lists third-party apps installed on this device. Built-in iOS, iPadOS, tvOS, and visionOS apps are not inventoried.

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
Given a Device ID, return a list of all the Notes for the device.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Device ID | Kandji-specific device ID | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Notes List | List of JSON objects, one object per Note | List |

---

### List Devices
Returns a list of enrolled devices. Optional query parameters can filter results:

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First Matching Record</li><li>First 300 Matching Records</li><li>Stream Matching Records. If you choose streaming, you must choose a Helper flow to run for every device.</li></ul> | Dropdown | TRUE |

**Inputs**
| Field | Description | Type | Required |
|---|---|---|---|
| Asset Tag | Asset tag | String | FALSE
| Blueprint ID | ID of the Blueprint the device is assigned to | String | FALSE |
| Device ID | Kandji-specific device ID | String | FALSE
| Device Name | Device name | String | FALSE
| FileVault Turned On | Whether FileVault is turned on | Boolean | FALSE |
| Kandji User ID | Kandji-specific user ID of the user assigned to the device | Number | FALSE |
| MAC Address | MAC Address of the primary network interface of the device | String | FALSE |
| Model | Device model | String | FALSE |
| OS Version | Version of the OS | String | FALSE |
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TVm and Apple Vision Pro) | String | FALSE |
| Serial Number | Device serial number | String | FALSE |
| Tag ID | Tag ID for the device; this returns devices that have a Tag with the exact Tag ID provided | String | FALSE
| Tag ID In | Tag ID for the device; this returns all devices with a Tag with a Tag ID that contains the string | String | FALSE
| Tag Name | Tag Name for the device; this returns devices that have a Tag with the exact Tag Name provided | String | FALSE
| Tag Name In | Tag ID for the device; this returns all devices with a Tag with a Tag Name that contains the string | String | FALSE
| User Email - Contains | String contains email address of the user associated with the device | String | FALSE |
| User Email - Exact Match | Exact email address of the user associated with the device | String | FALSE |
| User Name | Name of the user assigned to the device | String | FALSE |

**Outputs for "First Matching Record"**
| Field	| Definition | Type |
|---|---|---|
| The following appear when First Matching Record is selected from the Result Set field.|
| Agent Installed | Whether the Kandji Agent is installed | Boolean |
| Agent Version | Version of the Kandji Agent | String |
| Asset Tag | Asset tag | String |
| Blueprint ID | Blueprint ID the device is assigned to | String |
| Blueprint Name | Name of the Blueprint the device is assigned to | String |
| Device ID | Kandji-specific device ID | String |
| Device Name | Device name | String |
| First Enrollment | When the device was first enrolled with Kandji | Date |
| Is Missing | Whether the device is missing from Kandji | Boolean |
| Is Removed | Whether the device was removed from Kandji | Boolean |
| Last Check-in | Date of last MDM check-in | Date |
| Last Enrollment | When the device was last enrolled with Kandji | Date |
| Model | Device model | String |
| OS Version | Version of the OS | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
| Serial Number | Device serial number | String |
| Tags | List of tags | List |
| User | JSON object for assigned Kandji user | Object |

**Output for "First 300 Matching Records"**
| Field | Definition | Type |
|---|---|---|
| Devices | JSON list of objects, one object per device | List |

**Output for "Stream Matching Records"**
| Field | Definition | Type |
|---|---|---|
| Record Count | Number of records | Number |

---

### List Library Item Activity
Given a Library Item ID, get a list of Activity for the Library Item (uses the Kandji Get Library Item Activity API call).

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First 300 Records</li><li>Stream All Records.</li></ul> | Dropdown | TRUE |

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Library Item ID | Unique Library Item identifier | String | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON object Library Item Activity <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of records <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Library Item Statuses
Given a Library Item ID, get a list of Activity for the Library Item (uses the Kandji Get Library Item Activity API call).

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First 300 Records</li><li>Stream All Records.</li></ul> | Dropdown | TRUE |

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Library Item ID | Unique Library Item identifier | String | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON object Library Item Statuses <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of records <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Library Items
Given a Blueprint ID, return a list of the Library Items for the Blueprint.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First 300 Records</li><li>Stream All Records.</li></ul> | Dropdown | TRUE |

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Blueprint ID | Unique Blueprint identifier | String | TRUE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON object Library Items <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of records <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Tags
List all tags.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First 300 Records</li><li>Stream All Records.</li></ul> | Dropdown | TRUE |

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Name | Tag name | String | FALSE |

**Outputs**
| Field | Definition | Type |
|---|---|---|
| Results | JSON object with first 300 records <br>Appears when **First 300 Records** is selected from the **Result Set** option. | List |
| Record Count | Number of records <br>Appears when **Stream All Records** is selected from the **Result Set** option. | Number |

---

### List Users
Return a list of all users from directory integrations. Optional query parameters can be specified to filter the results.

**Options**
| Field | Definition | Type | Required |
|---|---|---|---|
| Result Set | Whether to return results directly or to stream results. Options include:<ul><li>First Matching Record</li><li>First 300 Records</li><li>Stream All Matching Records.</li></ul> | Dropdown | TRUE |

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Archived | Return only users that are either archived (true) or not archived (false). Archived users are users that appear in the Kandji Users module under the Archived tab. | Boolean | FALSE |
| Integration ID | Search for an integration matching the provided UUID value. | String | FALSE |
| Kandji User ID | Returns a user matching the provided UUID value. | String | FALSE |
| User Email | Returns users with email addresses containing the provided string. | FALSE |

**Outputs for "First Matching Record"**
| Field	| Definition | Type |
|---|---|---|
| The following appear when First Matching Record is selected from the Result Set field.|
| Active	| Whether or not a user is active | Boolean |
| Archived	| Whether or not a user is archived | Boolean |
| Created At | Date and time a user was created at | Date |
| Department | Department for the user | String |
| Email Address | Email address for the user | String |
| Kandji User ID | Unique identifier for the user | String |
| Integration | Integration object | Object |
| Job Title | Job title for the user | String |
| Name | Name of the user | String |
| Device Count | Number of devices assigned to a user | Number |
| Updated At | Update date and time | Date |

**Output for "First 300 Matching Records"**
| Field | Definition | Type |
|---|---|---|
| Users | JSON list of objects, one object per user | List |

**Output for "Stream All Matching Records"**
| Field | Definition | Type |
|---|---|---|
| Record Count | Number of records | Number |

---

### Lock Device
Send an MDM command to lock a device. For a Mac computer, a 6-digit Lock PIN will be returned.

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
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
| User Email | Email address of the user associated with the device | String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. For example:<ul><li>200 OK</li><li>400 Bad Request: "Command already running" - The command may already be running in a Pending state waiting on the device.</li><li>401 Unauthorized: Invalid access token. This can happen if the token was revoked, the required permissions are missing, or the token has expired.</li><li>404 Not found: Unable to locate the resource in the Kandji tenant.</li</ul>For a full list of possible status codes, see [HTTP status codes](https://help.okta.com/wf/en-us/Content/Topics/Workflows/execute/http-status-codes.htm). | Number |
| Message | Message | String |
| Lock PIN | Lock PIN for Mac computer | String |

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
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
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

### Remove Library Item
Given a Library Item ID and a Blueprint ID, unassign the Library Item from the Blueprint. To remove a Library Item from an Assignment Map, you must also provide the Assignment Node ID.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Assignment Node ID | Assignment Node for a Blueprint | String | FALSE |
| Blueprint ID | Blueprint ID of the Blueprint that contains the Library Item | String | FALSE |
| Library Item ID | Library Item ID for the Library Item to remove | String | FALSE |

**Output**
| Field | Description | Type |
|---|---|---|
| Remaining Library Items | JSON object with a list of remaining Library Items in the Blueprint | String |
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
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
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
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
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
Given a Device ID, update any of the following for that device: assigned Blueprint ID, User ID, Asset Tag, or Tags. You must update or clear at least one of these. 
Use Options to specify that leaving a field blank will clear the value for that attribute (the default value for each Option is False).<br><br>
Following RESTful conventions, if you specify a device's Tags, you must include the entire set of desired Tags in the request.

**Options**
| Field    | Definition                          | Type     | Required |
|----------|--------------------------------------|----------|----------|
| Asset Tag  | Leave Asset Tag blank to clear it   | Boolean | FALSE     |
| User ID  | Leave User ID blank to unassign   | Boolean | FALSE     |
| Tags  | Leave Tags blank to clear Tags   | Boolean | FALSE     |

**Inputs**
| Field | Description | Type | Required |
|---|---|---|---|
| Asset Tag | Asset tag to assign to the device |	String | FALSE |
| Blueprint ID | Blueprint ID to assign the device to | String | FALSE |
| Device ID | Kandji-specific device ID of the device to update | String | TRUE |
| Kandji User ID | Kandji-specific user ID of the user to assign the device to | Number | FALSE |
| Tags | Tag to assign to the device | String | FALSE |

**Outputs**
| Field | Description | Type |
|---|---|---|
| **Device** |
| Status | Status of the request | Number |
| Device ID | Kandji-specific device ID | String |
| Device Name | Device name | String |
| Model | Device model | String |
| Serial Number | Device serial number | String |
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
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
| Supplemental Build Version | The operating system’s build and Rapid Security Response versions in use on the device, for example (20A123a or 20F75c) | String |
| Supplemental OS Version Extra | The operating system’s Rapid Security Response version in use on the device (for example, a) | String |
| Tags | JSON object with a list of Tags | List |
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
| Platform | Apple platform (such as Mac, iPhone, iPad, Apple TV) | String |
| User Email | Email address of the user associated with the device | String |
| Status Code | Result of the operation. The HTTP status code is returned by the connector and indicates whether the action taken by the card succeeded or failed. | Number |
| Message | Message | String |

---

### Update Tag
Given a Tag ID, update the name of the tag.

**Input**
| Field | Description | Type | Required |
|---|---|---|---|
| Tag ID | Unique identifier for the tag | String | TRUE |

**Output**
| Field | Description | Type |
|---|---|---|
| Tag Name | Unique name for the tag | String |