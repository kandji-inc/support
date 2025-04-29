#!/bin/zsh

################################################################################################
# Created by Nicholas McDonald, Kandji Fellow | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 04/19/2025
#   Updated - 04/19/2025
# 	Version - 1
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   - macOS 15
#   - macOS 14
#
################################################################################################
# Software Information
################################################################################################
#
# This script checks for long-lived power management assertions on macOS that may prevent the 
# system from entering idle sleep or starting the screensaver. If any assertion exceeds a 
# specified time threshold, the script can either report it or attempt to terminate the owning 
# process, depending on configuration. It is especially useful for detecting misbehaving apps 
# (such as Adobe CEPHtmlEngine) that silently keep the system awake.
#
# By default, the script only reports offending processes. When configured to `kill`, the script
# will automatically terminate long-lived assertion holders **only if they are owned by real 
# user accounts** (not system or service users).
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2025 Kandji, Inc.
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

# Set this line to the number of hours a given power management assertion should not exceed
# If any assertion exceeds this threshold it will be reported or acted upon.
notToExceedHours="5"

# Set this value to "report" if the script should exit and report long lived power assertions
# Set this value to "kill" if the script should kill the owning process.
killOrReport="kill"

#########################################################################################
echo "Script is set to ${killOrReport} power assertions lived for more than ${notToExceedHours} hours."

# Threshold to compare to in seconds
thresholdSeconds=$((notToExceedHours * 3600))

# Function to get all active assertions
get_pmset_output() {
  pmset -g assertions
}

# Function to check if a process name still holds an assertion
is_assertion_held_by_process() {
  local targetProcessName="$1"
  local current_pmset_output
  current_pmset_output=$(get_pmset_output)

  echo "$current_pmset_output" | grep -E "pid [0-9]+\(" | grep -q "\($targetProcessName\)"
  return $?
}

foundLongAssertion=false

# Capture initial pmset output
pmset_output=$(get_pmset_output)

# Parse owning processes
echo "$pmset_output" | grep -E "pid [0-9]+\(" | while read -r line; do
  # Extract PID, Process Name, Hours, Minutes, Seconds
  pid=$(echo "$line" | sed -nE 's/.*pid ([0-9]+)\(.*/\1/p')
  processName=$(echo "$line" | sed -nE 's/.*pid [0-9]+\(([^)]+)\).*/\1/p')
  timeHms=$(echo "$line" | sed -nE 's/.*\] ([0-9]+):([0-9]+):([0-9]+) .*/\1 \2 \3/p')

  if [[ -n "$timeHms" ]]; then
    # Split into hours minutes seconds
    set -- ${(s: :)timeHms}
    hours=$1
    minutes=$2
    seconds=$3

    # Convert to total seconds
    uptime_seconds=$(( (hours * 3600) + (minutes * 60) + seconds ))

    # Compare to threshold
    if (( uptime_seconds > thresholdSeconds )); then
      echo "Assertion too long lived by process: $processName (PID: $pid) - Uptime ${hours}h ${minutes}m ${seconds}s"

      if [[ "$killOrReport" == "kill" ]]; then
        # Find process owner
        owner=$(ps -o user= -p $pid 2>/dev/null | xargs)

        if [[ -n "$owner" ]]; then
          # Only kill if the owner is NOT root or a service account
          if [[ "$owner" != "root" && "$owner" != _* ]]; then
            echo "Killing process $processName (PID: $pid) owned by user $owner..."
            kill -9 $pid
            sleep 2  # Give time for the system to clear it out

            # Recheck if assertion is still held
            if is_assertion_held_by_process "$processName"; then
              echo "WARNING: Assertion still held by process name $processName even after killing PID $pid."
            else
              echo "SUCCESS: Assertion by $processName cleared after killing PID $pid."
            fi
          else
            echo "Skipping killing process $processName (PID: $pid) owned by system/service user $owner."
          fi
        else
          echo "Unable to determine owner of PID $pid. Skipping."
        fi
      fi

      foundLongAssertion=true
    fi
  fi
done

if $foundLongAssertion; then
  echo "One or more long lived assertions detected."
  exit 2
else
  echo "No long lived assertions."
  exit 0
fi
