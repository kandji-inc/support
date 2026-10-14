#!/bin/zsh

################################################################################################
# License Information
################################################################################################
#
# Copyright 2026 Iru, Inc.
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

# Script is designed to trigger an alert in Iru if the battery condition is not normal and/or if the cycle count has reached a given threshold.
# Inspired by Matt Wilson's original batteryhealth script.

#Amount of cycles after you which you'd want to receive an alert.
cycleAlert=1000

##############################################################
# VARIABLES
##############################################################
#Determine model
model=`system_profiler SPHardwareDataType | grep "Model Name:" | cut -d ' ' -f 9`

##############################################################
# MAIN
##############################################################
if [[ "$model" =~ "Book" ]]; then
  #Determine battery condition
  batteryCondition=$(system_profiler SPPowerDataType | grep "Condition" | xargs)
  batteryCycles=$(system_profiler SPPowerDataType | grep "Cycle Count" | awk '{print $3}')
  
  if [[ $batteryCondition == "Condition: Normal" && $batteryCycles -lt $cycleAlert ]]; then
   echo "$batteryCondition, Battery cycle count is $batteryCycles"
    exit 0
  else
    echo "WARNING! $batteryCondition, Battery cycle count is $batteryCycles."
    exit 1
  fi
else
  echo "This computer is not a MacBook"
  exit 0
fi

exit 0
