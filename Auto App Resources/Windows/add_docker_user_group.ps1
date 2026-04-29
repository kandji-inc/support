################################################################################################
# Created by Noah Anderson | Iru, Inc. | Systems Engineering
################################################################################################
# Script Information
################################################################################################
#
# Adds the interactive desktop user to the docker-users local group. Identifies the currently
# logged-in interactive user by finding the owner of the explorer.exe process, then creates
# the docker-users local group if it does not exist and adds the user to it.
#
# Flow:
#   1. Identify the interactive user via the explorer.exe process owner
#   2. Create the docker-users local group if it does not already exist
#   3. Add the user to the group (idempotent -- skips if already a member)
#
# Accepts an optional -Debug switch for verbose logging.
# Exits 0 on success or if no interactive user is found (e.g. running in a session with no
# desktop). Exits 1 on any failure. Designed for unattended post-install deployment.
#
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

#Requires -RunAsAdministrator

#############################
######### ARGUMENTS #########
#############################

param(
    [switch]$Debug
)

#############################
######### VARIABLES #########
#############################

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:DebugMode = $Debug.IsPresent
$script:LogFile = $null
$script:DockerGroupName = "docker-users"


#######################
####### LOGGING #######
#######################

function Write-ScriptLog {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    $line = "$timestamp [$Level] $Message"
    Write-Output $line
    if ($script:LogFile) { Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 }
}

function Write-InfoLog  { param([string]$Message) Write-ScriptLog -Level "INFO"  -Message $Message }
function Write-WarnLog  { param([string]$Message) Write-ScriptLog -Level "WARN"  -Message $Message }
function Write-ErrorLog { param([string]$Message) Write-ScriptLog -Level "ERROR" -Message $Message }
function Write-DebugLog { param([string]$Message) if ($script:DebugMode) { Write-ScriptLog -Level "DEBUG" -Message $Message } }

function Initialize-Logger {
    $programData = [Environment]::GetFolderPath("CommonApplicationData")
    $dir = Join-Path $programData "DockerDesktop\AddUser\Logs"
    $null = New-Item -ItemType Directory -Path $dir -Force

    $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $script:LogFile = Join-Path $dir "AddUser_$stamp.log"

    Write-InfoLog ("Log file: {0}" -f $script:LogFile)

    $envComputer = [Environment]::GetEnvironmentVariable("COMPUTERNAME")
    if ($envComputer) { Write-InfoLog ("Machine: {0}" -f $envComputer) }

    $osVersion = [Environment]::OSVersion.Version
    Write-InfoLog ("OS: {0}.{1}.{2}" -f $osVersion.Major, $osVersion.Minor, $osVersion.Build)
}


#############################
######### FUNCTIONS #########
#############################

function Get-InteractiveUser {
    # Finds the owner of the first explorer.exe process; returns "DOMAIN\User" or $null.
    try {
        $proc = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction Stop |
                Select-Object -First 1

        if (-not $proc) {
            Write-DebugLog "No explorer.exe process found; no interactive user detected."
            return $null
        }

        $owner = $proc | Invoke-CimMethod -MethodName GetOwner -ErrorAction Stop
        if (-not $owner -or [string]::IsNullOrEmpty($owner.User)) {
            Write-DebugLog "explorer.exe owner query returned no user."
            return $null
        }

        $qualified = "{0}\{1}" -f $owner.Domain, $owner.User
        Write-DebugLog ("Interactive user: {0}" -f $qualified)
        return $qualified
    } catch {
        Write-WarnLog ("Failed to query explorer.exe owner: {0}" -f $_.Exception.Message)
        return $null
    }
}

function Confirm-DockerUsersGroup {
    try {
        $existing = Get-LocalGroup -Name $script:DockerGroupName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-DebugLog ("Group '{0}' already exists." -f $script:DockerGroupName)
            return $true
        }

        Write-InfoLog ("Creating local group '{0}'." -f $script:DockerGroupName)
        New-LocalGroup -Name $script:DockerGroupName -ErrorAction Stop | Out-Null
        Write-InfoLog ("Group '{0}' created." -f $script:DockerGroupName)
        return $true
    } catch {
        Write-ErrorLog ("Failed to create group '{0}': {1}" -f $script:DockerGroupName, $_.Exception.Message)
        return $false
    }
}

function Add-UserToDockerGroup {
    param([string]$User)

    try {
        $members = Get-LocalGroupMember -Group $script:DockerGroupName -ErrorAction Stop
        $alreadyMember = $members | Where-Object { $_.Name -eq $User }
        if ($alreadyMember) {
            Write-InfoLog ("'{0}' is already a member of '{1}'; skipping." -f $User, $script:DockerGroupName)
            return $true
        }
    } catch {
        Write-DebugLog ("Could not enumerate group members: {0}" -f $_.Exception.Message)
    }

    try {
        Add-LocalGroupMember -Group $script:DockerGroupName -Member $User -ErrorAction Stop
        Write-InfoLog ("Added '{0}' to '{1}'." -f $User, $script:DockerGroupName)
        return $true
    } catch {
        Write-ErrorLog ("Failed to add '{0}' to '{1}': {2}" -f $User, $script:DockerGroupName, $_.Exception.Message)
        return $false
    }
}


##############
#### MAIN ####
##############

function Invoke-Main {
    Initialize-Logger
    Write-InfoLog "Starting Docker Desktop add-user..."

    $user = Get-InteractiveUser
    if (-not $user) {
        Write-WarnLog "No interactive user found; nothing to do."
        Write-InfoLog "Script exit code: 0 (success)"
        exit 0
    }

    Write-InfoLog ("Interactive user: {0}" -f $user)

    if (-not (Confirm-DockerUsersGroup)) {
        Write-ErrorLog "Could not ensure docker-users group exists. Aborting."
        Write-ErrorLog "Script exit code: 1"
        exit 1
    }

    if (-not (Add-UserToDockerGroup -User $user)) {
        Write-ErrorLog "Script exit code: 1"
        exit 1
    }

    Write-InfoLog "Script exit code: 0 (success)"
    exit 0
}


###########################
######## ENTRYPOINT #######
###########################
Invoke-Main
