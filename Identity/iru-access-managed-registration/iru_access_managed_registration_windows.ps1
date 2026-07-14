################################################################################################
# Software Information
################################################################################################
#
#   Provisions an Iru Access MDM connection client secret on a managed Windows PC so the
#   device can register without user interaction. The script stores the secret in the
#   registry in the format Iru Access expects, encrypted to the device.
#
#   Deploy through your MDM as a custom script. Run elevated (as SYSTEM) on a schedule
#   after Iru Access is installed. Use Windows PowerShell 5.1 (powershell.exe).
#
#   For details, see:
#   https://docs.iru.com/en/identity/authentication/deploy-iru-access
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

<#
.SYNOPSIS
    Provisions the Iru Access MDM connection client secret on a managed Windows PC.

.DESCRIPTION
    Stores your MDM connection client secret on the device so Iru Access can register
    the PC as managed without the user entering the secret manually. Use manage
    --secret and --domain to store the secret, --list to verify it is present (prints
    a hash only), and --clear to remove it when rotating.

    The secret is written to the registry in the format Iru Access expects, encrypted
    to the device. The double backslashes in the registry path constants below are
    intentional — do not change them to single backslashes.

.NOTES
    Run from an elevated prompt when setting or clearing the secret (writing to HKLM
    requires Administrator). Listing works without elevation.

    Use Windows PowerShell 5.1 (powershell.exe); it ships with the .NET Framework DPAPI
    (System.Security) used here.

.EXAMPLE
    .\iru_access_managed_registration_windows.ps1 manage --secret <secret> --domain yourcompany.iru.com
    .\iru_access_managed_registration_windows.ps1 manage --list
    .\iru_access_managed_registration_windows.ps1 manage --clear yourcompany.iru.com
    .\iru_access_managed_registration_windows.ps1 list
    .\iru_access_managed_registration_windows.ps1 help
#>

Set-StrictMode -Off
Add-Type -AssemblyName System.Security

# --- Registry and encryption constants ---------------------------------------------------
$script:LegacyRegistryPath = 'SOFTWARE\\IruID'
$script:RegistryPath       = 'SOFTWARE\\IruID\\MdmSecrets'
$script:ValueName          = 'MdmSecret'
$script:EncryptionEntropy  = [System.Text.Encoding]::UTF8.GetBytes('IruID::MdmSecret::v1')
$script:Scope              = [System.Security.Cryptography.DataProtectionScope]::LocalMachine
$script:Hive               = [Microsoft.Win32.RegistryHive]::LocalMachine
$script:Views              = @(
    [Microsoft.Win32.RegistryView]::Registry64,
    [Microsoft.Win32.RegistryView]::Registry32
)

function Open-BaseKey($view) {
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($script:Hive, $view)
}

function Normalize-Domain($domain) {
    if ([string]::IsNullOrWhiteSpace($domain)) { return $null }
    return $domain.Trim().ToLowerInvariant()
}

# DPAPI-protected byte[] (current format) or a bare string (legacy value).
function Read-Secret($value) {
    if ($value -is [byte[]]) {
        if ($value.Length -gt 0) {
            try {
                $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect(
                    $value, $script:EncryptionEntropy, $script:Scope)
                return [System.Text.Encoding]::UTF8.GetString($decrypted)
            }
            catch [System.Security.Cryptography.CryptographicException] {
                return $null
            }
        }
        return $null
    }

    if ($value -is [string] -and -not [string]::IsNullOrEmpty($value)) {
        return $value
    }

    return $null
}

function New-RegistrySecurity {
    $security = New-Object System.Security.AccessControl.RegistrySecurity
    $security.SetAccessRuleProtection($true, $false)

    $admins = New-Object System.Security.Principal.SecurityIdentifier(
        [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
    $system = New-Object System.Security.Principal.SecurityIdentifier(
        [System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)
    $users = New-Object System.Security.Principal.SecurityIdentifier(
        [System.Security.Principal.WellKnownSidType]::BuiltinUsersSid, $null)

    $full  = [System.Security.AccessControl.RegistryRights]::FullControl
    $read  = [System.Security.AccessControl.RegistryRights]::ReadKey
    $none  = [System.Security.AccessControl.InheritanceFlags]::None
    $pnone = [System.Security.AccessControl.PropagationFlags]::None
    $allow = [System.Security.AccessControl.AccessControlType]::Allow

    $security.AddAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule($admins, $full, $none, $pnone, $allow)))
    $security.AddAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule($system, $full, $none, $pnone, $allow)))
    $security.AddAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule($users, $read, $none, $pnone, $allow)))

    return $security
}

function New-SecuredKey($base, $path) {
    $security = New-RegistrySecurity
    $key = $base.CreateSubKey(
        $path,
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        $security)
    if ($null -eq $key) {
        throw (New-Object System.InvalidOperationException("Failed to open the registry path for the client secret."))
    }
    $key.SetAccessControl($security)
    return $key
}

