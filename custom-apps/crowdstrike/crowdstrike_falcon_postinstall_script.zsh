#!/bin/zsh

################################################################################################
# Created by David Larrea & Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
# Created - 2021-08-26
# Last modified - 2024-03-26 - Joe Borner
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   15.0.1
#   14.7
#   13.7
#   12.7.6
#
################################################################################################
# Software Information
################################################################################################
#
# This script licenses the CrowdStrike Falcon agent
#
# Configuration profiles are included with the Crowdstrike deployment instructions
# found in the Kandji Knowledge Base.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2024 Kandji, Inc.
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

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# Put your install token here if applicable, otherwise leave blank.
# Example : customerIDChecksum="A43190DDA81403RANd-91"
customerIDChecksum=""

# Put your install token here if applicable, otherwise leave blank.
# Example : installToken="A313G7326"
installToken=""

########################################################################################
##################################### FUNCTIONS ########################################
########################################################################################

# license CrowdStrike Agent
/Applications/Falcon.app/Contents/Resources/falconctl license "${customerIDChecksum}" "${installToken}" 2>&1

exit 0