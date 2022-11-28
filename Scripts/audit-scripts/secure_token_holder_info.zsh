###################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
###################################################################################################
#
#   Created on 2022-04-13
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
#   12.3.1
#   11.6.5
#   10.15.7
#
###################################################################################################
# Software Information
###################################################################################################
#
#   This Audit script is designed to audit and report on secure token holder information on macOS.
#
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
###################################################################################################

###################################################################################################
############################# DO NOT MODIFY BELOW THIS LINE #######################################
###################################################################################################

# Report back to Kandji

/bin/echo "#######################################################"

# report bootstrap token status
/usr/bin/profiles status -type=bootstraptoken

/bin/echo ""

# report cryptographic users
/usr/sbin/diskutil apfs listUsers /

# Loop over users return from dscl excluding _, root, daemon, and nobody
for u in $(/usr/bin/dscl . -list /Users | grep -Ev '_|root|daemon|nobody'); do

    /bin/echo "GeneratedUID for $u: $(/usr/bin/dscl . -read /Users/$u GeneratedUID | /usr/bin/awk '{print $2}')"

    # secure token status for user
    /usr/sbin/sysadminctl -secureTokenStatus $u 2>&1

done

/bin/echo "#######################################################"

exit 0
