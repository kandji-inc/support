#Requires -Version 5.1

<#
.SYNOPSIS
    Add Iru's hosted MCP URL to Claude Desktop on Windows via mcp-remote (stdio bridge).

.DESCRIPTION
    Merges an iru MCP server entry into Claude Desktop's claude_desktop_config.json using npx
    and mcp-remote as a stdio-to-HTTP bridge, using the same url and headers (X-API-Key,
    X-MCP-Profile) as in MCP configuration from Copy MCP configuration in Iru.

.NOTES
    Version            : 1.0.1
    Author             : Iru, Inc.
    Copyright          : (c) 2026 Iru, Inc.
    License            : MIT License - full text in the License Information block in this script file.
    Compatible with    : Windows PowerShell 5.1 and PowerShell 7+
    Prerequisites      : Node.js 20+ (npx on PATH); Claude Desktop for Windows

    Config path        : Squirrel (default) install:
                           %LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json
                         Classic EXE install fallback:
                           %APPDATA%\Claude\claude_desktop_config.json

    Log path           : Same directory as config, under logs\mcp-server-iru.log

    For prerequisites, env vars, and full setup context, see Related Links (Get-Help -Full).

.PARAMETER Interactive
    Prompts for url, X-API-Key, and X-MCP-Profile from MCP configuration (Copy MCP configuration in Iru). Values are
    merged into claude_desktop_config.json only (not written to process environment variables). Without -Interactive,
    set IRU_MCP_URL, IRU_X_API_KEY, and IRU_X_MCP_PROFILE in the shell to match that JSON (same PASTE_ placeholders as
    the Iru MCP article).

.EXAMPLE
    $env:IRU_MCP_URL = 'PASTE_MCP_CONFIGURATION_URL'
    $env:IRU_X_API_KEY = 'PASTE_MCP_CONFIGURATION_X_API_KEY'
    $env:IRU_X_MCP_PROFILE = 'PASTE_MCP_CONFIGURATION_X_MCP_PROFILE'
    .\iru-mcp-claude-desktop-windows.ps1

.LINK
    https://docs.iru.com/en/endpoint/api/model-context-protocol/iru-mcp
#>

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

