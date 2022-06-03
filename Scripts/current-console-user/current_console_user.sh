#!/usr/bin/env zsh

#
#   Verious methods to return the current user on macOS
#

# More "Apple" way of grabbing this informationUse the scutil command to get the
# current user.
#
# Credit to Erik Berglund:
#       https://erikberglund.github.io/2018/Get-the-currently-logged-in-user,-in-Bash/
# POSIX sh has an issue with this one:
#       https://github.com/koalaman/shellcheck/wiki/SC2039#here-strings
CURRENT_USER_VERSION_1="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')"

# Get the owner of /dev/console using stat command
# This version is honored by the sh shell
CURRENT_USER_VERSION_2=$(stat -f '%Su' /dev/console)

# Here is another way of doing it with python in bash
CURRENT_USER_VERSION_3=$(/usr/bin/python -c 'from SystemConfiguration \
    import SCDynamicStoreCopyConsoleUser; \
    import sys; \
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
    username = [username,""][username in [u"loginwindow", None, u""]]; \
    sys.stdout.write(username + "\n");')

#######################################################################################

echo "Using scutil binary: $CURRENT_USER_VERSION_1"
echo "Using stat binary: $CURRENT_USER_VERSION_2"
echo "Using Python2: $CURRENT_USER_VERSION_3"
