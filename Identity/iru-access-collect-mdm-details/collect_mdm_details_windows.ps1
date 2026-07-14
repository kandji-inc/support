################################################################################################
# Software Information
################################################################################################
#
#   Reads the MDM server Provider ID and Discovery service URL from an enrolled
#   Windows device. Run in PowerShell on a device already enrolled in your MDM
#   when creating an Iru Identity MDM connection.
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

[CmdletBinding()]
param(
    [string]
    $ProviderId
)

$basePaths = @(
    "HKLM:\SOFTWARE\Microsoft\Enrollments",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Enrollments"
)

$records = @()

function Get-EnrollmentRecords {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string] $Filter
    )

    if (-not (Test-Path -Path $Path)) {
        return
    }

    Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | ForEach-Object {
        $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        if (-not $props) {
            return
        }

        $record = [PSCustomObject]@{
            ProviderId          = $props.ProviderID
            DiscoveryServiceUrl = $props.DiscoveryServiceFullURL
            Upn                 = $props.UPN
            EnrollmentKey       = $_.PSChildName
        }

        if (-not $record.ProviderId) {
            return
        }

        if (-not $Filter -or ($record.ProviderId -ieq $Filter)) {
            $record
        }
    }
}

foreach ($path in $basePaths) {
    $records += Get-EnrollmentRecords -Path $path -Filter $ProviderId
}

if (-not $records) {
    Write-Warning "No enrollment records found under $($basePaths -join ', ')."
    return
}

$records |
    Sort-Object ProviderId, EnrollmentKey |
    Format-Table -AutoSize |
    Out-String -Width 4096 |
    Write-Output