[CmdletBinding()]
param (
    [switch] $Interactive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-IruSecrets {
    if ($Interactive) {
        [string]$s = Read-Host 'IRU MCP server URL (HTTPS url from MCP configuration)'
        if ([string]::IsNullOrWhiteSpace($s)) { throw 'IRU_MCP_URL URL is required.' }
        if ($s -notmatch '^https://') { throw 'IRU_MCP_URL must be an HTTPS URL.' }

        $secureKey = Read-Host 'X-API-Key (exact value from headers in MCP configuration, including sk_live: if shown)' -AsSecureString
        [string]$k = [System.Net.NetworkCredential]::new('', $secureKey).Password
        if ([string]::IsNullOrWhiteSpace($k)) { throw 'IRU_X_API_KEY is required.' }

        [string]$p = Read-Host 'X-MCP-Profile (value from headers in MCP configuration)'
        if ([string]::IsNullOrWhiteSpace($p)) { throw 'IRU_X_MCP_PROFILE is required.' }

        return @{
            Server    = $s.Trim()
            ApiKey    = $k.Trim()
            ProfileId = $p.Trim()
        }
    }

    foreach ($pair in @(
            @{ Var = 'IRU_MCP_URL';     Msg = 'Set IRU_MCP_URL (or pass -Interactive)' },
            @{ Var = 'IRU_X_API_KEY';    Msg = 'Set IRU_X_API_KEY (or pass -Interactive)' },
            @{ Var = 'IRU_X_MCP_PROFILE'; Msg = 'Set IRU_X_MCP_PROFILE (or pass -Interactive)' }
        )) {
        $v = [Environment]::GetEnvironmentVariable($pair.Var, 'Process')
        if (-not [string]::IsNullOrWhiteSpace($v)) { continue }
        throw $pair.Msg
    }

    [string]$server = [Environment]::GetEnvironmentVariable('IRU_MCP_URL', 'Process').Trim()
    if ($server -notmatch '^https://') { throw 'IRU_MCP_URL must be an HTTPS URL.' }

    return @{
        Server    = $server
        ApiKey    = [Environment]::GetEnvironmentVariable('IRU_X_API_KEY',    'Process').Trim()
        ProfileId = [Environment]::GetEnvironmentVariable('IRU_X_MCP_PROFILE', 'Process').Trim()
    }
}

$iru = Resolve-IruSecrets
$iruServer = $iru.Server.TrimEnd('/')
$iruKey = $iru.ApiKey
$iruProfile = $iru.ProfileId

$remotePkg = if (-not [string]::IsNullOrWhiteSpace($env:IRU_MCP_REMOTE_PKG)) {
    $env:IRU_MCP_REMOTE_PKG.Trim()
} else {
    'mcp-remote@0.1.13'
}

# Resolve the real npx path explicitly. Node version managers (Nodist, nvm, volta) put a shim
# first on PATH that writes plain text to stdout when no version is configured - Claude Desktop
# communicates with MCP servers via stdout JSON-RPC and immediately fails to parse that text.
# Using the full path to the real npx bypasses the shim entirely.
$allNpx = (cmd /c "where npx" 2>$null) -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$npxPath = $allNpx |
    Where-Object { $_ -notlike '*nodist*' -and $_ -notlike '*nvm*' -and $_ -notlike '*volta*' } |
    Sort-Object { if ($_ -like '*.cmd') { 0 } else { 1 } } |  # prefer .cmd over bare name
    Select-Object -First 1
if (-not $npxPath) { $npxPath = $allNpx | Select-Object -First 1 }
if (-not $npxPath) {
    throw 'npx not found. Install Node.js 20+ and ensure npm is on PATH, then rerun.'
}

# Squirrel-installed Claude Desktop sandboxes %APPDATA% under a fixed Packages subfolder.
# Check that specific path first; fall back to the classic %APPDATA% path for EXE installs.
$squirrelConfigDir = "$env:LOCALAPPDATA\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude"
$configDir = if (Test-Path $squirrelConfigDir) { $squirrelConfigDir } else { Join-Path $env:APPDATA 'Claude' }
$configPath = Join-Path $configDir 'claude_desktop_config.json'
$bakPath = "$configPath.bak"

# Claude Desktop on Windows wraps .cmd files via "cmd.exe /C", and any space in any argument
# corrupts cmd.exe's command-line parsing - including the path to npx.cmd itself. Keeping the
# sensitive values in env and referencing them with ${VAR} (no space after colon) avoids this.
$newIruArgs = '-y', $remotePkg, $iruServer, '--header', 'X-API-Key:${IRU_X_API_KEY}', '--header', 'X-MCP-Profile:${IRU_X_MCP_PROFILE}'

$newIruEnv = [PSCustomObject][ordered]@{
    IRU_X_API_KEY    = $iruKey
    IRU_X_MCP_PROFILE = $iruProfile
}

$newIruEntry = [PSCustomObject][ordered]@{
    command = $npxPath
    args    = $newIruArgs
    env     = $newIruEnv
}

[System.IO.Directory]::CreateDirectory($configDir) | Out-Null

if (Test-Path -LiteralPath $configPath) {
    Copy-Item -LiteralPath $configPath -Destination $bakPath -Force
    Write-Host "Backed up existing config to $(Split-Path $bakPath -Leaf)" -ForegroundColor DarkGray

    try {
        $raw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
        $existing = $raw | ConvertFrom-Json

        # StrictMode treats missing properties as errors: $cfg.mcpServers throws when JSON had no "mcpServers" key.
        # PSObject.Properties.Match looks up the member without implying it exists.
        $msMember = @( $existing.PSObject.Properties.Match('mcpServers') )

        if (($msMember.Count -eq 0) -or ($null -eq $msMember[0].Value)) {
            $mcpServers = New-Object PSCustomObject
        } else {
            $mcpServers = $msMember[0].Value
        }
        $mcpServers | Add-Member -MemberType NoteProperty -Name iru -Value $newIruEntry -Force

        # Build $cfg with mcpServers first, then all other existing properties.
        $cfg = New-Object PSCustomObject
        $cfg | Add-Member -MemberType NoteProperty -Name mcpServers -Value $mcpServers -Force
        foreach ($prop in $existing.PSObject.Properties) {
            if ($prop.Name -ne 'mcpServers') {
                $cfg | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
            }
        }
    }
    catch {
        throw @"
Failed to read or merge $configPath :

$($_)

Repair the JSON manually, restore from $($bakPath), or rename the corrupt file aside and rerun.

"@
    }
}
else {
    $cfg = [PSCustomObject][ordered]@{
        mcpServers = [PSCustomObject][ordered]@{ iru = $newIruEntry }
    }
}

# -Depth avoids truncating nested args (ConvertTo-Json default depth is shallow on 5.x).
# -Compress first, then reformat to 2-space - avoids PS 5.x staircase indentation entirely.
$payload = $cfg | ConvertTo-Json -Depth 20 -Compress
$sb = New-Object System.Text.StringBuilder
$indent = 0; $inStr = $false; $i = 0
while ($i -lt $payload.Length) {
    $c = $payload[$i]
    if ($inStr) {
        [void]$sb.Append($c)
        if ($c -eq '\' -and ($i + 1) -lt $payload.Length) { $i++; [void]$sb.Append($payload[$i]) }
        elseif ($c -eq '"') { $inStr = $false }
    } else {
        switch -exact ($c) {
            '"'     { $inStr = $true; [void]$sb.Append($c) }
            '{'     { [void]$sb.Append($c); $indent++; [void]$sb.Append("`n" + ('  ' * $indent)) }
            '}'     { $indent--;             [void]$sb.Append("`n" + ('  ' * $indent) + $c) }
            '['     { [void]$sb.Append($c); $indent++; [void]$sb.Append("`n" + ('  ' * $indent)) }
            ']'     { $indent--;             [void]$sb.Append("`n" + ('  ' * $indent) + $c) }
            ','     { [void]$sb.Append($c); [void]$sb.Append("`n" + ('  ' * $indent)) }
            ':'     { [void]$sb.Append(': ') }
            default { [void]$sb.Append($c) }
        }
    }
    $i++
}
$payload = $sb.ToString()
$payload = $payload -replace '\[\s+\]', '[]'
$payload = $payload -replace '\{\s+\}', '{}'

$utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false
[System.IO.File]::WriteAllText($configPath, $payload, $utf8)

$logPath = Join-Path $configDir 'logs\mcp-server-iru.log'

Write-Host ''
Write-Host '[OK] IRU MCP server added to Claude Desktop config.' -ForegroundColor Green
Write-Host "  Config : $configPath"
Write-Host "  Logs   : $logPath"
Write-Host "  Bridge : $npxPath $remotePkg -> $iruServer"
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Fully quit Claude Desktop (right-click the system tray icon -> Quit), then reopen it.'
Write-Host '  2. Open a new chat.'
Write-Host '  3. Click the + button beside the composer.'
Write-Host '  4. Choose Ask Iru.'
Write-Host '  5. Start typing a message so Claude can use the Iru MCP.'
Write-Host '  6. To turn Iru on or off without editing the config, click +, open Connectors, and use the Iru toggle.'
Write-Host '  7. If something fails: in Claude Desktop open Settings -> Developer to review the Iru MCP'
Write-Host "     server configuration, whether it is running, and any errors. Logs: $logPath"
Write-Host ''
Write-Host "(Credentials not echoed; verify in $configPath if needed)"