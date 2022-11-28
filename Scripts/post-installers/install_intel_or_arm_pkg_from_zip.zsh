#!/bin/zsh

# Package name
# This is the name of the package that is contained in the zip file
PKG_NAME="intel_package_name.pkg"            # Intel package name
AS_PKG_NAME="apple_silicon_package_name.pkg" # Apple Silicon package name

# Kandji unzip path
# This should reflect the unzip file path defined in the custom app in Kandji
UNZIP_PATH="/var/tmp"

###################################################################################################
############################ MAIN - DO NOT MODIFY BELOW ###########################################
###################################################################################################

# Determine the processor brand
processor_brand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

if [[ "${processor_brand}" == *"Apple"* ]]; then
    /bin/echo "Apple Processor is present..."

    # make sure that the file exists at the defined path
    if [[ -e "$UNZIP_PATH/$AS_PKG_NAME" ]]; then
        /bin/echo "Installing $AS_PKG_NAME"
        /usr/sbin/installer -pkg "$UNZIP_PATH/$AS_PKG_NAME" -target /
    else
        /bin/echo "Could not find $UNZIP_PATH/$AS_PKG_NAME"
        exit 1
    fi

else
    /bin/echo "Intel Processor is not present..."

    # make sure that the file exists at the defined path
    if [[ -e "$UNZIP_PATH/$PKG_NAME" ]]; then
        /bin/echo "Installing $PKG_NAME"
        /usr/sbin/installer -pkg "$UNZIP_PATH/$PKG_NAME" -target /

    else
        /bin/echo "Could not find $UNZIP_PATH/$PKG_NAME"
        exit 1
    fi

fi

# cleanup
# Add any clean up routines that might be required
# Note: If unzipping files /tmp these files will be cleaned up after the next device restart.
/bin/rm -Rf "$UNZIP_PATH/$PKG_NAME" "$UNZIP_PATH/$AS_PKG_NAME"

exit 0
