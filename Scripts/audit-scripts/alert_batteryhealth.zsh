#!/bin/zsh
# Script is designed to trigger an alert in Kandji if the battery condition is not normal and/or if the cycle count has reached a given threshold.
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