function Save-Secret($secret, $domain, $view) {
    try {
        $base = Open-BaseKey $view
        try {
            $key = New-SecuredKey $base $script:RegistryPath
            try {
                $plaintext = [System.Text.Encoding]::UTF8.GetBytes($secret)
                $protected = [System.Security.Cryptography.ProtectedData]::Protect(
                    $plaintext, $script:EncryptionEntropy, $script:Scope)
                $key.SetValue($domain, $protected, [Microsoft.Win32.RegistryValueKind]::Binary)
            }
            finally { $key.Dispose() }
        }
        finally { $base.Dispose() }
    }
    catch [System.Security.Cryptography.CryptographicException] {
        throw (New-Object System.InvalidOperationException("Failed to encrypt the client secret for storage.", $_.Exception))
    }
    catch [System.Security.SecurityException] {
        throw (New-Object System.InvalidOperationException("Failed to persist client secret to the registry due to insufficient permissions.", $_.Exception))
    }
    catch [System.UnauthorizedAccessException] {
        throw (New-Object System.InvalidOperationException("Failed to persist client secret to the registry due to insufficient permissions.", $_.Exception))
    }
}

function Set-Secret($secret, $domain) {
    if ($null -eq $secret) { throw (New-Object System.ArgumentNullException("secret")) }
    if ([string]::IsNullOrWhiteSpace($domain)) { throw (New-Object System.ArgumentNullException("domain")) }

    $normalized = Normalize-Domain $domain
    foreach ($view in $script:Views) {
        Save-Secret $secret $normalized $view
    }
}

function Get-SecretsFromView($view) {
    $items = @()
    try {
        $base = Open-BaseKey $view
        try {
            $key = $base.OpenSubKey($script:RegistryPath, $false)
            if ($null -eq $key) { return $items }
            try {
                foreach ($name in $key.GetValueNames()) {
                    $secret = Read-Secret $key.GetValue($name)
                    if (-not [string]::IsNullOrWhiteSpace($secret)) {
                        $items += [pscustomobject]@{ Domain = $name; Secret = $secret }
                    }
                }
            }
            finally { $key.Dispose() }
        }
        finally { $base.Dispose() }
    }
    catch [System.Security.SecurityException] { return @() }
    catch [System.UnauthorizedAccessException] { return @() }
    return $items
}

function Get-LegacySecret {
    foreach ($view in $script:Views) {
        try {
            $base = Open-BaseKey $view
            try {
                $key = $base.OpenSubKey($script:LegacyRegistryPath, $false)
                $raw = $null
                if ($null -ne $key) { $raw = $key.GetValue($script:ValueName) }
                $secret = Read-Secret $raw
                if (-not [string]::IsNullOrWhiteSpace($secret)) { return $secret }
            }
            finally {
                if ($null -ne $key) { $key.Dispose() }
                $base.Dispose()
            }
        }
        catch [System.Security.SecurityException] { return $null }
        catch [System.UnauthorizedAccessException] { return $null }
    }
    return $null
}

# Case-insensitive dedupe across both registry views, then legacy secret as "legacy".
function Get-AllSecrets {
    $result = @()
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($view in $script:Views) {
        foreach ($item in (Get-SecretsFromView $view)) {
            if ($seen.Add($item.Domain)) { $result += $item }
        }
    }

    $legacy = Get-LegacySecret
    if (-not [string]::IsNullOrWhiteSpace($legacy)) {
        if ($seen.Add('legacy')) {
            $result += [pscustomobject]@{ Domain = 'legacy'; Secret = $legacy }
        }
    }

    return ,$result
}

function Remove-Secret($domain, $view) {
    try {
        $base = Open-BaseKey $view
        try {
            $key = $base.OpenSubKey($script:RegistryPath, $true)
            if ($null -ne $key) {
                try { $key.DeleteValue($domain, $false) }
                finally { $key.Dispose() }
            }
        }
        finally { $base.Dispose() }
    }
    catch [System.Security.SecurityException] {
        throw (New-Object System.InvalidOperationException("Failed to remove client secret from the registry due to insufficient permissions.", $_.Exception))
    }
    catch [System.UnauthorizedAccessException] {
        throw (New-Object System.InvalidOperationException("Failed to remove client secret from the registry due to insufficient permissions.", $_.Exception))
    }
}

function Remove-AllSecrets($view) {
    try {
        $base = Open-BaseKey $view
        try {
            $key = $base.OpenSubKey($script:RegistryPath, $true)
            if ($null -eq $key) { return }
            try {
                foreach ($name in $key.GetValueNames()) {
                    $key.DeleteValue($name, $false)
                }
            }
            finally { $key.Dispose() }
        }
        finally { $base.Dispose() }
    }
    catch [System.Security.SecurityException] {
        throw (New-Object System.InvalidOperationException("Failed to remove client secret from the registry due to insufficient permissions.", $_.Exception))
    }
    catch [System.UnauthorizedAccessException] {
        throw (New-Object System.InvalidOperationException("Failed to remove client secret from the registry due to insufficient permissions.", $_.Exception))
    }
}

