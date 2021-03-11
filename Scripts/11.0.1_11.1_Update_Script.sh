#!/bin/bash

################################################################################################
# Created by Nicholas McDonald | Principal Solutions Engineer
#
# Download Mechanism by Jim Quilty | Senior Solutions Engineer
#
# Kandji, Inc | Solutions | se@kandji.io
################################################################################################
# Created on 02/02/2021 Modified on 03/10/2021
#
# Script Version - 1.2.1
#
# Change Log
# Version 1.0 - Original
# Version 1.1 - Added support to upgrade 11-11.2 Mac computers to 11.2.1
# Version 1.2 - added support to upgrade 11-11.2.2 Mac computers to 11.2.3
# Version 1.2.1 - added SYSTEM_VERSION_COMPAT=0 to prevent retrieving "10.16"
# as the OS version in early macOS 11 versions
################################################################################################
# Software Information
################################################################################################
# This script is designed to upgrade macOS 11.0-11.2.2 clients to macOS 11.2.3 using the
# full macOS installer. This is required as the software update mecahnisms are broken in these
# macOS versions.
#
# This script is designed to be run every 15 minutes from Kandji (or any other MDM solutions)
# the script is MDM agnostic.
################################################################################################
# License Information
################################################################################################
# Copyright 2021 Kandji, Inc.
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

# EXIT CODES
# exit 1 = download failed
# exit 2 = AS, current user not a ST user
# exit 3 = AS. too many password attempts
# exit 4 = not enough disk space 
# exit 5 = download verification failed multiple times
# exit 6 = update failed, unknown
# exit 7 = unknown power error



#Specify your Org/Dept name, this will be shown to users. 
orgAndDeptName="Kandji IS&T"

#Specify how long each deferral should be (Before the user is re-prompted) 
deferralWindow="24"

#Specify if the script should only launch the Install macOS Big Sur.App for the user, as opposed to initiating a startosinstall
LaunchInstallerOnly="0"

################# Dont modify the contents below this line #################
currentUser=$(/bin/ls -la /dev/console | /usr/bin/cut -d' ' -f4)
osagiveup="180"
osatimeout="180"

passwordTry="0"

instVers="11.2.3"
minOsVers="11.0"

#Determine the processor brand
processorBrand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)

#collects the current macOS Version
currentmacOSVersion=$(SYSTEM_VERSION_COMPAT=0 /usr/bin/sw_vers -productVersion)

if (( $(/bin/echo "${currentmacOSVersion} ${minOsVers}" | /usr/bin/awk '{print ($1 < $2)}') )); then
	/bin/echo "This script is not designed to update 10.15 or below Mac computers"
	exit 0
fi

if (( $(/bin/echo "${currentmacOSVersion} ${instVers}" | /usr/bin/awk '{print ($1 >= $2)}') )); then
	/bin/echo "macOS Version is ${currentmacOSVersion} and does not meet the qualifications for this script."
	exit 0
else
	/bin/echo "Current macOS Version is: ${currentmacOSVersion}... Mac is eligible for update..."
fi

if [ ! -e /usr/local/bin/kandji ]; then
	iconFile="System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:ToolbarInfo.icns"
else 
	iconFile="Applications:Kandji Self Service.app:Contents:Resources:AppIcon.icns"
fi

availableSpace=$(/bin/df -g / | /usr/bin/awk 'FNR==2{print $4}')

totalSpace=$(/usr/sbin/diskutil info / | grep "Total Size:" | awk '{print $3}')

if [ "${availableSpace}" -lt "38" ]; then
	echo "Not enough free space"
	exit 4
fi

currentTime=$(date +%s)

deferralTimeInSeconds=$((${deferralWindow} * 3600))

if [ -e /var/tmp/.dft.kandji ]; then
	lastDeferralTime=$(/bin/cat /var/tmp/.dft.kandji)
	
	timeDiff=$((currentTime - lastDeferralTime))
	
	/bin/echo "Current Time: $currentTime, Last Deferral Time: $lastDeferralTime, Time Diff: $timeDiff"
	
	if [ "${timeDiff}" -gt "${deferralTimeInSeconds}" ]; then
		/bin/echo "${deferralWindow} hours since deferral"
	else
		/bin/echo "Deferred too recently"
		exit 0
	fi

fi

