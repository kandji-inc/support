#!/bin/zsh

################################################################################################
# Software Information
################################################################################################
#
#   Reads the APNs topic and MDM Check-in URL from an enrolled Mac. Run on a device
#   already enrolled in your MDM when creating an Iru Identity MDM connection.
#
#   For details, see:
#   https://docs.iru.com/en/identity/authentication/deploy-iru-access#resources
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Kandji, Inc.
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
#
################################################################################################

/usr/bin/sudo /usr/bin/profiles -P -o stdout 2>/dev/null | /usr/bin/awk '
/CheckInURL = / {
    if (match($0, /"[^"]+"/)) {
        candidate_checkin = substr($0, RSTART+1, RLENGTH-2)
    }
}
/Topic = / {
    if (match($0, /"[^"]+"/)) {
        candidate_topic = substr($0, RSTART+1, RLENGTH-2)
    }
}
/PayloadType = "com.apple.mdm"/ {
    apns_topic = candidate_topic
    checkin_url = candidate_checkin
    print "APNs Topic: " apns_topic
    print "MDM Check-in URL: " checkin_url
    exit
}
'
