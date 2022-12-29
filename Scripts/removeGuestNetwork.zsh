#!/bin/zsh

###################################################################################################
# Created by Brian Goldstein | support@kandji.io | Kandji, Inc.
###################################################################################################
#
# Created - 05/28/2022
# Updated - 11/05/2022
#
###################################################################################################
# Tested macOS Versions
###################################################################################################
#
# 13.0
# 12.6.1
#
###################################################################################################
# Software Information
###################################################################################################
#
# PURPOSE
#
# This script removes a specific wireless network from the preferred list. If removal is performed,
# the script will attempt to switch to the preferred network if it is within range.
#
#
# EXAMPLE SCENARIO
#
# The correctNetwork uses 802.1x authentication, therefor the Mac must connected to a different
# network, often guest wifi at an office, to receive the 802.1x profile. Once this is accomplished
# the Mac may remain connected to the guest network due to the order in the preferred list.   
#
###################################################################################################
# License Information
###################################################################################################
#
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

# Script version
VERSION="1.0.1"

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

# The SSID of the network that you want to remove from the preferred list.
removeNetwork="Beekeepr Guest"

# The SSID of the network that your Mac should be connected to.
correctNetwork="Beekeepr"

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

wifiAdapter="$(/usr/sbin/networksetup -listallhardwareports | /usr/bin/awk '/Wi-Fi/{getline; print $2}')"
currentNetwork="$(/usr/sbin/networksetup -getairportnetwork $wifiAdapter | /usr/bin/awk -F": " '{print $2}')"
preferredNetworks="$(/usr/sbin/networksetup -listpreferredwirelessnetworks $wifiAdapter)"
airport=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport

if [[ ! $preferredNetworks =~ "$removeNetwork" ]]; then
     /bin/echo "$removeNetwork was not found in the preferred networks list"
     exit 0
else
    if [ "$currentNetwork" = "$correctNetwork" ]; then
        /bin/echo "Mac is already connected to $correctNetwork."    
        /usr/sbin/networksetup -removepreferredwirelessnetwork $wifiAdapter "$removeNetwork"
        /bin/echo "$removeNetwork has been removed from the preferred networks list"
        exit 0
    else
        if [[ $($airport -s "$correctNetwork") != "No networks found" ]]; then
            /bin/echo "Mac is not connected to $correctNetwork"
            /usr/sbin/networksetup -removepreferredwirelessnetwork $wifiAdapter "$removeNetwork"
            /bin/echo "Cycling Wi-Fi power to reconnect"
            /usr/sbin/networksetup -setairportpower $wifiAdapter off
            /usr/sbin/networksetup -setairportpower $wifiAdapter on

            until /usr/sbin/ipconfig getifaddr $wifiAdapter >/dev/null; do
                /bin/echo "Waiting for network connectivity..."
                /bin/sleep 1
            done

            until /sbin/ping -c1 -S $(/usr/sbin/ipconfig getifaddr $wifiAdapter) 8.8.8.8 >/dev/null 2>&1; do
                /bin/echo "Waiting for internet connectivity..."
            done
        
            currentNetwork="$(/usr/sbin/networksetup -getairportnetwork $wifiAdapter | /usr/bin/awk -F": " '{print $2}')"
        
            if [ "$currentNetwork" = "$correctNetwork" ]; then
                /bin/echo "Succesfully removed $removeNetwork and connected to $correctNetwork"
                exit 0
             else
                /bin/echo "Failed to connect to $correctNetwork"
                exit 1
            fi
        else
            /usr/sbin/networksetup -removepreferredwirelessnetwork $wifiAdapter "$removeNetwork"
            /bin/echo "$removeNetwork has been removed from the preferred networks list"
            /bin/echo "$correctNetwork is not available, skipping Wi-Fi power cycle"
            exit 0
        fi
    fi
fi