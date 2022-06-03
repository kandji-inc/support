# Delete inactive user accounts

### About

This script is designed to be run from Kandji as a customer script library item. The script will look for and remove any user accounts that are older than the number of days specified in the `AGE` varialbe and do not appear in the `KEEP` list.

### Script modification

Update the variables below to meet your needs

```shell
###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

# Delete /User/ folders inactive longer than this many days
AGE=90

# User folders you would like to bypass. Typically local users or admin accounts.
# Modify this list as needed
KEEP=(
    "/Users/Shared"
    "/Users/support"
    "/Users/student"
    "/Users/testuser"
    "/Users/localadmin"
)
```