function Remove-LegacySecret($view) {
    try {
        $base = Open-BaseKey $view
        try {
            $key = $base.OpenSubKey($script:LegacyRegistryPath, $true)
            if ($null -ne $key) {
                try { $key.DeleteValue($script:ValueName, $false) }
                finally { $key.Dispose() }
            }
        }
        finally { $base.Dispose() }
    }
    catch [System.Security.SecurityException] {
        throw (New-Object System.InvalidOperationException("Failed to remove client secret from the registry due to insufficient permissions.", $_.Exception))
    }
    catch [System.UnauthorizedAccessException] {
        throw (New-Object System.InvalidOperationException("Failed to remove client secret from the registry due to insufficient permissions.", $_.Exception))
    }
}

function Clear-Secret($domain) {
    $normalized = Normalize-Domain $domain
    foreach ($view in $script:Views) {
        if ($null -eq $normalized) {
            Remove-AllSecrets $view
            Remove-LegacySecret $view
        }
        else {
            Remove-Secret $normalized $view
        }
    }
}

function Get-SecretHash($value) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($value))
    }
    finally { $sha.Dispose() }
    return (($bytes | ForEach-Object { $_.ToString('x2') }) -join '')
}

# --- Command-line interface -------------------------------------------------------------

function Write-Usage {
    [Console]::Out.WriteLine("Usage: iru_access_managed_registration_windows.ps1 <command> [options]")
    [Console]::Out.WriteLine("")
    [Console]::Out.WriteLine("Commands:")
    [Console]::Out.WriteLine("  manage --secret <secret> --domain <domain>   Stores the provided secret for the specified domain.")
    [Console]::Out.WriteLine("  manage --clear [domain]                      Removes the stored secret. If no domain is provided, clears all secrets.")
    [Console]::Out.WriteLine("  manage --list                                 Lists stored secrets and their hashes.")
    [Console]::Out.WriteLine("  help                                          Shows this help message.")
    [Console]::Out.WriteLine("")
    [Console]::Out.WriteLine("Run this tool from an elevated prompt when setting or clearing the secret.")
}

function Invoke-List {
    [Console]::Out.WriteLine("Listing secrets...")

    $secrets = @(Get-AllSecrets)
    foreach ($entry in $secrets) {
        $hash = Get-SecretHash $entry.Secret
        [Console]::Out.WriteLine("$($entry.Domain):$hash")
    }

    if ($secrets.Count -eq 0) {
        [Console]::Out.WriteLine("No stored secrets found.")
    }

    return 0
}

function Invoke-Manage($arguments) {
    $secret = $null
    $domain = $null
    $clear = $false
    $list = $false

    for ($i = 1; $i -lt $arguments.Count; $i++) {
        $arg = $arguments[$i].ToLowerInvariant()
        switch ($arg) {
            '--secret' {
                if (($i + 1) -ge $arguments.Count -or [string]::IsNullOrWhiteSpace($arguments[$i + 1])) {
                    [Console]::Error.WriteLine("Missing value for --secret.")
                    return 1
                }
                $i++
                $secret = $arguments[$i]
            }
            '--domain' {
                if (($i + 1) -ge $arguments.Count -or [string]::IsNullOrWhiteSpace($arguments[$i + 1])) {
                    [Console]::Error.WriteLine("Missing value for --domain.")
                    return 1
                }
                $i++
                $domain = $arguments[$i]
            }
            '--clear' { $clear = $true }
            '--list'  { $list = $true }
            default {
                [Console]::Error.WriteLine("Unknown argument '$($arguments[$i])'.")
                Write-Usage
                return 1
            }
        }
    }

    if ($list) {
        return Invoke-List
    }

    if (-not [string]::IsNullOrWhiteSpace($secret)) {
        if ([string]::IsNullOrWhiteSpace($domain)) {
            [Console]::Error.WriteLine("The --domain argument is required when setting a secret.")
            return 1
        }

        Set-Secret $secret $domain
        [Console]::Out.WriteLine("Client secret stored successfully for '$domain'.")
        return 0
    }

    if ($clear) {
        Clear-Secret $domain
        if ([string]::IsNullOrWhiteSpace($domain)) {
            [Console]::Out.WriteLine("Client secrets cleared.")
        }
        else {
            [Console]::Out.WriteLine("Client secret cleared for '$domain'.")
        }
        return 0
    }

    [Console]::Error.WriteLine("No action specified. Provide --secret/--domain to set, --clear to remove, or --list to view secrets.")
    Write-Usage
    return 1
}

function Invoke-Main($arguments) {
    if ($arguments.Count -eq 0) {
        Write-Usage
        return 1
    }

    $command = $arguments[0].ToLowerInvariant()
    switch ($command) {
        'manage' { return Invoke-Manage $arguments }
        'list'   { return Invoke-List }
        'help'   { Write-Usage; return 0 }
        default {
            [Console]::Error.WriteLine("Unknown command '$command'.")
            Write-Usage
            return 1
        }
    }
}

try {
    $exitCode = Invoke-Main @($args)
    exit $exitCode
}
catch [System.InvalidOperationException] {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
catch {
    [Console]::Error.WriteLine("An unexpected error occurred. Refer to the application data logs for details.")
    exit 99
}

