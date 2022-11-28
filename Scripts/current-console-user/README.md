# Verious methods to return the current user on macOS

### More "Apple" way of grabbing this informationUse the scutil command to get the current user.

POSIX `sh` has an issue with this one: https://github.com/koalaman/shellcheck/wiki/SC2039#here-strings

[Credit to Erik Berglund](https://erikberglund.github.io/2018/Get-the-currently-logged-in-user,-in-Bash/)

```shell
#!/usr/bin/env zsh

CURRENT_LOGGEDIN_USER="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')"
```

### Get the owner of /dev/console using stat command

This version is honored by the `sh` shell

```
CURRENT_LOGGEDIN_USER=$(stat -f '%Su' /dev/console)
```

### Here is another way of doing it with python in bash
```
CURRENT_LOGGEDIN_USER=$(/usr/bin/python -c 'from SystemConfiguration \
    import SCDynamicStoreCopyConsoleUser; \
    import sys; \
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
    username = [username,""][username in [u"loginwindow", None, u""]]; \
    sys.stdout.write(username + "\n");')
```
