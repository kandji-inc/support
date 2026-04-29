################################################################################################
# Created by Noah Anderson | Iru, Inc. | Systems Engineering
################################################################################################
# Script Information
################################################################################################
#
# Force-installs the Chrome Remote Desktop browser extension via Windows registry policy by
# writing to the ExtensionInstallForcelist registry key for any supported browser (Chrome,
# Edge) detected on the machine. Browsers that are not installed are skipped with a warning.
# The operation is idempotent -- re-running will not add duplicate entries.
#
# Flow:
#   1. Detect Chrome and Edge via App Paths registry, with filesystem fallback
#   2. For each detected browser, ensure its ExtensionInstallForcelist policy key exists
#   3. Skip if the extension is already listed; otherwise write it at the next available index
#
# Accepts an optional -Debug switch for verbose logging.
# Exits 0 on success or if no browsers are installed. Exits 1 if any detected browser
# failed to have its policy key updated. Designed for unattended deployment.
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

$script:ExtensionId  = "inomeogfingihgjfjlpeplalcfajhgai"
$script:UpdateUrl    = "https://clients2.google.com/service/update2/crx"
$script:ForcelistValue = "{0};{1}" -f $script:ExtensionId, $script:UpdateUrl

$script:ChromeAppPathsKey  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe"
$script:EdgeAppPathsKey    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe"

$script:ChromeFallbackPaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)
$script:EdgeFallbackPaths = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
)

$script:ChromeForcelistPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
$script:EdgeForcelistPath   = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"


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
    $dir = Join-Path $programData "DeployCrdExtension\Logs"
    $null = New-Item -ItemType Directory -Path $dir -Force

    $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $script:LogFile = Join-Path $dir "DeployCrdExtension_$stamp.log"

    Write-InfoLog ("Log file: {0}" -f $script:LogFile)

    $envComputer = [Environment]::GetEnvironmentVariable("COMPUTERNAME")
    if ($envComputer) { Write-InfoLog ("Machine: {0}" -f $envComputer) }

    $osVersion = [Environment]::OSVersion.Version
    Write-InfoLog ("OS: {0}.{1}.{2}" -f $osVersion.Major, $osVersion.Minor, $osVersion.Build)
}


#############################
######### FUNCTIONS #########
#############################

function Test-BrowserInstalled {
    param(
        [string]$AppPathsKey,
        [string[]]$FallbackPaths
    )

    if (Test-Path $AppPathsKey -ErrorAction SilentlyContinue) {
        $exePath = (Get-ItemProperty -Path $AppPathsKey -ErrorAction SilentlyContinue).'(default)'
        if (-not [string]::IsNullOrEmpty($exePath) -and (Test-Path $exePath -ErrorAction SilentlyContinue)) {
            Write-DebugLog ("Browser found via App Paths: {0}" -f $exePath)
            return $true
        }
    }

    foreach ($path in $FallbackPaths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            Write-DebugLog ("Browser found via filesystem fallback: {0}" -f $path)
            return $true
        }
    }

    return $false
}

function Test-ExtensionForcelisted {
    param([string]$RegistryPath)

    if (-not (Test-Path $RegistryPath -ErrorAction SilentlyContinue)) { return $false }

    $props = Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue
    if ($null -eq $props) { return $false }

    foreach ($name in $props.PSObject.Properties.Name) {
        if ($name -match '^\d+$') {
            $val = $props.$name
            if ($val -like "*$script:ExtensionId*") {
                Write-DebugLog ("Extension already listed under value '{0}': {1}" -f $name, $val)
                return $true
            }
        }
    }

    return $false
}

function Get-NextForcelistIndex {
    param([string]$RegistryPath)

    if (-not (Test-Path $RegistryPath -ErrorAction SilentlyContinue)) { return 1 }

    $props = Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue
    if ($null -eq $props) { return 1 }

    $indices = @($props.PSObject.Properties.Name | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
    if ($indices.Count -eq 0) { return 1 }

    $max = ($indices | Measure-Object -Maximum).Maximum
    return $max + 1
}

function Add-ExtensionToPolicy {
    param(
        [string]$BrowserName,
        [string]$RegistryPath
    )

    if (Test-ExtensionForcelisted -RegistryPath $RegistryPath) {
        Write-InfoLog ("{0}: extension already in ExtensionInstallForcelist; skipping." -f $BrowserName)
        return $true
    }

    try {
        if (-not (Test-Path $RegistryPath -ErrorAction SilentlyContinue)) {
            Write-DebugLog ("{0}: creating policy key: {1}" -f $BrowserName, $RegistryPath)
            $null = New-Item -Path $RegistryPath -Force
        }

        $index = Get-NextForcelistIndex -RegistryPath $RegistryPath
        Write-DebugLog ("{0}: writing value at index {1}: {2}" -f $BrowserName, $index, $script:ForcelistValue)
        Set-ItemProperty -Path $RegistryPath -Name ([string]$index) -Value $script:ForcelistValue -Type String
        Write-InfoLog ("{0}: extension added to ExtensionInstallForcelist at index {1}." -f $BrowserName, $index)
        return $true
    } catch {
        Write-ErrorLog ("{0}: failed to write ExtensionInstallForcelist: {1}" -f $BrowserName, $_.Exception.Message)
        return $false
    }
}


##############
#### MAIN ####
##############

function Invoke-Main {
    Initialize-Logger
    Write-InfoLog "Starting Chrome Remote Desktop extension deployment..."
    Write-InfoLog ("Extension ID: {0}" -f $script:ExtensionId)

    $attempted = 0
    $succeeded = 0

    if (Test-BrowserInstalled -AppPathsKey $script:ChromeAppPathsKey -FallbackPaths $script:ChromeFallbackPaths) {
        Write-InfoLog "Chrome detected."
        $attempted++
        if (Add-ExtensionToPolicy -BrowserName "Chrome" -RegistryPath $script:ChromeForcelistPath) {
            $succeeded++
        }
    } else {
        Write-WarnLog "Chrome not detected; skipping."
    }

    if (Test-BrowserInstalled -AppPathsKey $script:EdgeAppPathsKey -FallbackPaths $script:EdgeFallbackPaths) {
        Write-InfoLog "Edge detected."
        $attempted++
        if (Add-ExtensionToPolicy -BrowserName "Edge" -RegistryPath $script:EdgeForcelistPath) {
            $succeeded++
        }
    } else {
        Write-WarnLog "Edge not detected; skipping."
    }

    if ($attempted -eq 0) {
        Write-WarnLog "Neither Chrome nor Edge detected; nothing to do."
        Write-InfoLog "Script exit code: 0 (success)"
        exit 0
    }

    if ($succeeded -eq $attempted) {
        Write-InfoLog ("Extension policy applied to {0} browser(s)." -f $succeeded)
        Write-InfoLog "Script exit code: 0 (success)"
        exit 0
    }

    Write-ErrorLog ("Policy update failed for {0} of {1} browser(s)." -f ($attempted - $succeeded), $attempted)
    Write-ErrorLog "Script exit code: 1"
    exit 1
}


###########################
######## ENTRYPOINT #######
###########################
Invoke-Main