fPowerCheck ()
{
	powerSource=$(/usr/bin/pmset -g ps | /usr/bin/awk -F"'" '{print $2}' )
	
	/bin/echo "Connected Power source is currently: $powerSource"
	
	if [ "${powerSource}" = "Battery Power" ]; then
		/bin/echo "Computer is NOT connected to AC power..."
		
	elif [ "${powerSource}" = "AC Power" ]; then
		/bin/echo "Computer IS connected to AC power..."
		fInstall
	else
		/bin/echo "Unknown error"
		fErrorOut
		exit 7
	fi
	
	title="macOS ${instVers} Update - Connect to power"
	message="Your Mac is not yet connected to power.\n\nPlease connect to power and click Try Again."
	powerInput=$(/usr/bin/osascript<<END
	with timeout of ${osatimeout} seconds
set the answer to button returned of (display dialog "${message}" with icon file "${iconFile}" with title "${title}" buttons {"Defer ${deferralWindow} hour(s)", "Try Again"} default button 2 giving up after ${osagiveup})
	end timeout
END
)
	
	if [ "${powerInput}" = "Defer ${deferralWindow} hour(s)" ]; then
		/bin/echo "User chose to defer"
		fDefer
	elif [ "${powerInput}" = "Try Again" ]; then
		fPowerCheck
	else
		/bin/echo "Window timed out... will try again later..."
		exit 0
	fi
}

fDefer ()
{
	/usr/bin/killall caffeinate
	
	if [ -e /var/tmp/.dfc.kandji ]; then
		currentDefferalCount=$(/bin/cat /var/tmp/.dfc.kandji)
	else
		currentDefferalCount="0"
	fi
	
	deferalCount=$((currentDefferalCount+1))
	
	/bin/echo "${deferalCount}" > /var/tmp/.dfc.kandji
	/bin/echo "${currentTime}" > /var/tmp/.dft.kandji
	
	/bin/echo "User has chosen to defer, this is their ${deferalCount} defferal..."
	
	exit 0
}

fInitManualSusDownload ()
{
	
	# Download URL
	dlURL="http://swcdn.apple.com/content/downloads/12/32/071-14766-A_Q2H6ELXGVG/zx8saim8tei7fezrmvu4vuab80m0e8a5ll/InstallAssistant.pkg"
	
	# SHA256 checksum of the file for verification Example: shasum -a 256 PATH/TO/FILE
	fileChecksum="0fd7cf05746316145012fadcf266413bbb862b3dfb8b5e58d9b0ca1e98f57f01"
	
	################################################################################################
	
	## Other Variables ##
	finalURL=$(/usr/bin/curl "$dlURL" -s -L -I -o /dev/null -w '%{url_effective}')
	fileName="${finalURL##*/}"
	fileExt=$(/bin/echo "${fileName##*.}" | /usr/bin/awk '{print tolower($0)}')
	tmpDir="/private/tmp/download"
	pathToFile="$tmpDir/$fileName"
	dlTries=1
	vfTries=0
	percent=0
	
	## Create Functions ##
	successTest() {
		# Test if last run command was successful
		if [ $? -ne 0 ]; then
			/bin/echo "$1"
			/usr/bin/killall caffeinate
			exit 1
		fi
	}
	
	downloadFile() {
		/usr/bin/curl -Ls "$finalURL" -o "$pathToFile"
		while [[ "$?" -ne 0 ]]; do
			/bin/echo "Download Failed, retrying.  This is attempt $dlTries"
			/bin/sleep 5
			(( dlTries++ ))
			if [ "$dlTries" == 11 ]; then
				/bin/echo "Download has failed 10 times, exiting"
				/usr/bin/killall caffeinate
				exit 1
			fi
			/usr/bin/curl -Ls "$finalURL" -o "$pathToFile"
		done
	}
	
	getDownloadSize() {
		/usr/bin/curl -sI "$finalURL" | /usr/bin/grep -i "^Content-Length" | /usr/bin/awk '{print $2}' | /usr/bin/tr -d '\r'
	}
	
	dlPercent() {
		fSize=$(/bin/ls -nl "$pathToFile" | /usr/bin/awk '{print $5}')
		percent=$(/bin/echo "scale=2;($fSize/$dlSize)*100" | bc)
		percent=${percent%.*}
	}
	
	installPKG() {
		/bin/echo "PKG to install: $pathToFile"
		/usr/sbin/installer -pkg "$pathToFile" -target /
		successTest "Something went wrong during install..."
		/bin/echo "Install completed successfully..."
	}
	
	## Execute ##
	
	# Create temp directory for download
	if [ -d "$tmpDir" ]; then
		/bin/rm -rf "$tmpDir"
		/bin/mkdir "$tmpDir"
	else
		/bin/mkdir "$tmpDir"
	fi
	
	# Keep machine awake, as if user is active. 
	/usr/bin/caffeinate -disu &
	
	# Download & Validate File
	dlSize=$(getDownloadSize)
	dlSUM=""
	while [ "$fileChecksum" != "$dlSUM" ]; do
		/bin/echo "Attempting to download and verify $fileName..."
		(( vfTries++ ))
		if [ $vfTries == 4 ]; then
			/bin/echo "Download and Verification has failed 3 times, exiting..."
			/usr/bin/killall caffeinate
			exit 5
		fi
		downloadFile &
		pid=$!
		# If this script is killed, kill the download.
		trap "kill $pid 2> /dev/null" EXIT
		# Track download progress
		while kill -0 $pid 2> /dev/null; do
			if [ -f "$pathToFile" ]; then
				dlPercent
				/bin/echo "Download at $percent%"
				/bin/sleep 10
			fi
		done 
		# Disable the trap on a normal exit.
		trap - EXIT
		/bin/echo "Download complete. Verifying file..."
		dlSUM=$(/usr/bin/shasum -a 256 "$pathToFile" | /usr/bin/cut -d ' ' -f1)
	done
	
	# Perform Installation
	installPKG
	
	# Cleanup
	/bin/echo "Cleaning up files and processes..."
	/usr/bin/killall caffeinate
	/bin/sleep 10
	/bin/rm -R "$tmpDir"
}

