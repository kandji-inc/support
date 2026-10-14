# Create Internet Shortcut

### About

This shell script creates custom shortcuts on users' desktops for HTTP, HTTPS, SMB, FTP, and VNC addresses. Administrators can set a display name and specify a custom image. If no image is specified, the script uses a default icon based on the link type.

Set `HOSTNAME` to a full address that starts with the link type:

- Web pages use `https://www.example.com` or `http://www.example.com`.
- File shares use `smb://server.example.com/Share`.
- FTP servers use `ftp://server.example.com`.
- Screen Sharing uses `vnc://server.example.com`.


### Dependencies

This script needs the Iru Agent to control Finder. Follow [Give the Iru Agent access to Finder](../iru-finder-access/README.md).


### Deploy a Custom Icon (Optional)

A custom icon is optional. If you want to use the default icon for the link type, skip to [Script Modification](#script-modification).

The image set in `ICON` must exist on the Mac before the script runs. PNG, ICNS, and other image formats supported by macOS can be used. You can use a Mac Custom App and the ZIP file method to deploy one or more images:

1. Put the image files at the top level of a ZIP file.
2. Create a **Mac Custom App** and select **ZIP File**.
3. Set **Unzip Location** to:
   ```
   /Users/Shared/ShortcutIcons
   ```
4. Upload the ZIP file.
5. Customize [createInternetShortcut.zsh](createInternetShortcut.zsh) using [Script Modification](#script-modification), then paste it into the **Postinstall Script** field. Running it as the postinstall script ensures that the image exists before the shortcut is created.

For full setup instructions, see [Configure the Mac Custom App Library Item](https://docs.iru.com/en/endpoint/library/library-items-profiles/configure-the-custom-apps-library-item).


### Script Modification

Customize the script before you deploy it, whether or not you use a custom icon.

1. Open the script in a text editor such as BBEdit or VS Code.
2. Update the `HOSTNAME` variable with the correct URI and `DISPLAYNAME` with the shortcut name.
3. To use a custom icon, set `ICON` to the full local path of the image. Leave `ICON` blank to use the default icon.
4. Deploy the customized script:
   - With a custom icon, paste it into the **Postinstall Script** field of the Mac Custom App from [Deploy a Custom Icon](#deploy-a-custom-icon-optional).
   - Without a custom icon, add it as a Custom Script. For setup steps, see [Add a Custom Script Library Item](https://docs.iru.com/en/endpoint/library/library-items-profiles/custom-scripts-overview#add-a-custom-script-library-item).

```Shell
        ########################################################################################
        ###################################### VARIABLES #######################################
        ########################################################################################

        # The address that you want the shortcut to open.
        HOSTNAME="https://www.iru.com"

        # The name that will display to users.
        DISPLAYNAME="Iru Website"

        # Full local path to the image to be used for the shortcut. The image must already exist
        # on the Mac. A blank variable will use the default icon for the URI type.
        # Example: ICON="/Users/Shared/ShortcutIcons/Iru.png"
        ICON=""
```
