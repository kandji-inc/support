#!/bin/bash
################################################################################################
# Created by Jim Quilty | se@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 12/30/2020
################################################################################################
# Software Information
################################################################################################
# Script to download and install a large PKG file via curl and verify it's checksum.
# The PKG needs to be Zipped before uploading to your preferred storage bucket.
# Set the variables for your download URL and the SHA 256 checksum of the ZIP file.
################################################################################################
# License Information
################################################################################################
# Copyright 2020 Kandji, Inc. 
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

## User Set Variables ##

# Download URL
dlURL="DOWNLOAD_URL"

# SHA256 checksum of the ZIP file for verification Example: shasum -a 256 PATH/TO/FILE
fileChecksum="FILE_CHECKSUM"

################################################################################################

## Other Variables ##
finalURL=$(/usr/bin/curl "$dlURL" -s -L -I -o /dev/null -w '%{url_effective}')
fileName="${finalURL##*/}"
fileExt=$(echo "${fileName##*.}" | /usr/bin/awk '{print tolower($0)}')
tmpDir="/private/tmp/download"
pathToFile="$tmpDir/$fileName"
dlTries=1
vfTries=0
percent=0

## Create Functions ##
successTest() {
	# Test if last run command was successful
	if [ $? -ne 0 ]; then
    echo "$1"
		exit 1
	fi
}

downloadFile() {
  /usr/bin/curl -Ls "$finalURL" -o "$pathToFile"
  while [[ "$?" -ne 0 ]]; do
    echo "Download Failed, retrying.  This is attempt $dlTries"
    sleep 5
    (( dlTries++ ))
    if [ "$dlTries" == 11 ]; then
      echo "Download has failed 10 times, exiting"
      exit 1
    fi
    /usr/bin/curl -Ls "$finalURL" -o "$pathToFile"
  done
}

getDownloadSize() {
	/usr/bin/curl -sI "$finalURL" | /usr/bin/grep -i Content-Length | /usr/bin/awk '{print $2}' | /usr/bin/tr -d '\r'
}

dlPercent() {
	fSize=$(/bin/ls -nl "$pathToFile" | /usr/bin/awk '{print $5}')
	percent=$(echo "scale=2;($fSize/$dlSize)*100" | bc)
	percent=${percent%.*}
}

processZIP() {
  echo "Unzipping $pathToFile..."
	/usr/bin/unzip -oqd "$tmpDir" "$pathToFile"
	successTest "Unzip failed. Exiting..."
  pkgName=$(/usr/bin/find "$tmpDir" -iname *.pkg -d 1)
  successTest "No PKG file found in $tmpDir. Exiting..."
  rm -rf "$pathToFile"
  echo "PKG to install: $pkgName"
}

installPKG() {
  processZIP
  echo "PKG to install: $pkgName"
  /usr/sbin/installer -pkg "$pkgName" -target /
  successTest "Something went wrong during install..."
  echo "Install completed successfully..."
}

## Execute ##

# Check that the file to download is a ZIP
if [[ "$fileExt" != "zip" ]]; then
  echo "A ZIP file was not detected. Please check the download URL and try again..."
  exit 1
fi

# Create temp directory for download
if [ -d "$tmpDir" ]; then
	/bin/rm -rf "$tmpDir"
	/bin/mkdir "$tmpDir"
else
	/bin/mkdir "$tmpDir"
fi

# Keep machine awake, as if user is active.
# Clear caffeinate automatically upon script termination.
/usr/bin/caffeinate -disu -w $$ &

# Download & Validate File
dlSize=$(getDownloadSize)
dlSUM=""
while [ "$fileChecksum" != "$dlSUM" ]; do
  echo "Attempting to download and verify $fileName..."
  (( vfTries++ ))
  if [ $vfTries == 4 ]; then
  echo "Download and Verification has failed 3 times, exiting..."
  exit 1
  fi
  downloadFile &
  pid=$!
  # If this script is killed, kill the download.
  trap "kill $pid 2> /dev/null" EXIT
  # Track download progress
  while kill -0 $pid 2> /dev/null; do
    if [ -f "$pathToFile" ]; then
      dlPercent
      echo "Download at $percent%"
      sleep 10
    fi
  done 
  # Disable the trap on a normal exit.
  trap - EXIT
  echo "Download complete. Verifying file..."
  dlSUM=$(/usr/bin/shasum -a 256 "$pathToFile" | /usr/bin/cut -d ' ' -f1)
done

# Perform Installation
installPKG

# Cleanup
echo "Cleaning up files and processes..."
sleep 10
/bin/rm -R "$tmpDir"

exit 0