fWelcomeB ()
{
	if [ "${currentUser}" == "root" ] || [ "${currentUser}" == "_mbsetupuser" ] || [ "${currentUser}" == "wtmp" ]; then
		/bin/echo "No user is logged in... exiting..."
		exit 0
	fi
	
	if [[ "${LaunchInstallerOnly}" = "1" ]]; then 
		if ps aux | grep "Install macOS Big Sur" | grep -v "grep"; then
			/bin/echo "Installer already open"
			exit 0
		fi
	fi
	
	title="macOS ${instVers} Update"
	message="Your Mac is pending the install of a critical macOS update. This update has been approved by ${orgAndDeptName}.\n\nThis update will take approximately 60 minutes to install.\n\nYou may defer this update for ${deferralWindow} hour(s) or update now.\n\nPlease ensure your Mac is connected to a power source."
	welcomeInput=$(/usr/bin/osascript<<END
	with timeout of ${osatimeout} seconds
set the answer to button returned of (display dialog "${message}" with icon file "${iconFile}" with title "${title}" buttons {"Defer ${deferralWindow} hour(s)", "Update Now"} default button 2 giving up after ${osagiveup})
	end timeout
END
)

	if [ "${welcomeInput}" = "Defer ${deferralWindow} hour(s)" ]; then
		/bin/echo "User chose to defer"
		fDefer
	elif [ "${welcomeInput}" = "Update Now" ]; then
		fPowerCheck
	else
		/bin/echo "Window timed out... will try again later..."
		exit 0
	fi
}

fDownloadInstaller ()
{
	#Downloads the macOS Installer
	try="0"

	until [ "${try}" -ge 5 ]
	do
		if [ ! -e "/Applications/Install macOS Big Sur.app" ]; then

			/bin/echo "Trying to download installer.... number of trys ${try}"
			
			fInitManualSusDownload
			
			try=$((try+1))
			/bin/sleep 2
		else
			/bin/echo "The Big Sur installer is present"
			installerVersion=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "/Applications/Install macOS Big Sur.app/Contents/Info.plist")
			if [[ "${installerVersion}" != "16.4.08" ]]; then
				/bin/echo "Invalid installer version found... deleting...."
				rm -rf "/Applications/Install macOS Big Sur.app"
				fDownloadInstaller
			else
				/bin/echo "Correct Installer Version is Present"
				try="6"
			fi
		fi
	done

	if [ ! -e "/Applications/Install macOS Big Sur.app" ]; then
		/bin/echo "Download failed..."
		exit 1
	else
		fWelcomeB
	fi
}

fInstallPrompt ()
{
	title="macOS ${instVers} Update - Install In Progress"
	message="The update is now installing... Please do not use the computer...\n\nIt may take up to 35 minutes before the computer restarts."
	osaWindow=$(/usr/bin/osascript<<END
	with timeout of 10800 seconds
	display dialog "${message}" with icon file "${iconFile}" with title "${title}" buttons {"Close"} default button 1
	end timeout
END
) &
}

fErrorOut ()
{
	/usr/bin/killall caffeinate
	/usr/bin/killall osascript

	title="macOS ${instVers} Update - Install Failed"
	message="The update failed to install.\n\nPlease contact ${orgAndDeptName}"
	osaWindow=$(/usr/bin/osascript<<END
	display dialog "${message}" with icon file "${iconFile}" with title "${title}" buttons {"Close"} default button 1
END
) &
	exit 6
}

