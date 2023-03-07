#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald (DTNB) | support@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 06/08/2020
# Updated on 03/06/2023
################################################################################################
# Software Information
################################################################################################
# Converts a plist to a mobileconfig profile by extracting the main dictionary
################################################################################################
# License Information
################################################################################################
# Copyright 2023 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
################################################################################################


currentUser=$(ls -la /dev/console | cut -d' ' -f4)

plistPath="$1"

if [ "${plistPath}" = "" ]; then 
	echo "No File Loaded"
	exit 1
fi

PayloadUUID=$(/usr/bin/uuidgen)
PayloadID=$(/usr/bin/uuidgen)
ProfileUUID=$(/usr/bin/uuidgen)
ProfileID=$(/usr/bin/uuidgen)

collectPlistDictionary=$(/usr/libexec/PlistBuddy ${plistPath} -x -c print | /usr/bin/xpath -e '/plist[@version="1.0"]/dict/child::node()' 2>/dev/null | /usr/bin/awk NF)
fullPlistName=$(/usr/bin/basename -- "${plistPath}")
prefDomain="${fullPlistName%.*}"

mobileConfigOut="/Users/${currentUser}/Downloads/${prefDomain}.mobileconfig"

/bin/cat > ${mobileConfigOut} <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
	<dict>
	${collectPlistDictionary}
	<key>PayloadDescription</key>
	<string>${prefDomain}</string>
	<key>PayloadDisplayName</key>
	<string>${prefDomain}</string>
	<key>PayloadIdentifier</key>
	<string>io.se.kandji.${PayloadID}</string>
	<key>PayloadOrganization</key>
	<string>Kandji, Inc.</string>
	<key>PayloadType</key>
	<string>${prefDomain}</string>
	<key>PayloadUUID</key>
	<string>${PayloadUUID}</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
	</dict>
	</array>
	<key>PayloadDescription</key>
	<string>${prefDomain}</string>
	<key>PayloadDisplayName</key>
	<string>${prefDomain}</string>
	<key>PayloadIdentifier</key>
	<string>io.kandji.customprofile.${ProfileID}</string>
	<key>PayloadOrganization</key>
	<string>Kandji, Inc.</string>
	<key>PayloadScope</key>
	<string>System</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>${ProfileUUID}</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
EOF


/usr/bin/plutil -convert xml1 ${mobileConfigOut}

validateMobileConfig=$(/usr/bin/plutil -lint ${mobileConfigOut} | /usr/bin/awk '{print $NF}')


if [ "$validateMobileConfig" = "OK" ]; then
	echo "Plist to MobileConfig coversion Succeeded the MobileConfig file has been placed in your downloads folder."
	exit 0 
else 
	echo "Plist to MobileConfig coversion Failed"
	echo "DETAILS:"
	echo "-----------"
	echo "$validateMobileConfig"
	exit 1
fi

exit 0