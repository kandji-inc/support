#!/usr/bin/env zsh

#
# A script to export ssh keys
#

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

# Do not modify the below, there be dragons. Modify at your own risk.

# Store the current logged in user
current_user=$(printf '%s' "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')

# User home dir
user_home="/Users/$current_user"

if [[ "$current_user" == "root" ]] || [[ "$current_user" == "_mbsetupuser" ]]; then
    echo "Current user is not logged in ..."
    echo "Will try again later ..."
    exit 0
fi

# Look for id_rsa.pub file
if [[ -e "$user_home/.ssh/id_rsa.pub" ]]; then
    echo "Found $user_home/.ssh/id_rsa.pub"
    ssh_keys="$(/bin/cat $user_home/.ssh/id_rsa.pub)"
    echo "$ssh_keys"

# Look for known_hosts file
elif [[ -e "$user_home/.ssh/known_hosts" ]]; then
    echo "Found $user_home/.ssh/known_hosts"
    ssh_keys="$(/bin/cat $user_home/.ssh/known_hosts)"
    echo "$ssh_keys"
else
    echo "No ssh key files found for $current_user ..."
    exit 0

fi

exit 0