fInstall ()
{

	if [[ "${LaunchInstallerOnly}" = "1" ]]; then 
		/bin/echo "Configured to only launch the installer... opening now..."
			/usr/bin/sudo -u ${currentUser} /usr/bin/open -a "/Applications/Install macOS Big Sur.app" &
			exit 0
	fi
	
	/usr/bin/caffeinate -disu &
	
	if [[ "${processorBrand}" = *"Apple"* ]]; then
		/bin/echo "Apple Processor is present..."
		fRunASInstall
	else
		/bin/echo "Apple Processor is not present..."
		fInstallPrompt &
		fRunIntelInstall
	fi

}

fRunIntelInstall ()
{

	TriggerInstall=$('/Applications/Install macOS Big Sur.app/Contents/Resources/startosinstall' --agreetolicense --forcequitapps)
	
	cmdStat=$?
	
	/bin/echo ${TriggerInstall}
	/bin/echo ${cmdStat}
	
	if [ "${cmdStat}" != "0" ]; then
		/bin/echo "Unexpected Error Occurred... Failing and notifying user..."
		fErrorOut
	else
		exit 0
	fi

}

fGetPassword()
{

	/bin/echo "Password Attempt number ${passwordTry}"
	until [ "${passwordTry}" -ge 5 ]
	do

	title="macOS ${instVers} Update - Authentication Required"
	message="Please enter your macOS login password."
	passwordInput=$(/usr/bin/osascript<<END
	with timeout of ${osatimeout} seconds
	display dialog "${message}\n\n${WARN}" with icon file "${iconFile}" buttons {"Defer ${deferralWindow} hour(s)", "Continue"} default answer "" with hidden answer default button 2 with title "${title}" giving up after ${osagiveup}
	copy the result as list to {text_returned, button_pressed}
	end timeout
END
)

	password=$(/bin/echo "${passwordInput}" | /usr/bin/awk -F, '{ print $2 }' | /usr/bin/xargs /bin/echo -n)

	passwordinput_button=$(/bin/echo "${passwordInput}" | /usr/bin/awk -F, '{ print $1 }')

	if [ "${passwordinput_button}" = "Defer ${deferralWindow} hour(s)" ]; then
		/bin/echo "User chose to be defer 1 day... will try again...."
		fDefer
	elif [ "${passwordinput_button}" = "Continue" ]; then
		/bin/echo "User supplied a password..."
		passwordTry=$((passwordTry+1))
	else
		/usr/bin/killall caffeinate
		/bin/echo "Window timed out.. will try again later..."
		exit 0
	fi
		
		escapedPassword=$(echo ${password} | /usr/bin/python -c "import re, sys; print(re.escape(sys.stdin.read().strip()))")
		
		validatePassword=$(/usr/bin/expect<<EOF

spawn /usr/bin/dscl /Local/Default -authonly ${currentUser}
expect {
	"Password:" {
		send "${escapedPassword}\r"
		exp_continue
	}
}
EOF
)
		
		
		if [[ "${validatePassword}" == *"eDSAuthFailed"* ]]; then
			/bin/echo "Password incorrect, unable to get auth..prompting for password attempt"
			WARN="Incorrect Password or other failure... if repeated issues please contact ${orgAndDeptName}\n\nPassword Attempt: ${passwordTry}"
			fGetPassword
		else
			fTriggerASInstall
		fi

done
/bin/echo "Too many password attempts..."
/usr/bin/killall caffeinate
exit 3

}

# Starts the install on Apple Silicon devices
fRunASInstall ()
{
	secureTokenCheck=$(/usr/sbin/sysadminctl -secureTokenStatus ${currentUser} 2>&1)

	if [[ "${secureTokenCheck}" = *"ENABLED"* ]]; then
		/bin/echo "${currentUser} is a ST user and can proceed..."
	else
		/bin/echo "${currentUser} is NOT A ST user and CANNOT authorize the update."
		exit 2
	fi

	fGetPassword
}

fTriggerASInstall ()
{

fInstallPrompt &

TriggerInstall=$(
( /bin/cat <<EOF
${password}
EOF
) | '/Applications/Install macOS Big Sur.app/Contents/Resources/startosinstall' --agreetolicense --forcequitapps --user ${currentUser} --stdinpass 2>&1)
	
cmdStat=$?

password=""

/bin/echo ${TriggerInstall}
/bin/echo ${cmdStat}

	if [[ "${TriggerInstall}" = *"Error: could not get authorization..."* ]]; then
		/bin/echo "Password incorrect or another issue, unable to get auth..prompting for password attempt"
		WARN="Incorrect Password or other failure... if repeated issues please contact IT\n\nPassword Attempt: ${passwordTry}"
		fGetPassword
	elif [ "${cmdStat}" != "0" ]; then
		echo "Unexpected Error Occurred... Failing and notifying user..."
		fErrorOut
	fi
}

fDownloadInstaller