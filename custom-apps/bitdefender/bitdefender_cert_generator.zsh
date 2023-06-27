#!/usr/bin/env zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2023-04-11
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.3.1
#
################################################################################################
# Software Information
################################################################################################
#
#   This script can be used to create a pfx cert for deploying with Bitdefender. The cert info
#   variables should be prepopulated in the script below.
#
#       # Cert info
#       COUNTRY="US"      # US - 2 letter country code
#       STATE="Georgia"   # Giorgia - state or province
#       LOCAL="Atlanta"   # Atlanta - locality name
#       ORG_NAME="Kandji" # Kandji - organization name
#       CERT_NAME="Kandji Bitdenfender CA SSL"      # Example: Kandji Bitdenfender CA SSL
#
#   Once the cert is generated, upload it to your Kandji tenant.
#
#   Bitdefender kb: https://www.bitdefender.com/business/support/en/77209-157498-install-security-agents---use-cases.html#UUID-00e93090-1040-8119-d7cf-c48320a8d6b7
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2023 Kandji, Inc.
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

################################################################################################
####################################### VARIABLES ##############################################
################################################################################################

# Cert info
COUNTRY=""                   # US - 2 letter country code
STATE=""                     # Georgia - state or province
LOCAL=""                     # Atlanta - locality name
ORG_NAME="Endpoint"          # Leave as default value
CERT_NAME="Kandji BD CA SSL" # Leave as default value

################################################################################################
############################ MAIN - DO NOT MODIFY BELOW ########################################
################################################################################################

# create some vars
bitdefender_tmp_dir="/var/tmp/tmp-bitdefender-cert"
current_user="$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" |
    /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' |
    /usr/bin/awk -F '@' '{print $1}')"

# if CERT_NAME is empty prompt the user
if [[ -z $COUNTRY ]] || [[ -z $STATE ]] || [[ -z $LOCAL ]] ||
    [[ -z $ORG_NAME ]] || [[ -z $CERT_NAME ]]; then
    /bin/echo ""
    /bin/echo "Please ensure that all information is entered in the VARIABLES section of "
    /bin/echo "this script. Then, run this script again."
    /bin/echo ""
    exit 1
fi

# list cert info
/bin/echo ""
/bin/echo "Certificate information entered:"
/bin/echo "Country: $COUNTRY"
/bin/echo "State/Province: $STATE"
/bin/echo "Locality: $LOCAL"
/bin/echo "Organization: $ORG_NAME"
/bin/echo "Certificate name: $CERT_NAME"
/bin/echo ""

if read -rq "confirm?Do the above settings look good? (Y/N): "; then
    /bin/echo ""
    /bin/echo "Sweet!!!"
    /bin/echo ""
else
    /bin/echo "Cert builder canceled, exiting..."
    exit 1
fi

/bin/echo "Please enter the uninstall password that you used when configuring the "
/bin/echo "package settings in the Bitdefender admin console. This password will be "
/bin/echo "hashed and used in the generation of the .pfx certificate. Once generated, "
/bin/echo "you will need to uploaded the certificate to Kandji in a Certificate library"
/bin/echo "item. Be sure to add the hash in the password field in the Library item as well."
/bin/echo ""
/bin/echo "NOTE: You will not see any entered text"

# prompt user
read -s "CERT_PASSWORD?Enter password: "
/bin/echo ""

# if CERT_PASSWORD is empty prompt the user
if [[ -z "$CERT_PASSWORD" ]]; then
    /bin/echo "A password was not entered."
    exit 1
fi

# prompt user
read -s "PASSWORD_CHECK?Verify password: "
/bin/echo ""

if [[ "$CERT_PASSWORD" != "$PASSWORD_CHECK" ]]; then
    /bin/echo "Passwords do not match. Please try again."
    exit 1
fi

# MD5 hashed password
hashed_password="$(/sbin/md5 -s $CERT_PASSWORD | awk '{print $4}')"

/bin/echo ""
/bin/echo "Creating $bitdefender_tmp_dir directory to store .key and .pem files for"
/bin/echo "use in generating the .pfx certificate."
/bin/echo ""

/bin/mkdir -p "${bitdefender_tmp_dir}"

/usr/bin/openssl req -new -days 1825 -nodes -x509 \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCAL/O=$ORG_NAME/CN=$CERT_NAME" \
    -keyout "$bitdefender_tmp_dir/root_ca.key" -out "$bitdefender_tmp_dir/root_ca.pem"

/bin/echo ""
/bin/echo "Creating cert with hashed password used in Bitdefender installer package settings."

/usr/bin/openssl pkcs12 -inkey "$bitdefender_tmp_dir/root_ca.key" \
    -in "$bitdefender_tmp_dir/root_ca.pem" -export -passout pass:"$hashed_password" \
    -out "/Users/$current_user/Desktop/certificate.pfx"

/bin/echo "The certificate.pfx file is on the Desktop."
/bin/echo ""
/bin/echo "NOTE: This cert needs to be uploaded to Kandji in a Certificate library item."
/bin/echo "NOTE: Use the following hash as the password in the Certificate library item."
/bin/echo "NOTE: This certificate needs to be added to the Bitdefender installer zip as well."
/bin/echo ""
/bin/echo "Please reference the Kandji Bitdefender support article for more information."
/bin/echo ""
/bin/echo "Password hash: $hashed_password"
/bin/echo ""

# open the user's Desktop in Finder.
/usr/bin/open "/Users/$current_user/Desktop"

/bin/echo "Cleaning up the $bitdefender_tmp_dir directory."
/bin/rm -Rf "$bitdefender_tmp_dir"
