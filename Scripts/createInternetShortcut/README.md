# Create Internet Shortcut

### About

This Shell script creates custom shortcuts on user's desktops for http(s), smb, ftp, and vnc addresses. Administrators can set a display name and specify an icon if disired.  If no icon is specified, the script will use a default icon depending on the link type. 


### Dependencies

- Privacy Profile (PPPC) granting the Kandji Agent access to Finder Apple Events.
  - **Identifer Type:** Bundle ID
  - **Identifier:** io.kandji.KandjiAgent
  - **Code Requirement:** 
    ```
    anchor apple generic and identifier "io.kandji.KandjiAgent" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = P3FGV63VK7)
    ```
  - **App or Service:** AppleEvents
    - **Access:** Allow
    - **Receiver Identifier Type:** Bundle ID
    - **Receiver Identifier:** com.apple.finder
    - **Receiver Code Requirement:** identifier "com.apple.finder" and anchor apple


### Script Modification

1. Open the script in a text editor such as BBEdit or VSCode.
2. Update the `HOSTNAME` variable with the correct URI, `DISPLAYNAME` with the display name of the shortcut, and `ICON` with the full path of your desired icon if you do not want to use the default icons.

```Shell
        ########################################################################################
        ###################################### VARIABLES #######################################
        ########################################################################################

        # The address that you want the shortcut to open.
        HOSTNAME="https://kandji.io"

        # The name that will display to users.
        DISPLAYNAME="My Favorite MDM"

        # Full path to the icon to be used for the shortcut.  A blank variable will use a 
        # default icon, depending on the link type.
        # example: ICON="/Library/Kandji/Kandji Agent.app/Contents/Resources/AppIcon.icns"
        ICON=
```
3. Save and close the script.
4. In Kandji, create a new Custom Script.
5. Paste your modified createInternetShortcut.zsh script in the body of the script.


### Examples

- Custom Icon:
<br><img src="/Scripts/createInternetShortcut/images/CustomIcon-code.png" width="600" align="middle"></img><img src="/Scripts/createInternetShortcut/images/CustomIcon-icon.png" width="150" align="middle"></img>

- HTTP and HTTPS Default Icon:
<br><img src="/Scripts/createInternetShortcut/images/DefaultHTTPS-code.png" width="600" align="middle"></img><img src="/Scripts/createInternetShortcut/images/DefaultHTTPS-icon.png" width="150" align="middle"></img>

- SMB and FTP Default Icon:
<br><img src="/Scripts/createInternetShortcut/images/DefaultSMB-code.png" width="600" align="middle"></img><img src="/Scripts/createInternetShortcut/images/DefaultSMB-icon.png" width="150" align="middle"></img>

- VNC Default Icon:
<br><img src="/Scripts/createInternetShortcut/images/DefaultVNC-code.png" width="600" align="middle"></img><img src="/Scripts/createInternetShortcut/images/DefaultVNC-icon.png" width="150" align="middle"></img>



