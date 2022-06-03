#!/bin/zsh
###################################################################################################
# Created by Noah Anderson | se@kandji.io | Kandji, Inc. | Systems Engineering
###################################################################################################
# Created on 06/03/2022
###################################################################################################
# Software Information
###################################################################################################
#
# Script downloads two 1Password 8 .apps, one for Intel architecture, one for Apple silicon, and 
# builds a combined Universal macOS Installer component package which will place the native .app 
# in /Applications for the appropriate Mac architecture.
#
# Validates proper Developer ID Authority/Team Identifier on .app bundles
# Validates matching application versions and bundle identifiers on .app bundles
# If any of those checks fail, package will not build and script will exit 1
#
###################################################################################################
# Usage
###################################################################################################
#
# Run the below command; a PKG will be created in the directory from where the script is executed
#
# /bin/zsh /path/to/Create_1Password8_Package.zsh
#
###################################################################################################
###################################################################################################
# License Information
###################################################################################################
# Copyright 2022 Kandji, Inc.
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
###################################################################################################

############################
##########VARIABLES#########
############################

#Download URLs for both platform archs
apple_download="https://downloads.1password.com/mac/1Password-latest-aarch64.zip"
intel_download="https://downloads.1password.com/mac/1Password-latest-x86_64.zip"

#ZIP and application names
apple_zip="1Password-Apple.zip"
intel_zip="1Password-Intel.zip"
app_name="1Password.app"

#Temp build directories for package creation
tmp_build_dir="/tmp/1PW8"
tmp_build_dir_apple="${tmp_build_dir}/Apple"
tmp_build_dir_intel="${tmp_build_dir}/Intel"
tmp_build_dir_scripts="${tmp_build_dir}/Scripts"

#Code signatory values to confirm security
dev_id_authority="AgileBits Inc. (2BUA8C4S2C)"
team_identifier="2BUA8C4S2C"

###########################
#########PRECHECKS#########
###########################

#If previous directory exists from failed run, remove it
if [[ -d "${tmp_build_dir}" ]]; then
    /bin/echo "Previous build directory found... removing"
    /bin/rm -R "${tmp_build_dir}"
fi

#Create empty directories to populate
/bin/mkdir -p "${tmp_build_dir_apple}" "${tmp_build_dir_intel}" "${tmp_build_dir_scripts}"

#Download our arm64 and x86_64 .zips for 1PW8
/bin/echo "Beginning download of ${apple_zip}"
/usr/bin/curl -L "${apple_download}" -o "${tmp_build_dir_apple}/${apple_zip}"
/bin/echo "Beginning download of ${intel_zip}"
/usr/bin/curl -L "${intel_download}" -o "${tmp_build_dir_intel}/${intel_zip}"

#Unzip both installs to architecture-specific folders and remove the zips upon success
/usr/bin/unzip "${tmp_build_dir_apple}/${apple_zip}" -d "${tmp_build_dir_apple}" >/dev/null 2>&1 && /bin/rm "${tmp_build_dir_apple}/${apple_zip}"
/usr/bin/unzip "${tmp_build_dir_intel}/${intel_zip}" -d "${tmp_build_dir_intel}" >/dev/null 2>&1 && /bin/rm "${tmp_build_dir_intel}/${intel_zip}"

#Validate TeamID and Signing Authority
/bin/echo "Beginning security checks..."
apple_teamid=$(/usr/bin/codesign -dvv "${tmp_build_dir_apple}/${app_name}" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2)
intel_teamid=$(/usr/bin/codesign -dvv "${tmp_build_dir_intel}/${app_name}" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2)
apple_dev_authority=$(/usr/bin/codesign -dvv "${tmp_build_dir_apple}/${app_name}" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs)
intel_dev_authority=$(/usr/bin/codesign -dvv "${tmp_build_dir_intel}/${app_name}" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs)

#Run security checks
if [[ "${apple_teamid}" == "${team_identifier}" ]] && [[ "${intel_teamid}" == "${team_identifier}" ]] && [[ "${apple_dev_authority}" == "${dev_id_authority}" ]] && [[ "${intel_dev_authority}" == "${dev_id_authority}" ]]; then
    /bin/echo "All security checks passed"
