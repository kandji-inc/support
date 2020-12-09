#!/bin/bash
################################################################################################
# Created by Jim Quilty | se@kandji.io | Kandji, Inc. | Solutions Engineering
################################################################################################
# Created on 12/09/2020
################################################################################################
# Software Information
################################################################################################
# This script resets the permissions on the /private/tmp folder if they changed
################################################################################################
# License Information
################################################################################################
# Copyright 2020 Kandji, Inc. 
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

# Get current permissions on /private/tmp folder
tmpPerms=$(stat -f "%Sp" /private/tmp)
tmpOwn=$(stat -f "%Su" /private/tmp)
tmpGroup=$(stat -f "%Sg" /private/tmp)

# Check if permissions are correct
if [ "$tmpPerms" == "drwxrwxrwt" ]; then
  echo "Permissions are correct. Nothing to do..."
  else
  echo "Permissions are not correct. Fixing..."
  chmod 777 /private/tmp
  chmod +t /private/tmp
fi

# Check if owner and group are correct
if [ "$tmpOwn" == 'root' ] && [ "$tmpGroup" == 'wheel' ]; then
  echo "Owner and Group are correct. Nothing to do..."
  else
  echo "Permissions are not correct. Fixing..."
  chown root:wheel /private/tmp
fi