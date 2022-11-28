#!/bin/zsh

#
#   Report all local user accounts with a UID greater than 500
#

# Creates a list of users with a UID greater than 500
# Users with a UID less than UID 500 are typically services accuonts
USER_LIST=($(/usr/bin/dscl . list /Users UniqueID |
    /usr/bin/awk '$2 > 500 {print $1}'))

echo "Checking user account permissions ..."

# Determine if any of the local users have standard permissions
for user in $USER_LIST; do

    # Verify that the accounts found are actually mobile accounts
    # Returns true if the current logged in user is a member of the local admins group.
    GROUP_MEMBERSHIP=$(/usr/bin/dscl . read /groups/admin | /usr/bin/grep "$user")
    RET="$?"

    if [ "$RET" -eq 0 ]; then
        # User is in the admin group
        echo "$user has admin permissions ..."
    else
        # User is not in the admin group
        echo "$user has standard permissions ..."
    fi

done