else
    #If security checks do not match expected values, report defined and expected values to stdout and exit 1 
    /bin/echo "ERROR: Expected values for Team Identifier and Developer Authority did not match!"
    /bin/echo "Expected Team Identifier is ${team_identifier}"
    /bin/echo "Apple .app Team Identifier is ${apple_teamid}"
    /bin/echo "Intel .app Team Identifier is ${intel_teamid}"
    /bin/echo "Expected Developer Authority is ${dev_id_authority}"
    /bin/echo "Apple .app Developer Authority is ${apple_dev_authority}"
    /bin/echo "Intel .app Developer Authority is ${intel_dev_authority}"
    /bin/echo "Installation package for 1Password 8 was NOT created"
    /bin/echo "Inspect temp build directory at ${tmp_build_dir} for issues"
    exit 1
fi

#NOTE: Script will only build PKG if both Intel + Apple silicon .apps have identical versions and bundle identifiers
#This is to ensure our created installation package has the correct version and bundle ID for either install 

#Get Short Versions
apple_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${tmp_build_dir_apple}/${app_name}/Contents/Info.plist")
intel_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${tmp_build_dir_intel}/${app_name}/Contents/Info.plist")

#Get Bundle IDs
apple_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${tmp_build_dir_apple}/${app_name}/Contents/Info.plist")
intel_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${tmp_build_dir_intel}/${app_name}/Contents/Info.plist")

#Ensure both match
if [[ "${apple_version}" == "${intel_version}" ]]; then
    version="${apple_version}"
fi

if [[ "${apple_version}" == "${intel_version}" ]]; then
    identifier="${apple_id}"
fi

#Validate joint version and identifier vars are valid
#If not, values may be mismatched between Apple and Intel builds
if [[ -n "${version}" ]] && [[ -n "${identifier}" ]]; then
    /bin/echo "Identified ${app_name} version as ${version}"
    /bin/echo "Identified ${app_name} bundle ID as ${identifier}"
else
    #If ${version} and/or ${identifier} are not defined, exit 1 and report defined values to stdout
    /bin/echo "ERROR: Derived values for version and/or identifier did not match or was not found"
    /bin/echo "Identified Apple version as ${apple_version}"
    /bin/echo "Identified Intel version as ${intel_version}"
    /bin/echo "Identified Apple identifier as ${apple_id}"
    /bin/echo "Identified Intel identifier as ${intel_id}"
    /bin/echo "Installation package for 1Password 8 was NOT created"
    /bin/echo "Inspect temp build directory at ${tmp_build_dir} for issues"
    exit 1
fi

###############
#####BUILD#####
###############

#Move our arch-specific folders containing the .app to our Scripts folder
/bin/mv "${tmp_build_dir_apple}" "${tmp_build_dir_intel}" "${tmp_build_dir_scripts}"

#Preinstall below lives in the same Scripts directory as the .app folders
#At installation time, script will identify processor type and then copy the correct .app bundle to /Applications
#Write out preinstall heredoc and expand variables
/bin/cat >"${tmp_build_dir_scripts}/preinstall" <<EOF
#!/bin/zsh

#Populate PKG names
apple_app="Apple/${app_name}"
intel_app="Intel/${app_name}"
EOF

#Write out the remainder of the preinstall and do not expand vars
/bin/cat >>"${tmp_build_dir_scripts}/preinstall" <<"EOF"
#Get local directory
local_dir=$(/usr/bin/dirname ${0})

#Identify Mac processor type
intel_check=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | /usr/bin/grep -oi "Intel")

if [[ "${intel_check}" ]]; then
    /bin/cp -r "${local_dir}/${intel_app}" "/Applications"
else
    /bin/cp -r "${local_dir}/${apple_app}" "/Applications"
fi

exit 0
EOF

#Make preinstall executable
/bin/chmod a+x "${tmp_build_dir_scripts}/preinstall"

#Build our package with a preinstall governing which .app installs on which architecture
/usr/bin/pkgbuild --nopayload --scripts "${tmp_build_dir_scripts}" --identifier "${identifier}" --version ${version} "./1Password-${version}.pkg"
/bin/echo "PKG created at $(/bin/pwd)/1Password-${version}.pkg"

#Remove our temporary build directory
/bin/rm -r "${tmp_build_dir}"

exit 0
