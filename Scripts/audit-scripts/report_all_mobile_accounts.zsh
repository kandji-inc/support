#!/bin/zsh

#
#   Get all user accounts with a UID greater than 500 and report if they are mobile accounts
#

# Creates a list of users with a UID greater than 500
# Users with a UID less than UID 500 are typically services accuonts
USER_LIST=($(/usr/bin/dscl . list /Users UniqueID |
    /usr/bin/awk '$2 > 500 {print $1}' |
    /usr/bin/sed -e 's/^[ \t]*//'))

# Check to see if the user_list is empty
if [[ "$USER_LIST" == "" ]]; then
    # If no users with UID over 1000 are returned, Quit.
    echo "No user accounts found."
    echo "Nothing to do ..."
    echo "Exiting ..."
    echo ""
    exit 0
fi

# If the list contianed users with UID over 1000 print them to stdout
for user in $USER_LIST; do

    # Verify that the accounts found are actually mobile accounts
    echo "Checking user account type for $user ..."

    # Grab the user account type
    _ACCOUNT_TYPE=$(/usr/bin/dscl . \
        -read /Users/"$user" AuthenticationAuthority |
        /usr/bin/head -2 |
        /usr/bin/awk -F'/' '{print $2}' |
        /usr/bin/tr -d '\n' |
        /usr/bin/sed -e 's/^[ \t]*//')

    if [[ $_ACCOUNT_CHECK -eq 1 ]]; then
        # Check the user account type before attemtpting to convert the account.

        _MOBILE_USER_CHECK=$(/usr/bin/dscl . \
            -read /Users/"$user" AuthenticationAuthority |
            /usr/bin/head -2 |
            /usr/bin/awk -F'/' '{print $1}' |
            /usr/bin/tr -d '\n' |
            /usr/bin/sed 's/^[^:]*: //' |
            /usr/bin/sed s/\;/""/g)
    fi

    if [[ $_ACCOUNT_TYPE = "Active Directory" ]] || [[ $_MOBILE_USER_CHECK = "LocalCachedUser" ]]; then
        echo "$user has an AD mobile account."
        echo "Converting to a local account with the same username and UID."
    else
        echo "The $user account is not a AD mobile account."
        echo ""
        # break
    fi

done
