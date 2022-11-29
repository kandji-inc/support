#!/usr/bin/env zsh

#
# Audit script to report AD binding status
#

ad_status=$(/usr/bin/dscl localhost -list . |
    /usr/bin/grep "Active Directory" 2>/dev/null)

if [[ $ad_status == "Active Directory" ]]; then
    # If the Mac is bound to AD
    echo "This Mac  is bound to Active Directory."
    exit 1
else
    echo "This Mac is not bound to an AD domain."
    exit 0
fi
