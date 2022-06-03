#!/usr/bin/env zsh

#
#   Gets the curernt users UID
#   GitHub: @captam3rica
#

# copy paste the below into other scripts

get_current_user_uid() {
    # Return the current logged-in user's UID.
    # Will continue to loop until the UID is greater than 500

    current_user_uid=$(/usr/bin/id -u "$1")
    counter=0

    while [[ "$current_user_uid" -lt 501 ]] && [[ $counter -lt 6 ]]; do
        /usr/bin/logger "" "Current user is not logged in ... WAITING"
        /bin/sleep 1

        # Get the current console user again
        current_user="$1"

        # Get uid again
        current_user_uid=$(/usr/bin/id -u "$1")

        if [[ "$current_user_uid" -lt 501 ]]; then
            /usr/bin/logger "Current user: $current_user with UID $current_user_uid ..."
        fi

        counter=$((counter + 1))

        # waiting 5 seconds before next check
        /bin/sleep 5

    done
    printf "%s\n" "$current_user_uid"
}

###################################################################################################
####################################### MAIN LOGIC ################################################
###################################################################################################

# Get the current logged in user
current_user="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')"

# Get the current logged in user's UID
current_user_uid="$(get_current_user_uid $current_user)"

echo "Current logged in user: $current_user($current_user_uid)"

exit 0
