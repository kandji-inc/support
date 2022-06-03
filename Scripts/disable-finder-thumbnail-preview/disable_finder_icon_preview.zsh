#!/bin/zsh

###################################################################################################
# Created by Matt Wilson | se@kandji.io | Kandji, Inc. | Solutions Engineering
###################################################################################################
# Created on 05/09/2021
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.0.1
#   11.6.1
#   11.6
#   11.5.2
#
###################################################################################################
# Software Information
###################################################################################################
#
#   Disable Finder icon(thumbnail) preview for all users on a Mac
#
###################################################################################################
# License Information
###################################################################################################
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
###################################################################################################

VERSION="1.1.0"

###################################################################################################
######################################## FUNCTIONS ################################################
###################################################################################################

get_all_users() {
    # Get all users with a UID greater than 500

    # Creates a list of users with a UID 501 or higher
    # Creates a list of users with a UID greater than 500
    # Users with a UID less than UID 500 are typically services accuonts
    user_list=$(/usr/bin/dscl . list /Users UniqueID |
        /usr/bin/awk '$2 > 500 {print $1}')

    # Return the user_list
    echo "$user_list"
}

###################################################################################################
######################################## MAIN SCRIPT ##############################################
###################################################################################################

main() {
    # This function runs the main logic for this script

    # Store the user list
    echo "Grabbing user accounts ..."
    user_list="$(get_all_users)"

    # Check to see if the user_list is empty
    if [[ "$user_list" == "" ]]; then
        # If no users with UID over 1000 are returned, Quit.
        echo "No user accounts found."
        echo "Nothing to do ..."
        echo "Exiting ..."
        echo ""
        exit 0
    fi

    # Declare the array so that we can use it
    declare -a user_array

    # To handle the way zsh does string splitting, or lack there of, we are putting the orignial
    # user_list into an array and converting to the sh style string splitting. This will allow us
    # to loop over the results.
    user_array=( ${=user_list} )

    for user in $user_array; do

        echo "Modifying Finder for user: $user"

        # Delete the existing cover-flow preview setting
        /usr/libexec/PlistBuddy -c \
            "delete 'StandardViewSettings':ExtendedListViewSettingsV2:showIconPreview" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Delete the existing icon preview setting
        /usr/libexec/PlistBuddy -c \
            "delete 'StandardViewSettings':IconViewSettings:showIconPreview" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Delete the existing list preview setting
        /usr/libexec/PlistBuddy -c \
            "delete 'StandardViewSettings':ListViewSettings:showIconPreview" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Delete the existing column preview setting
        /usr/libexec/PlistBuddy -c \
            "delete 'StandardViewOptions':ColumnViewOptions:ShowIconThumbnails" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Reset the cover-flow preview setting to off
        /usr/libexec/PlistBuddy -c \
            "add 'StandardViewSettings':ExtendedListViewSettingsV2:showIconPreview bool false" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Reset the icon preview setting to off
        /usr/libexec/PlistBuddy -c \
            "add 'StandardViewSettings':IconViewSettings:showIconPreview bool false" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Reset the list preview setting to off
        /usr/libexec/PlistBuddy -c \
            "add 'StandardViewSettings':ListViewSettings:showIconPreview bool false" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Reset the column preview setting to off
        /usr/libexec/PlistBuddy -c \
            "add 'StandardViewOptions':ColumnViewOptions:ShowIconThumbnails bool false" \
            "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Make sure that the current user owns their Finder preference list.
        /usr/sbin/chown $user "/Users/$user/Library/Preferences/com.apple.finder.plist"

        # Add the com.apple.desktopservices plist containing a key to prevent the writing of
        # .DS_Store files to netowrkshares
        /usr/libexec/PlistBuddy -c \
            "add 'DSDontWriteNetworkStores' bool true" \
            "/Users/$user/Library/Preferences/com.apple.desktopservices.plist"

        # Make sure that the current user owns their desktopservices preference list.
        /usr/sbin/chown -R "$user":staff \
            "/Users/$user/Library/Preferences/com.apple.desktopservices.plist"

    done

    # Restart the cfprefsd process
    killall cfprefsd

    # Restart the Finder
    killall Finder

}

# Call the main function
main

# Exit gracefully
exit 0
