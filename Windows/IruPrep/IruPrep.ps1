################################################################################################
# IruPrep.ps1
#   Interactive Windows readiness + network compatibility helper for Iru enrollment.
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


#Requires -Version 5.1

if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    Write-Error "IruPrep is a Windows-only utility. Run it from PowerShell on Windows."
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
} catch {}

# -----------------------------
# Branding / App Settings
# -----------------------------
$BrandName      = "Iru"
$ToolName       = "IruPrep Enrollment Compatibility Utility"
$ToolVersion    = "v1.5"

$AccentColor          = [System.Drawing.Color]::FromArgb(18, 22, 61)
$script:AccentDarkColor = [System.Drawing.Color]::FromArgb(
    [math]::Max(0, $AccentColor.R - 25),
    [math]::Max(0, $AccentColor.G - 25),
    [math]::Max(0, $AccentColor.B - 25))
$HeaderBgColor        = [System.Drawing.Color]::White

$LogoFileName   = "iru-logo.png"   # place next to the .ps1
$IconFileName   = "iru.ico"        # optional, next to the .ps1

# Sources for $LogoFileName / $IconFileName if missing locally.
$LogoUrl = "https://raw.githubusercontent.com/kandji-inc/support/refs/heads/main/Windows/IruPrep/iru-logo.png"
$IconUrl = "https://raw.githubusercontent.com/kandji-inc/support/refs/heads/main/Windows/IruPrep/iru.ico"

# Upstream copy of this script - checked at launch to offer self-update.
$UpstreamScriptUrl = "https://raw.githubusercontent.com/kandji-inc/support/refs/heads/main/Windows/IruPrep/IruPrep.ps1"

$DocsNetworkUrl = "https://docs.iru.com/en/iru/requirements/using-iru-on-enterprise-networks"

# Default output folder
$DefaultOutputFolder = Join-Path $env:USERPROFILE "Documents"

# Compares local $ToolVersion to the upstream copy on main; on user consent, overwrites
# the local file and relaunches. Silent on any network/parse/IO failure so offline runs
# still work. Loop-safe: the relaunched copy will match upstream and skip this branch.
function Invoke-SelfUpdate {
    $ScriptPath = $PSCommandPath
    if (-not $ScriptPath) { $ScriptPath = $MyInvocation.ScriptName }
    if (-not $ScriptPath -or -not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) { return }

    try {
        $resp = Invoke-WebRequest -Uri $UpstreamScriptUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    } catch { return }

    $content = $resp.Content
    if (-not $content) { return }

    $match = [regex]::Match($content, '\$ToolVersion\s*=\s*"(?<v>[^"]+)"')
    if (-not $match.Success) { return }
    $upstreamRaw = $match.Groups['v'].Value

    try {
        $upstreamVer = [version]($upstreamRaw -replace '^[vV]', '')
        $localVer    = [version]($ToolVersion  -replace '^[vV]', '')
    } catch { return }

    if ($upstreamVer -le $localVer) { return }

    $msg = "A newer version ($upstreamRaw) is available. You are running $ToolVersion.`nUpdate now? The tool will relaunch."
    $choice = [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "$ToolName : Update available",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information)

    if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try {
        $tmpPath = "$ScriptPath.new"
        [System.IO.File]::WriteAllText($tmpPath, $content, (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $tmpPath -Destination $ScriptPath -Force -ErrorAction Stop
        Start-Process -FilePath 'powershell.exe' `
            -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',$ScriptPath) `
            -ErrorAction Stop | Out-Null
        exit 0
    } catch {
        if (Test-Path -LiteralPath "$ScriptPath.new") {
            try { Remove-Item -LiteralPath "$ScriptPath.new" -Force -ErrorAction Stop } catch {}
        }
        [System.Windows.Forms.MessageBox]::Show(
            "Update failed: $($_.Exception.Message)`nContinuing with the current version.",
            "$ToolName -- Update failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
}

Invoke-SelfUpdate

# TCP latency thresholds (ms) for "healthy" handshake to TCP/443
$TcpRttPassMaxMs     = 300     # <= 300ms => PASS
$TcpRttInfoMaxMs     = 700     # 301-700ms => INFO, >700ms => FAIL
$TcpConnectTimeoutMs = 2500

# Single source of truth for subdomain validation
$script:SubdomainRegex = '^(?!-)[a-zA-Z0-9-]{1,63}(?<!-)$'

# Cancellation flag for network checks
$script:CancelRequested = $false

# -----------------------------
# Shared theme + data tables
# -----------------------------

# PASS/FAIL/INFO visual treatment for WinForms (Back/Fore) and HTML (Web*).
$Rgb = [System.Drawing.Color]
$script:StatusTheme = @{
    PASS = @{ Back = $Rgb::FromArgb(198,239,206); Fore = $Rgb::FromArgb(  0, 97,  0); HtmlBadgeClass = "badge-pass"; HtmlCalloutClass = "co-pass"; OsLabel = "Supported";     SnLabel = "Valid";   WebBg = "#dcfce7"; WebText = "#15803d"; WebAccent = "#16a34a" }
    FAIL = @{ Back = $Rgb::FromArgb(255,199,206); Fore = $Rgb::FromArgb(156,  0,  6); HtmlBadgeClass = "badge-fail"; HtmlCalloutClass = "co-fail"; OsLabel = "Not supported"; SnLabel = "Invalid"; WebBg = "#fee2e2"; WebText = "#dc2626"; WebAccent = "#dc2626" }
    INFO = @{ Back = $Rgb::FromArgb(255,235,156); Fore = $Rgb::FromArgb(156,101,  0); HtmlBadgeClass = "badge-info"; HtmlCalloutClass = "co-info"; OsLabel = "Unknown";       SnLabel = "Unknown"; WebBg = "#fef3c7"; WebText = "#d97706"; WebAccent = "#d97706" }
}

# Windows build -> marketing name lookup. First entry whose MinBuild is <= the
# device build wins; entries are pre-sorted highest-first.
$script:WindowsBuilds = (
    "26200=Windows 11 25H2","26100=Windows 11 24H2","22631=Windows 11 23H2",
    "22621=Windows 11 22H2","22000=Windows 11 21H2","19045=Windows 10 22H2",
    "19044=Windows 10 21H2","19043=Windows 10 21H1","19042=Windows 10 20H2",
    "19041=Windows 10 2004"
) | ForEach-Object { $K, $V = $_ -split '=', 2; @{ MinBuild = [int]$K; Name = $V } }

# Per-region endpoints. SubdomainSuffixes/UuidSuffixes are joined to the tenant subdomain/UUID at run time.
$script:RegionMap = @{
    EU = @{
        Base              = "kandji-prd-eu.s3.amazonaws.com","iru-prd-eu-managed-library-items.s3.amazonaws.com","managed-library.eu.kandji.io","managed-library.eu.iru.com","windows-agent.eu.kandji.io"
        SubdomainSuffixes = "iru.com","gateway.eu.iru.com","id.iru.com","id.eu.iru.com","id.connect.iru.com","id.connect.eu.iru.com","id.devices.eu.iru.com","id.gateway.eu.iru.com"
        UuidSuffixes      = "web-api.eu.kandji.io","devices.eu.kandji.io"
        Wildcard          = "*.iot.eu.kandji.io"
        GatewayHost       = "gateway.eu.iru.com"
    }
    US = @{
        Base              = "kandji-prd.s3.amazonaws.com","iru-prd-managed-library-items.s3.amazonaws.com","managed-library.kandji.io","managed-library.iru.com","windows-agent.kandji.io"
        SubdomainSuffixes = "iru.com","gateway.iru.com","id.iru.com","id.connect.iru.com","id.devices.iru.com","id.gateway.iru.com"
        UuidSuffixes      = "web-api.kandji.io","devices.us-1.kandji.io"
        Wildcard          = "*.iot.kandji.io"
        GatewayHost       = "gateway.iru.com"
    }
}

# Telemetry endpoints common to every region.
$script:TelemetryDomains = "browser-intake-datadoghq.com","events.launchdarkly.com","updater.iru.com"

# Endpoints not yet expected to resolve. Failures here surface as INFO so the overall score isn't dragged down.
$script:NotYetActiveDomains = "managed-library.eu.iru.com","managed-library.iru.com"

# HTML report template. Convert-ResultsToHtml does {{token}} substitution.
$script:HtmlTemplate = @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>{{Title}}</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
    font-size: 13px; color: #1a1d2e; background: #f0f2f5; line-height: 1.5; }

  /* ---- Header ---- */
  .hdr { background: {{BrandColor}}; height: 52px; display: flex; align-items: center;
    justify-content: space-between; padding: 0 28px; }
  .hdr-left { display: flex; align-items: center; gap: 10px; }
  .hdr-divider { width: 1px; height: 20px; background: rgba(255,255,255,.2); }
  .hdr-title { color: rgba(255,255,255,.75); font-size: 13px; }
  .hdr-right { color: rgba(255,255,255,.45); font-size: 12px; }

  /* ---- Page ---- */
  .page { max-width: 1080px; margin: 0 auto; padding: 24px 24px 48px; }

  /* ---- Stats strip ---- */
  .stats { display: flex; gap: 10px; margin-bottom: 20px; }
  .stat { background: #fff; border: 1px solid #e4e7ed; border-radius: 10px;
    padding: 12px 18px; flex: 1; }
  .stat-val { font-size: 22px; font-weight: 700; line-height: 1.1; color: {{BrandColor}}; }
  .stat-lbl { font-size: 11px; color: #6b7280; margin-top: 3px; }
  .stat-sub { font-size: 10px; color: #9ca3af; margin-top: 2px; }
  .stat.clickable { cursor: pointer; transition: border-color .15s, box-shadow .15s; user-select: none; }
  .stat.clickable:hover { border-color: #b0b8c8; box-shadow: 0 2px 6px rgba(0,0,0,.07); }
  .stat.active { border-color: {{BrandColor}}; box-shadow: 0 0 0 3px {{BrandColorAlpha}}; }

  /* ---- Filter bar ---- */
  .filter-bar { display: none; align-items: center; justify-content: space-between;
    background: {{BrandColor}}; color: #fff; border-radius: 8px; padding: 8px 16px;
    margin-bottom: 14px; font-size: 12px; }
  .filter-bar.visible { display: flex; }
  .filter-bar-label { opacity: .8; }
  .filter-reset { background: rgba(255,255,255,.15); border: none; color: #fff;
    padding: 4px 12px; border-radius: 6px; font-size: 12px; cursor: pointer;
    font-family: inherit; }
  .filter-reset:hover { background: rgba(255,255,255,.25); }

  /* ---- Callout cards ---- */
  .callouts { display: grid; grid-template-columns: repeat(auto-fit,minmax(300px,1fr));
    gap: 14px; margin-bottom: 20px; }
  .co { background: #fff; border: 1px solid #e4e7ed; border-radius: 10px;
    padding: 16px 16px; display: flex; align-items: flex-start;
    justify-content: space-between; gap: 16px; border-left-width: 4px; border-left-style: solid; }
  .co-body { flex: 1; min-width: 0; }
  .co-lbl { font-size: 10px; font-weight: 600; text-transform: uppercase;
    letter-spacing: .08em; color: #9ca3af; margin-bottom: 5px; }
  .co-val { font-size: 19px; font-weight: 700; color: {{BrandColor}}; margin-bottom: 3px;
    word-break: break-all; }
  .co-meta { font-size: 11px; color: #9ca3af; margin-bottom: 5px; }
  .co-reason { font-size: 12px; font-weight: 500; margin-top: 4px; }
  .co-badge { flex-shrink: 0; align-self: flex-start; margin-top: 2px;
    padding: 3px 10px; border-radius: 999px; font-size: 11px; font-weight: 600; white-space: nowrap; }

  /* ---- Results card ---- */
  .results-card { background: #fff; border: 1px solid #e4e7ed; border-radius: 10px;
    overflow: hidden; }
  .rc-hdr { display: flex; align-items: center; justify-content: space-between;
    padding: 14px 16px 13px; border-bottom: 1px solid #f0f2f5; }
  .rc-title { font-size: 14px; font-weight: 600; color: {{BrandColor}}; }
  .rc-pills { display: flex; gap: 8px; }
  .rcp { font-size: 11px; font-weight: 600; padding: 2px 9px; border-radius: 5px; }

  table { width: 100%; border-collapse: collapse; table-layout: fixed; }
  col.c-check  { width: 28%; }
  col.c-status { width: 10%; }
  col.c-detail { width: 62%; }
  th { text-align: left; background: #f7f8fa; padding: 8px 16px;
    font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase;
    letter-spacing: .05em; border-bottom: 1px solid #e4e7ed; }
  td { padding: 9px 16px; border-bottom: 1px solid #f0f2f5; vertical-align: top;
    font-size: 12px; color: #374151; }
  tr:last-child td { border-bottom: none; }
  tbody tr:not(.sec-row):hover td { background: #fafbfc; }

  .sec-row td { background: #f7f8fa; color: #6b7280; font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: .08em; padding: 6px 16px;
    border-bottom: 1px solid #e4e7ed; border-top: 1px solid #e4e7ed; }
  .sec-row:first-child td { border-top: none; }

  .badge { display: inline-flex; align-items: center; padding: 2px 8px;
    border-radius: 999px; font-size: 11px; font-weight: 600; white-space: nowrap; }

  .dl { display: block; }
  .dl + .dl { margin-top: 2px; color: #6b7280; }

  .footer { text-align: right; padding: 16px 0 0; font-size: 11px; color: #9ca3af; }

  /* ---- Status colours (generated from $script:StatusTheme) ---- */
{{StatusCss}}
</style>
</head>
<body>

<div class="hdr">
  <div class="hdr-left">
    {{HdrLogo}}
    <div class="hdr-divider"></div>
    <span class="hdr-title">Enrollment Compatibility Report</span>
  </div>
  <div class="hdr-right">Generated {{Generated}}</div>
</div>

<div class="page">

  <div class="stats">
    <div class="stat">
      <div class="stat-val">{{Score}}%</div>
      <div class="stat-lbl">Compliance score</div>
    </div>
    <div class="stat">
      <div class="stat-val">{{AvgText}}</div>
      <div class="stat-lbl">Avg TCP/443 latency</div>
      <div class="stat-sub">{{AvgSub}}</div>
    </div>
    <div class="stat">
      <div class="stat-val"><span class="badge {{OverallBadgeCls}}">{{Overall}}</span></div>
      <div class="stat-lbl" style="margin-top:6px;">Overall</div>
    </div>
    <div class="stat clickable" data-filter="pass">
      <div class="stat-val sv-pass">{{Pass}}</div>
      <div class="stat-lbl">Pass &#x25BE;</div>
    </div>
    <div class="stat clickable" data-filter="fail">
      <div class="stat-val sv-fail">{{Fail}}</div>
      <div class="stat-lbl">Fail &#x25BE;</div>
    </div>
    <div class="stat clickable" data-filter="info">
      <div class="stat-val sv-info">{{Info}}</div>
      <div class="stat-lbl">Info &#x25BE;</div>
    </div>
  </div>

  <div class="filter-bar" id="filter-bar">
    <span class="filter-bar-label" id="filter-label">Showing filtered results</span>
    <button class="filter-reset" id="filter-reset">&#x2715; Reset - show all</button>
  </div>

  <div class="callouts">
    <div class="co {{OsCoClass}}">
      <div class="co-body">
        <div class="co-lbl">Detected operating system</div>
        <div class="co-val">{{OsName}}</div>
        <div class="co-meta">{{OsMetaHtml}}</div>
        {{OsReasonHtml}}
      </div>
      <span class="co-badge">{{OsStatusLabel}}</span>
    </div>
    <div class="co {{SnCoClass}}">
      <div class="co-body">
        <div class="co-lbl">Device serial number</div>
        <div class="co-val">{{SnValue}}</div>
        {{SnReasonHtml}}
      </div>
      <span class="co-badge">{{SnStatusLabel}}</span>
    </div>
  </div>

  <div class="results-card">
    <div class="rc-hdr">
      <span class="rc-title">Check results</span>
      <div class="rc-pills">
        <span class="rcp rcp-pass">{{Pass}} pass</span>
        <span class="rcp rcp-fail">{{Fail}} fail</span>
        <span class="rcp rcp-info">{{Info}} info</span>
      </div>
    </div>
    <table>
      <colgroup>
        <col class="c-check" /><col class="c-status" /><col class="c-detail" />
      </colgroup>
      <thead>
        <tr><th>Check</th><th>Status</th><th>Details</th></tr>
      </thead>
      <tbody>
{{Rows}}
      </tbody>
    </table>
  </div>

  <div class="footer">Powered by Iru &nbsp;&bull;&nbsp; {{Title}}</div>

</div>
<script>
var activeFilter = null;
function setFilter(status) {
    activeFilter = (activeFilter === status) ? null : status;
    applyFilter();
}
function resetFilter() { activeFilter = null; applyFilter(); }
function applyFilter() {
    var dataRows = document.querySelectorAll('tr[data-status]');
    var secRows  = document.querySelectorAll('tr.sec-row');
    var statBoxes = document.querySelectorAll('.stat.clickable');
    var bar   = document.getElementById('filter-bar');
    var label = document.getElementById('filter-label');

    dataRows.forEach(function(r) {
        r.style.display = (!activeFilter || r.getAttribute('data-status') === activeFilter) ? '' : 'none';
    });

    secRows.forEach(function(sec) {
        var sib = sec.nextElementSibling;
        var hasVisible = false;
        while (sib && !sib.classList.contains('sec-row')) {
            if (sib.getAttribute('data-status') && sib.style.display !== 'none') { hasVisible = true; break; }
            sib = sib.nextElementSibling;
        }
        sec.style.display = hasVisible ? '' : 'none';
    });

    statBoxes.forEach(function(el) {
        el.classList.toggle('active', el.getAttribute('data-filter') === activeFilter);
    });

    if (activeFilter) {
        var vis = document.querySelectorAll('tr[data-status][data-status="' + activeFilter + '"]').length;
        label.textContent = 'Showing ' + vis + ' ' + activeFilter.toUpperCase() + ' result' + (vis !== 1 ? 's' : '');
        bar.classList.add('visible');
    } else {
        bar.classList.remove('visible');
    }
}
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.stat.clickable').forEach(function(el) {
        el.addEventListener('click', function() { setFilter(el.getAttribute('data-filter')); });
    });
    var resetBtn = document.getElementById('filter-reset');
    if (resetBtn) { resetBtn.addEventListener('click', resetFilter); }
});
</script>
</body>
</html>
'@

# -----------------------------
# Helpers
# -----------------------------
function Get-WindowsInfo {
    $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue

    $buildInt = $null
    if ($cv.CurrentBuildNumber -match '^\d+$') { $buildInt = [int]$cv.CurrentBuildNumber }

    [pscustomobject]@{
        ProductName     = $cv.ProductName
        Caption         = $os.Caption
        DisplayVersion  = $cv.DisplayVersion
        ReleaseId       = $cv.ReleaseId
        EditionId       = $cv.EditionID
        Version         = $os.Version
        BuildNumberInt  = $buildInt
        Build           = if ($cv.CurrentBuildNumber -and $null -ne $cv.UBR) { "$($cv.CurrentBuildNumber).$($cv.UBR)" } else { $cv.CurrentBuildNumber }
    }
}

# Build number is authoritative; ProductName/Caption can still say Windows 10 on Windows 11.
function Get-WindowsBuildName {
    param([int]$Build)
    foreach ($Entry in $script:WindowsBuilds) {
        if ($Build -ge $Entry.MinBuild) { return $Entry.Name }
    }
    "Windows (Build $Build)"
}

function Get-EdgeInfo {
    $edgeExe = $null
    $appPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe"
    )

    foreach ($p in $appPaths) {
        if (Test-Path $p) {
            try {
                $props = Get-ItemProperty -Path $p -ErrorAction Stop
                $candidate = $props.'(default)'
                if (-not $candidate) { $candidate = $props.Path }
                if ($candidate -and (Test-Path $candidate)) { $edgeExe = $candidate; break }
            } catch {}
        }
    }

    if (-not $edgeExe) {
        $paths = @(
            "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
            "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
            "$env:LocalAppData\Microsoft\Edge\Application\msedge.exe"
        )
        $edgeExe = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    $appx = $null
    if (-not $edgeExe) {
        try {
            $appx = Get-AppxPackage -Name "Microsoft.MicrosoftEdge.Stable" -ErrorAction SilentlyContinue
            if (-not $appx) { $appx = Get-AppxPackage -Name "Microsoft.MicrosoftEdge" -ErrorAction SilentlyContinue }
        } catch {}
    }

    if ($edgeExe) {
        $ver = $null
        try { $ver = (Get-Item $edgeExe).VersionInfo.ProductVersion } catch {}
        [pscustomobject]@{ Installed=$true; Method="Executable"; Path=$edgeExe; Version=$ver }
        return
    }

    if ($appx) {
        [pscustomobject]@{ Installed=$true; Method="AppX Package"; Path=$appx.InstallLocation; Version=$appx.Version.ToString() }
        return
    }

    [pscustomobject]@{ Installed=$false; Method="NotFound"; Path=$null; Version=$null }
}

function Get-SerialInfo {
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $sn   = if ($bios -and $bios.SerialNumber) { $bios.SerialNumber.Trim() } else { $null }

    $bad = @("", "0", "0000000000000000", "To be filled by O.E.M.", "To be filled by OEM",
             "Default string", "System Serial Number", "Serial Number")

    $ok = $true
    if (-not $sn) { $ok = $false }
    elseif ($bad -contains $sn) { $ok = $false }
    elseif ($sn -match "^(0+|N/A)$") { $ok = $false }

    [pscustomobject]@{ Present=$ok; SerialNumber=$sn }
}

# -----------------------------
# Current user + admin check
# -----------------------------
function Get-LoggedOnUser {
    try {
        $Id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        if ($Id -and $Id.Name) { return $Id.Name }
    } catch {}

    $U = $env:USERNAME
    $D = $env:USERDOMAIN
    if ($D -and $U) { return "$D\$U" }
    $U
}

function Test-CurrentUserIsAdmin {
    # Check group membership, not token elevation: an admin running unelevated should still pass.
    try {
        $Id  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Sid = $Id.User.Value
        $IsAdmin = [bool](Get-LocalGroupMember -Group Administrators -ErrorAction Stop |
            Where-Object { $_.SID.Value -eq $Sid })

        [pscustomobject]@{
            User    = $Id.Name
            IsAdmin = $IsAdmin
            Detail  = if ($IsAdmin) { "User is a local administrator." } else { "User is NOT a local administrator." }
        }
    } catch {
        [pscustomobject]@{
            User    = (Get-LoggedOnUser)
            IsAdmin = $false
            Detail  = "Could not determine admin status reliably: $($_.Exception.Message)"
        }
    }
}

# -----------------------------
# MDM enrollment detection (ENROLLED => FAIL)
# -----------------------------
function Get-MdmEnrollmentInfo {
    $enrollmentsPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"
    $omadmPath       = "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts"

    $found = New-Object System.Collections.Generic.List[object]

    if (Test-Path $enrollmentsPath) {
        foreach ($k in (Get-ChildItem $enrollmentsPath -ErrorAction SilentlyContinue)) {
            try {
                $p = Get-ItemProperty $k.PSPath -ErrorAction Stop

                $hasUrl =
                    ($p.PSObject.Properties.Name -contains "MDMEnrollmentURL" -and $p.MDMEnrollmentURL) -or
                    ($p.PSObject.Properties.Name -contains "DiscoveryServiceFullURL" -and $p.DiscoveryServiceFullURL)

                # Require a non-empty ProviderID to indicate a real MDM provider.
                # Exclude known Windows internal authority entries - these are present on
                # most modern Windows 11 devices and are not actual MDM enrollments.
                # EnrollmentType 28/30/31 = Local/Deploy/Cloud Authority (Windows internal).
                $windowsInternalProviders = @(
                    "Local Authority",
                    "Cloud Authority",
                    "Deploy Authority",
                    "SC Authority",
                    "MS Work Account"
                )
                $windowsInternalTypes = @(28, 29, 30, 31, 32)

                $hasProvider = (
                    ($p.PSObject.Properties.Name -contains "ProviderID" -and $p.ProviderID) -and
                    ($windowsInternalProviders -notcontains $p.ProviderID) -and
                    (
                        -not ($p.PSObject.Properties.Name -contains "EnrollmentType") -or
                        ($windowsInternalTypes -notcontains $p.EnrollmentType)
                    )
                )

                if ($hasUrl -or $hasProvider) {
                    [void]$found.Add([pscustomobject]@{
                        KeyName                 = $k.PSChildName
                        ProviderID              = $p.ProviderID
                        EnrollmentType          = $p.EnrollmentType
                        EnrollmentState         = $p.EnrollmentState
                        MDMEnrollmentURL        = $p.MDMEnrollmentURL
                        DiscoveryServiceFullURL = $p.DiscoveryServiceFullURL
                    })
                }
            } catch {}
        }
    }

    $omadmAccounts = @()
    if (Test-Path $omadmPath) {
        try { $omadmAccounts = (Get-ChildItem $omadmPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName) } catch {}
    }

    $enrolled = ($found.Count -gt 0) -or ($omadmAccounts.Count -gt 0)

    $detailsParts = New-Object System.Collections.Generic.List[string]

    if ($found.Count -gt 0) {
        [void]$detailsParts.Add("Enrollments keys: $($found.Count)")
        $top = $found | Select-Object -First 3
        foreach ($x in $top) {
            $provider = if ($x.ProviderID) { $x.ProviderID } else { "-" }
            $etype    = if ($null -ne $x.EnrollmentType)  { $x.EnrollmentType }  else { "-" }
            $state    = if ($null -ne $x.EnrollmentState) { $x.EnrollmentState } else { "-" }
            $url      = if ($x.MDMEnrollmentURL) { $x.MDMEnrollmentURL } elseif ($x.DiscoveryServiceFullURL) { $x.DiscoveryServiceFullURL } else { "-" }

            [void]$detailsParts.Add("Key=$($x.KeyName); ProviderID=$provider; Type=$etype; State=$state; URL=$url")
        }
        if ($found.Count -gt 3) { [void]$detailsParts.Add("...and $($found.Count - 3) more enrollment key(s)") }
    } else {
        [void]$detailsParts.Add("No MDM enrollment keys found under $enrollmentsPath")
    }

    if ($omadmAccounts.Count -gt 0) {
        [void]$detailsParts.Add("OMADM accounts: $($omadmAccounts.Count) (e.g. $($omadmAccounts | Select-Object -First 1))")
    } else {
        [void]$detailsParts.Add("No OMADM accounts found under $omadmPath")
    }

    [pscustomobject]@{
        Enrolled       = [bool]$enrolled
        Details        = ($detailsParts -join " | ")
        RawEnrollments = $found
        OmadmAccounts  = $omadmAccounts
    }
}

function Test-TcpLatency443 {
    param(
        [Parameter(Mandatory=$true)][string]$TargetHost,
        [int]$TimeoutMs = 2500,
        [int]$PassMaxMs = 300,
        [int]$InfoMaxMs = 700
    )

    $DnsMs = $null
    try {
        $SwDns = [System.Diagnostics.Stopwatch]::StartNew()
        [void][System.Net.Dns]::GetHostAddresses($TargetHost)
        $SwDns.Stop()
        $DnsMs = [int]$SwDns.ElapsedMilliseconds
    } catch {
        [pscustomobject]@{
            Host   = $TargetHost
            Status = "FAIL"
            TcpMs  = $null
            DnsMs  = $null
            Detail = "DNS resolution failed: $($_.Exception.Message)"
        }
        return
    }

    $Client = $null
    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $Sw = [System.Diagnostics.Stopwatch]::StartNew()
        $Task = $Client.ConnectAsync($TargetHost, 443)

        if (-not $Task.Wait($TimeoutMs)) {
            try { $Client.Close() } catch {}
            [pscustomobject]@{
                Host   = $TargetHost
                Status = "FAIL"
                TcpMs  = $null
                DnsMs  = $DnsMs
                Detail = "TCP connect timed out (> ${TimeoutMs}ms). DNS=${DnsMs}ms"
            }
            return
        }

        $Sw.Stop()
        $TcpMs = [int]$Sw.ElapsedMilliseconds
        try { $Client.Close() } catch {}

        $Status =
            if ($TcpMs -le $PassMaxMs) { "PASS" }
            elseif ($TcpMs -le $InfoMaxMs) { "INFO" }
            else { "FAIL" }

        [pscustomobject]@{
            Host   = $TargetHost
            Status = $Status
            TcpMs  = $TcpMs
            DnsMs  = $DnsMs
            Detail = "TCP/443 connect=${TcpMs}ms; DNS=${DnsMs}ms"
        }
    } catch {
        try { if ($Client) { $Client.Close() } } catch {}
        [pscustomobject]@{
            Host   = $TargetHost
            Status = "FAIL"
            TcpMs  = $null
            DnsMs  = $DnsMs
            Detail = "TCP connect error: $($_.Exception.Message); DNS=${DnsMs}ms"
        }
    }
}

# Downloads $Url to $Path if the file is missing. Silent on failure -- callers must tolerate the file still being absent.
function Get-RequiredAsset {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Url,
        [int]$TimeoutSec = 15
    )

    if (Test-Path -LiteralPath $Path) { return }

    try {
        Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing `
            -TimeoutSec $TimeoutSec -ErrorAction Stop
    } catch {
        # Don't leave a half-written file behind.
        if (Test-Path -LiteralPath $Path) {
            try { Remove-Item -LiteralPath $Path -Force -ErrorAction Stop } catch {}
        }
    }
}

# Returns PASS on HTTP 200 from the regional gateway's ping endpoint, FAIL otherwise.
function Test-TenantSubdomain {
    param(
        [Parameter(Mandatory=$true)][string]$Subdomain,
        [Parameter(Mandatory=$true)][string]$GatewayHost,
        [int]$TimeoutSec = 8
    )

    $Url = "https://$Subdomain.$GatewayHost/main-backend/app/v1/ping"
    $Status = "FAIL"
    $Detail = $null

    try {
        $Resp = Invoke-WebRequest -Uri $Url -UseBasicParsing `
            -TimeoutSec $TimeoutSec -ErrorAction Stop
        $Code = [int]$Resp.StatusCode
        if ($Code -eq 200) {
            $Status = "PASS"
            $Detail = "Tenant subdomain '$Subdomain' confirmed (HTTP 200 from $Url)."
        } else {
            $Detail = "Unexpected HTTP $Code from $Url - tenant subdomain '$Subdomain' may not exist."
        }
    } catch [System.Net.WebException] {
        $We = $_.Exception
        $Code = $null
        if ($We.Response) { try { $Code = [int]$We.Response.StatusCode } catch {} }
        $CodeText = if ($Code) { "HTTP $Code" } else { $We.Status.ToString() }
        $Detail = "Tenant subdomain '$Subdomain' not found ($CodeText from $Url): $($We.Message)"
    } catch {
        $Detail = "Unable to validate tenant subdomain '$Subdomain' via $Url - $($_.Exception.Message)"
    }

    [pscustomobject]@{ Status = $Status; Url = $Url; Detail = $Detail }
}

function Test-PendingReboot {
    $sources = New-Object System.Collections.Generic.List[string]

    # Windows Update requested a reboot
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        [void]$sources.Add("Windows Update")
    }

    # Component Based Servicing (e.g. .NET, language packs)
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
        [void]$sources.Add("Component Based Servicing")
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress") {
        [void]$sources.Add("CBS Reboot In Progress")
    }

    # Pending file rename operations (installers commonly set this)
    try {
        $pfro = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                    -Name PendingFileRenameOperations -ErrorAction Stop
        if ($pfro.PendingFileRenameOperations) {
            [void]$sources.Add("Pending File Rename Operations")
        }
    } catch {}

    # SCCM / ConfigMgr client reboot pending
    try {
        $ccm = [WmiClass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $ccm.DetermineIfRebootPending()
        if ($status -and ($status.RebootPending -or $status.IsHardRebootPending)) {
            [void]$sources.Add("SCCM Client")
        }
    } catch {}

    $pending = $sources.Count -gt 0

    [pscustomobject]@{
        Pending = $pending
        Sources = $sources
        Detail  = if ($pending) {
            "Reboot pending: $($sources -join ', '). Reboot before enrolling."
        } else {
            "No pending reboot detected."
        }
    }
}

function Get-ExperienceEnrollmentPolicy {
    $Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Experience"
    $ValueName = "AllowManualMDMUnenrollment"

    if (-not (Test-Path $Path)) {
        [pscustomobject]@{ Status="PASS"; Details="Key not present ($Path) - treated as OK" }
        return
    }

    try {
        $RegItem = Get-ItemProperty -Path $Path -ErrorAction Stop
        $Prop = $RegItem.PSObject.Properties[$ValueName]
        if ($null -eq $Prop) {
            [pscustomobject]@{ Status="PASS"; Details="Value not present ($Path\$ValueName) - treated as OK" }
            return
        }

        $V = $RegItem.$ValueName
        $Status = if ($V -eq 1) { "PASS" } elseif ($V -eq 0) { "FAIL" } else { "INFO" }
        $Details = switch ($Status) {
            "PASS" { "$Path\$ValueName = 1 (OK)" }
            "FAIL" { "$Path\$ValueName = 0 (BLOCKS enrollment/unenrollment)" }
            default { "$Path\$ValueName = $V (unexpected; expected 0 or 1)" }
        }
        [pscustomobject]@{ Status = $Status; Details = $Details }
    } catch {
        [pscustomobject]@{ Status="INFO"; Details="Error reading $Path\$ValueName : $($_.Exception.Message)" }
    }
}

function Get-RegionDomains {
    param([Parameter(Mandatory=$true)][ValidateSet("EU","US")]$Region,[string]$Subdomain,[string]$UUID)

    $Map = $script:RegionMap[$Region]
    $Domains = New-Object System.Collections.Generic.List[string]

    foreach ($D in $script:TelemetryDomains) { [void]$Domains.Add($D) }
    foreach ($D in $Map.Base)                { [void]$Domains.Add($D) }

    if ($Subdomain) {
        foreach ($Suffix in $Map.SubdomainSuffixes) { [void]$Domains.Add("$Subdomain.$Suffix") }
    }
    if ($UUID) {
        foreach ($Suffix in $Map.UuidSuffixes) { [void]$Domains.Add("$UUID.$Suffix") }
    }

    $Domains | Select-Object -Unique
}

# -----------------------------
# Results Store + UI helpers
# -----------------------------
$script:Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Section,[string]$Check,
        [ValidateSet("PASS","FAIL","INFO")]$Status,
        [string]$Details,
        # Optional structured payload for HTML callouts to read without re-parsing $Details.
        [hashtable]$Data
    )
    [void]$script:Results.Add([pscustomobject]@{
        Timestamp = (Get-Date)
        Section   = $Section
        Check     = $Check
        Status    = $Status
        Details   = $Details
        Data      = $Data
    })
}

function Get-StatusColor {
    param([string]$Status)
    $Key = if ($script:StatusTheme.ContainsKey($Status)) { $Status } else { "INFO" }
    @{ Back = $script:StatusTheme[$Key].Back; Fore = $script:StatusTheme[$Key].Fore }
}

function Add-GridRow {
    param(
        [System.Windows.Forms.DataGridView]$Grid,
        [string]$Section,[string]$Check,[string]$Status,[string]$Details
    )
    $Idx = $Grid.Rows.Add()
    $Row = $Grid.Rows[$Idx]
    $Row.Cells[0].Value = $Section
    $Row.Cells[1].Value = $Check
    $Row.Cells[2].Value = $Status
    $Row.Cells[3].Value = $Details
}

# Adds a result and projects it into the visible grid. Pass -Data to attach structured fields for HTML callouts.
function Add-CheckResult {
    param(
        [string]$Section,
        [string]$Check,
        [ValidateSet("PASS","FAIL","INFO")][string]$Status,
        [string]$Details,
        [hashtable]$Data
    )
    Add-Result -Section $Section -Check $Check -Status $Status -Details $Details -Data $Data
    Add-GridRow -Grid $script:Grid -Section $Section -Check $Check -Status $Status -Details $Details
}

# Standard separator/border colour used everywhere a panel needs a 1px outline.
$script:BorderColor = [System.Drawing.Color]::FromArgb(218, 220, 224)

# Draws a 1px border on a panel. -Rectangle paints all four sides; default is bottom-only.
function Add-PanelBorder {
    param([System.Windows.Forms.Control]$Panel, [switch]$Rectangle)
    if ($Rectangle) {
        $Panel.Add_Paint({ param($S, $E)
            $Pen = New-Object System.Drawing.Pen($script:BorderColor)
            $E.Graphics.DrawRectangle($Pen, 0, 0, ([int]$S.Width - 1), ([int]$S.Height - 1))
            $Pen.Dispose()
        })
    } else {
        $Panel.Add_Paint({ param($S, $E)
            $Pen = New-Object System.Drawing.Pen($script:BorderColor)
            $E.Graphics.DrawLine($Pen, 0, ([int]$S.Height - 1), [int]$S.Width, ([int]$S.Height - 1))
            $Pen.Dispose()
        })
    }
}

# -Primary fills with accent; secondary is white with an accent outline. -OutlineColor overrides (e.g. Cancel uses red).
function New-FlatButton {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [switch]$Primary,
        [System.Drawing.Color]$OutlineColor = $AccentColor
    )
    $White = [System.Drawing.Color]::White
    $B = New-Object System.Windows.Forms.Button -Property @{
        Text = $Text; FlatStyle = "Flat"; Width = 150
        Height = if ($Primary) { 42 } else { 32 }
        Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
        BackColor = if ($Primary) { $AccentColor } else { $White }
        ForeColor = if ($Primary) { $White } else { $OutlineColor }
    }
    $B.FlatAppearance.BorderSize  = if ($Primary) { 0 } else { 1 }
    $B.FlatAppearance.BorderColor = $OutlineColor
    if ($Primary) {
        $B.Add_MouseEnter({ $this.BackColor = $script:AccentDarkColor })
        $B.Add_MouseLeave({ $this.BackColor = $AccentColor })
    } else {
        # GetNewClosure captures $OutlineColor per-button so each hover uses its own colour.
        $B.Add_MouseEnter({ if ($this.Enabled) { $this.BackColor = $OutlineColor; $this.ForeColor = [System.Drawing.Color]::White } }.GetNewClosure())
        $B.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::White; $this.ForeColor = $OutlineColor }.GetNewClosure())
    }
    $B
}

# Toggles primary button between filled (enabled) and grey outline (disabled).
function Set-AccentButtonEnabled {
    param([System.Windows.Forms.Button]$Button, [bool]$Enabled)
    $Button.Enabled = $Enabled
    $Button.BackColor = if ($Enabled) { $AccentColor } else { [System.Drawing.Color]::White }
    $Button.ForeColor = if ($Enabled) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(160, 160, 160) }
    $Button.FlatAppearance.BorderColor = if ($Enabled) { $AccentColor } else { [System.Drawing.Color]::FromArgb(200, 200, 200) }
    $Button.FlatAppearance.BorderSize = if ($Enabled) { 0 } else { 1 }
}

function Get-ComplianceSummary {
    $pass = ($script:Results | Where-Object Status -eq "PASS").Count
    $fail = ($script:Results | Where-Object Status -eq "FAIL").Count
    $info = ($script:Results | Where-Object Status -eq "INFO").Count
    $scoredTotal = $pass + $fail
    $score = if ($scoredTotal -gt 0) { [math]::Round(($pass / $scoredTotal) * 100, 0) } else { 0 }
    $overall = if ($fail -gt 0) { "FAIL" } elseif ($pass -gt 0) { "PASS" } else { "INFO" }
    [pscustomobject]@{ Pass=$pass; Fail=$fail; Info=$info; Score=$score; Overall=$overall }
}

function Get-AverageRtt {
    $Vals = @(
        $script:Results |
        Where-Object { $_.Check -like "Latency (TCP/443) to *" -and $_.Details -match "TCP/443 connect=(\d+)ms" } |
        ForEach-Object { [int]([regex]::Match($_.Details, "TCP/443 connect=(\d+)ms").Groups[1].Value) }
    )

    if (-not $Vals -or $Vals.Count -eq 0) {
        [pscustomobject]@{ HasData=$false; AvgMs=$null; Samples=0 }
        return
    }

    $Avg = [int][math]::Round(($Vals | Measure-Object -Average).Average, 0)
    [pscustomobject]@{ HasData=$true; AvgMs=$Avg; Samples=$Vals.Count }
}

# -----------------------------
# HTML Export
# -----------------------------
function Get-LogoDataUri {
    param([Parameter(Mandatory=$true)][string]$LogoPath)
    if (-not (Test-Path $LogoPath)) { return $null }
    try {
        $Bytes = [System.IO.File]::ReadAllBytes($LogoPath)
        $B64   = [System.Convert]::ToBase64String($Bytes)
        "data:image/png;base64,$B64"
    } catch { $null }
}

function Convert-ResultsToHtml {
    param(
        [Parameter(Mandatory=$true)][object]$Summary,
        [Parameter(Mandatory=$true)][string]$Title
    )

    Add-Type -AssemblyName System.Web
    $esc = {
        param($s)
        if ($null -eq $s) { return "" }
        [System.Web.HttpUtility]::HtmlEncode([string]$s)
    }

    # ---- Logo ----
    $logoUri = Get-LogoDataUri -LogoPath (Join-Path -Path $PSScriptRoot -ChildPath $LogoFileName)
    $hdrLogoHtml = if ($logoUri) {
        "<img src='$logoUri' alt='Iru' style='height:26px;width:auto;display:block;' />"
    } else {
        "<span style='font-weight:700;font-size:15px;color:#fff;letter-spacing:.5px;'>iru</span>"
    }

    # ---- Latency stat ----
    $avg = Get-AverageRtt
    $avgText = if ($avg.HasData) { "$($avg.AvgMs) ms" } else { "-" }
    $avgSub  = if ($avg.HasData) { "$($avg.Samples) samples" } else { "no samples" }

    # ---- OS callout ---- (reads structured fields from .Data, no regex on .Details)
    $osDetectedRow = $script:Results | Where-Object { $_.Check -eq "Detected OS" }  | Select-Object -First 1
    $osVersionRow  = $script:Results | Where-Object { $_.Check -like "OS version*" } | Select-Object -First 1
    $osData        = if ($osDetectedRow) { $osDetectedRow.Data } else { @{} }
    $osStatus      = if ($osVersionRow) { $osVersionRow.Status } else { "INFO" }
    $osReason      = if ($osVersionRow -and $osVersionRow.Data -and $osVersionRow.Data.Reason) { & $esc $osVersionRow.Data.Reason } else { "" }
    $osMetaParts   = @()
    if ($osData.Build)          { $osMetaParts += "Build $($osData.Build)" }
    if ($osData.DisplayVersion) { $osMetaParts += "Version $($osData.DisplayVersion)" }
    if ($osData.Edition)        { $osMetaParts += "$($osData.Edition) edition" }

    # ---- Serial number callout ----
    $snRow      = $script:Results | Where-Object { $_.Check -eq "Serial number present" } | Select-Object -First 1
    $snData     = if ($snRow) { $snRow.Data } else { @{} }
    $snStatus   = if ($snRow) { $snRow.Status } else { "INFO" }
    $snReason   = if ($snData.Reason) { & $esc $snData.Reason } else { "" }

    # ---- Table rows ----
    $rows = & {
        $prevSection = $null
        foreach ($r in $script:Results) {
            if ($r.Section -ne $prevSection) {
                "        <tr class='sec-row'><td colspan='3'>$(& $esc $r.Section)</td></tr>"
                $prevSection = $r.Section
            }
            $badgeCls   = $script:StatusTheme[$r.Status].HtmlBadgeClass
            $statusAttr = $r.Status.ToLower()
            $detailHtml = ($r.Details -split ' \| ' | Where-Object { $_ } |
                ForEach-Object { "<span class='dl'>$(& $esc $_)</span>" }) -join ""
            "        <tr data-status='$statusAttr'><td>$(& $esc $r.Check)</td><td><span class='badge $badgeCls'>$(& $esc $r.Status)</span></td><td>$detailHtml</td></tr>"
        }
    }

    # ---- Per-status CSS generated from $script:StatusTheme.
    $statusCss = ($script:StatusTheme.GetEnumerator() | ForEach-Object {
        $K = $_.Key.ToLower(); $T = $_.Value
        "  .badge-$K, .rcp-$K, .co-$K .co-badge { background: $($T.WebBg); color: $($T.WebText); }`n" +
        "  .co-$K { border-left-color: $($T.WebAccent); }`n" +
        "  .co-$K .co-reason, .sv-$K { color: $($T.WebText); }"
    }) -join "`n"

    # ---- Brand colour derived from $AccentColor. {{BrandColorAlpha}} is the same RGB at .12 alpha.
    $brandHex   = "#{0:x2}{1:x2}{2:x2}" -f $AccentColor.R, $AccentColor.G, $AccentColor.B
    $brandAlpha = "rgba({0},{1},{2},.12)" -f $AccentColor.R, $AccentColor.G, $AccentColor.B

    # ---- Token substitution -----------------------------------------------------
    # PowerShell's (if/else) form doesn't reliably evaluate inside a hashtable literal; resolve fallbacks first.
    $osNameValue = if ($osData.Name)   { $osData.Name }   else { "Unknown" }
    $snValueText = if ($snData.Serial) { $snData.Serial } else { "(none detected)" }
    $osMetaHtml  = ($osMetaParts | ForEach-Object { & $esc $_ }) -join " &middot; "

    $tokens = [ordered]@{
        Title            = & $esc $Title
        HdrLogo          = $hdrLogoHtml
        Generated        = & $esc (Get-Date -Format 'dd MMM yyyy HH:mm')
        Score            = $Summary.Score
        AvgText          = & $esc $avgText
        AvgSub           = & $esc $avgSub
        Overall          = & $esc $Summary.Overall
        OverallBadgeCls  = $script:StatusTheme[$Summary.Overall].HtmlBadgeClass
        Pass             = $Summary.Pass
        Fail             = $Summary.Fail
        Info             = $Summary.Info
        OsCoClass        = $script:StatusTheme[$osStatus].HtmlCalloutClass
        OsName           = & $esc $osNameValue
        OsMetaHtml       = $osMetaHtml
        OsReasonHtml     = if ($osReason) { "<p class='co-reason'>$osReason</p>" } else { "" }
        OsStatusLabel    = & $esc $script:StatusTheme[$osStatus].OsLabel
        SnCoClass        = $script:StatusTheme[$snStatus].HtmlCalloutClass
        SnValue          = & $esc $snValueText
        SnReasonHtml     = if ($snReason) { "<p class='co-reason'>$snReason</p>" } else { "" }
        SnStatusLabel    = & $esc $script:StatusTheme[$snStatus].SnLabel
        Rows             = $rows -join "`n"
        StatusCss        = $statusCss
        BrandColor       = $brandHex
        BrandColorAlpha  = $brandAlpha
    }

    $html = $script:HtmlTemplate
    foreach ($t in $tokens.GetEnumerator()) {
        $html = $html.Replace("{{$($t.Key)}}", [string]$t.Value)
    }
    $html
}


# -----------------------------
# UI
# -----------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "$BrandName $ToolName"
$form.Size = New-Object System.Drawing.Size(1200, 860)
$form.StartPosition = "CenterScreen"
$form.AutoScaleMode = "Dpi"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.MinimumSize = New-Object System.Drawing.Size(1000, 760)
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.BackColor   = [System.Drawing.Color]::FromArgb(240, 242, 245)

# Ensure colocated branding assets exist; download from GitHub if missing.
Get-RequiredAsset -Path (Join-Path -Path $PSScriptRoot -ChildPath $IconFileName) -Url $IconUrl
Get-RequiredAsset -Path (Join-Path -Path $PSScriptRoot -ChildPath $LogoFileName) -Url $LogoUrl

# Icon (optional)
$iconPath = Join-Path -Path $PSScriptRoot -ChildPath $IconFileName
if (Test-Path $iconPath) { try { $form.Icon = New-Object System.Drawing.Icon($iconPath) } catch {} }

# Header
$header = New-Object System.Windows.Forms.Panel
$header.Dock = "Top"
$header.Height = 92
$header.BackColor = $HeaderBgColor

$logoPath = Join-Path -Path $PSScriptRoot -ChildPath $LogoFileName
$picLogo = New-Object System.Windows.Forms.PictureBox
$picLogo.SizeMode = "Zoom"
$picLogo.Size = New-Object System.Drawing.Size(260, 64)
$picLogo.Visible = $false
$picLogo.Location = New-Object System.Drawing.Point(0, 14)
if (Test-Path $logoPath) { try { $picLogo.Image = [System.Drawing.Image]::FromFile($logoPath); $picLogo.Visible = $true } catch {} }

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = $ToolName
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
$lblTitle.AutoSize = $false
$lblTitle.AutoEllipsis = $true
$lblTitle.Location = New-Object System.Drawing.Point(14, 18)
$lblTitle.Height = 28

$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = "Verify Windows, MDM, and network readiness for Iru enrollment (US or EU) - $ToolVersion"
$lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSubTitle.AutoSize = $false
$lblSubTitle.AutoEllipsis = $true
$lblSubTitle.Location = New-Object System.Drawing.Point(14, 50)
$lblSubTitle.Height = 18

$accentLine = New-Object System.Windows.Forms.Panel
$accentLine.Dock = "Bottom"
$accentLine.Height = 3
$accentLine.BackColor = $AccentColor

$header.Controls.AddRange(@($picLogo, $lblTitle, $lblSubTitle, $accentLine))

function Set-HeaderLayout {
    $rightPadding = 14
    $leftPadding  = 14
    $gap          = 12
    $logoLeft = $header.ClientSize.Width - $rightPadding

    if ($picLogo.Visible) {
        $xLogo = [int]($header.ClientSize.Width - $picLogo.Width - $rightPadding)
        if ($xLogo -lt $leftPadding) { $xLogo = $leftPadding }
        $picLogo.Location = New-Object System.Drawing.Point($xLogo, 14)
        $logoLeft = $xLogo
    }

    $maxTextRight = $logoLeft - $gap
    if ($maxTextRight -lt ($leftPadding + 50)) { $maxTextRight = $leftPadding + 50 }
    $maxWidth = [int]($maxTextRight - $leftPadding)

    $lblTitle.Width = $maxWidth
    $lblSubTitle.Width = $maxWidth
}
$header.Add_Resize({ Set-HeaderLayout })

# Summary strip
$summaryPanel = New-Object System.Windows.Forms.Panel
$summaryPanel.Dock = "Top"
$summaryPanel.Height = 52
$summaryPanel.Padding = New-Object System.Windows.Forms.Padding(14, 0, 14, 0)
$summaryPanel.BackColor = [System.Drawing.Color]::White
Add-PanelBorder $summaryPanel

$lblOverall = New-Object System.Windows.Forms.Label
$lblOverall.AutoSize = $true
$lblOverall.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
$lblOverall.Text = "Overall: -"

$lblScore = New-Object System.Windows.Forms.Label
$lblScore.AutoSize = $true
$lblScore.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
$lblScore.Text = "Score: -"

$lblAvgRtt = New-Object System.Windows.Forms.Label
$lblAvgRtt.AutoSize = $true
$lblAvgRtt.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
$lblAvgRtt.Text = "Avg TCP/443 latency: -"

$lblCounts = New-Object System.Windows.Forms.Label
$lblCounts.AutoSize = $true
$lblCounts.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblCounts.Text = "PASS: 0  |  FAIL: 0  |  INFO: 0"
$lblCounts.ForeColor = [System.Drawing.Color]::FromArgb(100, 105, 115)

$summaryLayout = New-Object System.Windows.Forms.TableLayoutPanel
$summaryLayout.Dock = "Fill"
$summaryLayout.ColumnCount = 4
$summaryLayout.RowCount = 1
[void]$summaryLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 28)))
[void]$summaryLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 18)))
[void]$summaryLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30)))
[void]$summaryLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 24)))

$summaryLayout.Controls.Add($lblOverall, 0, 0)
$summaryLayout.Controls.Add($lblScore,   1, 0)
$summaryLayout.Controls.Add($lblAvgRtt,  2, 0)
$summaryLayout.Controls.Add($lblCounts,  3, 0)

$summaryPanel.Controls.Add($summaryLayout)

function Update-SummaryUI {
    $s = Get-ComplianceSummary
    $lblOverall.Text = "Overall: $($s.Overall)"
    $lblScore.Text   = "Score: $($s.Score)%"
    $lblCounts.Text  = "PASS: $($s.Pass) | FAIL: $($s.Fail) | INFO: $($s.Info)"

    $avg = Get-AverageRtt
    if ($avg.HasData) {
        $lblAvgRtt.Text = "Avg TCP/443 latency: $($avg.AvgMs) ms ($($avg.Samples))"
    } else {
        $lblAvgRtt.Text = "Avg TCP/443 latency: - (no samples)"
    }

    $c = Get-StatusColor $s.Overall
    $lblOverall.ForeColor = $c.Fore
}

# -----------------------------
# Inputs group
# -----------------------------
$lblRegion = New-Object System.Windows.Forms.Label
$lblRegion.Text = "Region"
$lblRegion.AutoSize = $true

$cmbRegion = New-Object System.Windows.Forms.ComboBox
$cmbRegion.DropDownStyle = "DropDownList"
$cmbRegion.Items.AddRange(@("EU", "US"))
$cmbRegion.SelectedIndex = 0

$lblSubdomain = New-Object System.Windows.Forms.Label
$lblSubdomain.Text = "Tenant Subdomain"
$lblSubdomain.AutoSize = $true

$txtSubdomain = New-Object System.Windows.Forms.TextBox

$lblSubdomainHint = New-Object System.Windows.Forms.Label
$lblSubdomainHint.Text      = "  Enter a Tenant Subdomain to enable Run Checks"
$lblSubdomainHint.AutoSize  = $false
$lblSubdomainHint.Dock      = "Fill"
$lblSubdomainHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblSubdomainHint.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblSubdomainHint.ForeColor = [System.Drawing.Color]::FromArgb(180, 100, 0)   # amber

$lblUUID = New-Object System.Windows.Forms.Label
$lblUUID.Text = "Tenant UUID"
$lblUUID.AutoSize = $true

$txtUUID = New-Object System.Windows.Forms.TextBox

$lblDeviceDomain = New-Object System.Windows.Forms.Label
$lblDeviceDomain.Text = "Device Domain override"
$lblDeviceDomain.AutoSize = $true

$txtDeviceDomain = New-Object System.Windows.Forms.TextBox

# Primary accent-filled action button - disabled until a valid subdomain is entered.
$btnRun = New-FlatButton -Text "Run Checks" -Primary
$btnRun.Enabled = $false

# Cancel button - red outline, hidden until a run is in progress.
$DangerColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
$btnCancel = New-FlatButton -Text "Cancel" -OutlineColor $DangerColor
$btnCancel.Enabled = $false
$btnCancel.Visible = $false
$btnCancel.Add_Click({
    $script:CancelRequested = $true
    $btnCancel.Enabled = $false
    $lblStatus.Text = "Cancelling..."
})

$btnDocs = New-FlatButton -Text "Open Docs"
$btnDocs.Add_Click({ try { Start-Process $DocsNetworkUrl } catch {} })

# Enrollment button (Edge only).
$btnEnroll = New-FlatButton -Text "Open Enrollment"
$btnEnroll.Enabled = $false

$btnEnroll.Add_Click({
    $sub = $txtSubdomain.Text.Trim()

    if (-not $sub) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter the Tenant Subdomain first.",
            "Missing Tenant Subdomain",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    if ($sub -notmatch $script:SubdomainRegex) {
        [System.Windows.Forms.MessageBox]::Show(
            "Tenant Subdomain looks invalid. Use only letters, numbers, and hyphens (no spaces).",
            "Invalid Tenant Subdomain",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $url = "https://$sub.iru.com/enroll"

    $edge = Get-EdgeInfo
    if (-not $edge.Installed) {
        [System.Windows.Forms.MessageBox]::Show(
            "Microsoft Edge is required to open enrollment. Edge was not detected on this device.",
            "Edge Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    try {
        if ($edge.Method -eq "Executable" -and $edge.Path -and (Test-Path $edge.Path)) {
            Start-Process -FilePath $edge.Path -ArgumentList @($url)
        } else {
            Start-Process ("microsoft-edge:{0}" -f $url)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to open enrollment in Microsoft Edge.`n$($_.Exception.Message)",
            "Launch Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$btnExportHtml = New-FlatButton -Text "Export HTML"
$btnExportHtml.Enabled = $false

$btnClear = New-FlatButton -Text "Clear"

function Update-ButtonStates {
    $Sub = $txtSubdomain.Text.Trim()
    $IsValid = [bool]($Sub -match $script:SubdomainRegex)
    Set-AccentButtonEnabled -Button $btnRun -Enabled $IsValid
    $btnEnroll.Enabled = $IsValid
    $lblSubdomainHint.Visible = -not $IsValid
}
$txtSubdomain.Add_TextChanged({ Update-ButtonStates })

# Legend strip
$legendStrip = New-Object System.Windows.Forms.Panel
$legendStrip.Dock = "Bottom"
$legendStrip.Height = 40
$legendStrip.Padding = New-Object System.Windows.Forms.Padding(12, 7, 12, 7)
$legendStrip.BackColor = [System.Drawing.Color]::FromArgb(250, 251, 252)

$legend = New-Object System.Windows.Forms.FlowLayoutPanel
$legend.Dock = "Fill"
$legend.FlowDirection = "LeftToRight"
$legend.WrapContents = $false
$legend.AutoSize = $false
$legend.BackColor = [System.Drawing.Color]::Transparent

function New-LegendPill {
    param([string]$Text)
    $Theme = $script:StatusTheme[$Text]
    $P = New-Object System.Windows.Forms.Label
    $P.Text      = $Text
    $P.AutoSize  = $true
    $P.Padding   = New-Object System.Windows.Forms.Padding(10, 4, 10, 4)
    $P.Margin    = New-Object System.Windows.Forms.Padding(0, 0, 10, 0)
    $P.BackColor = $Theme.Back
    $P.ForeColor = $Theme.Fore
    $P.Font      = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $P
}
foreach ($Status in "PASS","FAIL","INFO") { $legend.Controls.Add((New-LegendPill $Status)) }
$legendStrip.Controls.Add($legend)

$panelInputs = New-Object System.Windows.Forms.Panel
$panelInputs.Dock = "Top"
$panelInputs.Height = 300
$panelInputs.BackColor = [System.Drawing.Color]::White
$panelInputs.Padding = New-Object System.Windows.Forms.Padding(0)
Add-PanelBorder $panelInputs -Rectangle

$inputsHeader = New-Object System.Windows.Forms.Panel
$inputsHeader.Dock = "Top"
$inputsHeader.Height = 36
$inputsHeader.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$inputsHeader.Padding = New-Object System.Windows.Forms.Padding(0)
Add-PanelBorder $inputsHeader

$lblInputsTitle = New-Object System.Windows.Forms.Label
$lblInputsTitle.Text = "Inputs"
$lblInputsTitle.AutoSize = $false
$lblInputsTitle.Dock = "Fill"
$lblInputsTitle.TextAlign = "MiddleLeft"
$lblInputsTitle.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
$lblInputsTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$lblInputsTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$lblInputsTitle.BackColor = [System.Drawing.Color]::Transparent
$inputsHeader.Controls.Add($lblInputsTitle)

$inputsContainer = New-Object System.Windows.Forms.Panel
$inputsContainer.Dock = "Fill"

$actionsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$actionsPanel.Dock = "Right"
$actionsPanel.Width = 170
$actionsPanel.FlowDirection = "TopDown"
$actionsPanel.WrapContents = $false
$actionsPanel.Padding = New-Object System.Windows.Forms.Padding(8, 8, 8, 8)
$actionsPanel.BackColor = [System.Drawing.Color]::Transparent

# Last button in the stack gets no bottom margin so the action column sits tight against the panel padding.
$btnExportHtml.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 0)

foreach ($Btn in $btnRun, $btnCancel, $btnDocs, $btnEnroll, $btnClear, $btnExportHtml) {
    [void]$actionsPanel.Controls.Add($Btn)
}

$fieldsLayout = New-Object System.Windows.Forms.TableLayoutPanel
$fieldsLayout.Dock = "Fill"
$fieldsLayout.ColumnCount = 2
$fieldsLayout.RowCount = 5
$fieldsLayout.Padding = New-Object System.Windows.Forms.Padding(6, 8, 6, 6)
[void]$fieldsLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 170)))
[void]$fieldsLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))
[void]$fieldsLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 34)))  # row 0 Region
[void]$fieldsLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 34)))  # row 1 Subdomain
[void]$fieldsLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20)))  # row 2 Hint
[void]$fieldsLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 34)))  # row 3 UUID
[void]$fieldsLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 34)))  # row 4 Device Domain

$cmbRegion.Dock       = "Fill"
$txtSubdomain.Dock    = "Fill"
$txtUUID.Dock         = "Fill"
$txtDeviceDomain.Dock = "Fill"

$fieldsLayout.Controls.Add($lblRegion, 0, 0)
$fieldsLayout.Controls.Add($cmbRegion, 1, 0)
$fieldsLayout.Controls.Add($lblSubdomain, 0, 1)
$fieldsLayout.Controls.Add($txtSubdomain, 1, 1)
$fieldsLayout.Controls.Add($lblSubdomainHint, 0, 2)
$fieldsLayout.SetColumnSpan($lblSubdomainHint, 2)
$fieldsLayout.Controls.Add($lblUUID, 0, 3)
$fieldsLayout.Controls.Add($txtUUID, 1, 3)
$fieldsLayout.Controls.Add($lblDeviceDomain, 0, 4)
$fieldsLayout.Controls.Add($txtDeviceDomain, 1, 4)

$inputsContainer.Controls.Add($fieldsLayout)
$inputsContainer.Controls.Add($actionsPanel)

$panelInputs.Controls.Add($inputsContainer)
$panelInputs.Controls.Add($legendStrip)
$panelInputs.Controls.Add($inputsHeader)

# -----------------------------
# Results group
# -----------------------------
$panelResults = New-Object System.Windows.Forms.Panel
$panelResults.Dock = "Fill"
$panelResults.BackColor = [System.Drawing.Color]::White
$panelResults.Padding = New-Object System.Windows.Forms.Padding(0)
Add-PanelBorder $panelResults -Rectangle

$resultsHeader = New-Object System.Windows.Forms.Panel
$resultsHeader.Dock = "Top"
$resultsHeader.Height = 36
$resultsHeader.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$resultsHeader.Padding = New-Object System.Windows.Forms.Padding(0)
Add-PanelBorder $resultsHeader

$lblResultsTitle = New-Object System.Windows.Forms.Label
$lblResultsTitle.Text = "Results"
$lblResultsTitle.AutoSize = $false
$lblResultsTitle.Dock = "Fill"
$lblResultsTitle.TextAlign = "MiddleLeft"
$lblResultsTitle.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
$lblResultsTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$lblResultsTitle.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$lblResultsTitle.BackColor = [System.Drawing.Color]::Transparent
$resultsHeader.Controls.Add($lblResultsTitle)

$script:Grid = New-Object System.Windows.Forms.DataGridView
$script:Grid.Dock = "Fill"
$script:Grid.ReadOnly = $true
$script:Grid.AllowUserToAddRows = $false
$script:Grid.AllowUserToDeleteRows = $false
$script:Grid.AutoSizeColumnsMode = "None"
$script:Grid.AllowUserToResizeColumns = $true
$script:Grid.ShowCellToolTips = $true
$script:Grid.SelectionMode = "FullRowSelect"
$script:Grid.MultiSelect = $false
$script:Grid.RowHeadersVisible = $false
$script:Grid.AutoGenerateColumns = $false
$script:Grid.BackgroundColor = [System.Drawing.Color]::White
$script:Grid.BorderStyle = "None"
$script:Grid.CellBorderStyle = "SingleHorizontal"
$script:Grid.EnableHeadersVisualStyles = $false
$script:Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(235, 238, 242)
$script:Grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$script:Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$script:Grid.ColumnHeadersHeight = 34
$script:Grid.RowTemplate.Height = 28
$script:Grid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(250, 251, 252)

[void]$script:Grid.Columns.Add("Section", "Section")
[void]$script:Grid.Columns.Add("Check", "Check")
[void]$script:Grid.Columns.Add("Status", "Status")
[void]$script:Grid.Columns.Add("Details", "Details")

$script:Grid.Columns["Section"].MinimumWidth = 90
$script:Grid.Columns["Check"].MinimumWidth   = 120
$script:Grid.Columns["Status"].MinimumWidth  = 56
$script:Grid.Columns["Details"].MinimumWidth = 200

# Proportional column widths recalculated on every resize
function Set-GridColumnWidths {
    $scrollW = [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth
    $avail   = [math]::Max($script:Grid.ClientSize.Width - $scrollW, 466)
    $script:Grid.Columns["Section"].Width = [int]($avail * 0.18)
    $script:Grid.Columns["Check"].Width   = [int]($avail * 0.24)
    $script:Grid.Columns["Status"].Width  = [int]($avail * 0.10)
    # Details gets whatever remains so no pixel is wasted and no clipping occurs
    $script:Grid.Columns["Details"].Width = $avail - $script:Grid.Columns["Section"].Width `
                                            - $script:Grid.Columns["Check"].Width   `
                                            - $script:Grid.Columns["Status"].Width
}
$script:Grid.Add_Resize({ Set-GridColumnWidths })

# Softer selection colours
$script:Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(210, 227, 252)
$script:Grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::FromArgb(20, 20, 20)

# Status-column pill badges drawn via CellPainting
$script:Grid.Add_CellPainting({
    param($s, $e)
    if ($e.ColumnIndex -ne 2 -or $e.RowIndex -lt 0) { return }
    $val = [string]$e.Value
    $e.Handled = $true

    # Row background (honour alternating + selection)
    if ($e.State -band [System.Windows.Forms.DataGridViewElementStates]::Selected) {
        $rowBg = $script:Grid.DefaultCellStyle.SelectionBackColor
    } elseif ($e.RowIndex % 2 -eq 1) {
        $rowBg = [System.Drawing.Color]::FromArgb(250, 251, 252)
    } else {
        $rowBg = [System.Drawing.Color]::White
    }
    $bgBrush = New-Object System.Drawing.SolidBrush($rowBg)
    $e.Graphics.FillRectangle($bgBrush, $e.CellBounds)
    $bgBrush.Dispose()

    if ($val) {
        $c = Get-StatusColor $val
        $pillW  = 48
        $pillH  = 18
        $pillX  = [int](($e.CellBounds.Width  - $pillW) / 2) + $e.CellBounds.X
        $pillY  = [int](($e.CellBounds.Height - $pillH) / 2) + $e.CellBounds.Y

        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc($pillX, $pillY, $pillH, $pillH, 180, 180)
        $path.AddLine($pillX + ($pillH / 2), $pillY, $pillX + $pillW - ($pillH / 2), $pillY)
        $path.AddArc($pillX + $pillW - $pillH, $pillY, $pillH, $pillH, 0, 180)
        $path.AddLine($pillX + $pillW - ($pillH / 2), $pillY + $pillH, $pillX + ($pillH / 2), $pillY + $pillH)
        $path.CloseFigure()

        $oldMode = $e.Graphics.SmoothingMode
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $pillBrush = New-Object System.Drawing.SolidBrush($c.Back)
        $e.Graphics.FillPath($pillBrush, $path)
        $pillBrush.Dispose()
        $path.Dispose()
        $e.Graphics.SmoothingMode = $oldMode

        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment     = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $pillFont   = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
        $textBrush  = New-Object System.Drawing.SolidBrush($c.Fore)
        $pillRect   = New-Object System.Drawing.RectangleF($pillX, $pillY, $pillW, $pillH)
        $e.Graphics.DrawString($val, $pillFont, $textBrush, $pillRect, $sf)
        $pillFont.Dispose()
        $textBrush.Dispose()
        $sf.Dispose()
    }

    # Cell border
    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(225, 228, 232))
    $e.Graphics.DrawLine($borderPen,
        $e.CellBounds.Left, $e.CellBounds.Bottom - 1,
        $e.CellBounds.Right - 1, $e.CellBounds.Bottom - 1)
    $borderPen.Dispose()
})

$lblWatermark = New-Object System.Windows.Forms.Label
$lblWatermark.Text = "Powered by Iru"
$lblWatermark.AutoSize = $true
$lblWatermark.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblWatermark.ForeColor = [System.Drawing.Color]::FromArgb(155, 155, 155)
$lblWatermark.BackColor = [System.Drawing.Color]::Transparent
$lblWatermark.Location = New-Object System.Drawing.Point(0, 10)

# Detail panel - shows full Details text for the selected row so nothing is ever clipped
$detailPanel = New-Object System.Windows.Forms.Panel
$detailPanel.Dock = "Bottom"
$detailPanel.Height = 72
$detailPanel.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

$lblDetailHeader = New-Object System.Windows.Forms.Label
$lblDetailHeader.Text = "Selected row - full details:"
$lblDetailHeader.AutoSize = $true
$lblDetailHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblDetailHeader.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$lblDetailHeader.Location = New-Object System.Drawing.Point(8, 4)

$txtDetail = New-Object System.Windows.Forms.TextBox
$txtDetail.Multiline = $true
$txtDetail.ReadOnly = $true
$txtDetail.ScrollBars = "Vertical"
$txtDetail.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$txtDetail.BackColor = [System.Drawing.Color]::White
$txtDetail.BorderStyle = "FixedSingle"
$txtDetail.Dock = "Bottom"
$txtDetail.Height = 50

$detailPanel.Controls.Add($txtDetail)
$detailPanel.Controls.Add($lblDetailHeader)

$script:Grid.Add_SelectionChanged({
    if ($script:Grid.SelectedRows.Count -gt 0) {
        $txtDetail.Text = [string]$script:Grid.SelectedRows[0].Cells["Details"].Value
    } else {
        $txtDetail.Text = ""
    }
})

$resultsPanel = New-Object System.Windows.Forms.Panel
$resultsPanel.Dock = "Fill"
# Add detail panel before grid so docking resolves correctly (Bottom claimed first, Fill takes remainder)
$resultsPanel.Controls.Add($detailPanel)
$resultsPanel.Controls.Add($script:Grid)
$resultsPanel.Controls.Add($lblWatermark)
$resultsPanel.Add_Resize({
    $x = [int]($resultsPanel.ClientSize.Width - $lblWatermark.Width - 14)
    if ($x -lt 14) { $x = 14 }
    $lblWatermark.Location = New-Object System.Drawing.Point($x, 10)
})
$panelResults.Controls.Add($resultsPanel)
$panelResults.Controls.Add($resultsHeader)

# Status strip
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.SizingGrip = $false

$lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
$lblStatus.Text = "Ready"

$progress = New-Object System.Windows.Forms.ToolStripProgressBar
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$progress.AutoSize = $false
$progress.Width = 220
$progress.Visible = $false

$spacer = New-Object System.Windows.Forms.ToolStripStatusLabel
$spacer.Spring = $true
$spacer.Text = ""

$lblBrand = New-Object System.Windows.Forms.ToolStripStatusLabel
$lblBrand.Text = "$BrandName - $ToolVersion"
$lblBrand.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 90)

[void]$statusStrip.Items.Add($lblStatus)
[void]$statusStrip.Items.Add($progress)
[void]$statusStrip.Items.Add($spacer)
[void]$statusStrip.Items.Add($lblBrand)

# Add controls
$form.Controls.Add($panelResults)
$form.Controls.Add($panelInputs)
$form.Controls.Add($summaryPanel)
$form.Controls.Add($header)
$form.Controls.Add($statusStrip)

# -----------------------------
# Actions
# -----------------------------
function Reset-UIState {
    $script:Results.Clear()
    $script:Grid.Rows.Clear()
    $btnExportHtml.Enabled = $false
    $lblStatus.Text = "Ready"
    $progress.Visible = $false
    $progress.Value = 0
    Update-SummaryUI
}

function Start-RunUI {
    $script:CancelRequested = $false
    Set-AccentButtonEnabled -Button $btnRun -Enabled $false
    $btnDocs.Enabled       = $false
    $btnEnroll.Enabled     = $false
    $btnClear.Enabled      = $false
    $btnExportHtml.Enabled = $false
    $btnCancel.Enabled     = $true
    $btnCancel.Visible     = $true
    $progress.Visible      = $true
    $progress.Value        = 0
}

function Stop-RunUI {
    $btnDocs.Enabled = $true
    Update-ButtonStates   # re-enables btnRun and btnEnroll only if subdomain is valid
    $btnClear.Enabled = $true
    $btnExportHtml.Enabled = ($script:Results.Count -gt 0)
    $btnCancel.Enabled = $false
    $btnCancel.Visible = $false
    $progress.Visible = $false
}

function Set-Progress {
    param([int]$Percent, [string]$Text)
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    $progress.Value = $Percent
    if ($Text) { $lblStatus.Text = $Text }
    [System.Windows.Forms.Application]::DoEvents()
}

$btnClear.Add_Click({
    $cmbRegion.SelectedIndex = 0
    $txtSubdomain.Clear()
    $txtUUID.Clear()
    $txtDeviceDomain.Clear()
    Reset-UIState
    Update-ButtonStates
})

$btnExportHtml.Add_Click({
    if ($script:Results.Count -eq 0) { return }

    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Title = "Export HTML Report"
    $dlg.Filter = "HTML Report (*.html)|*.html"
    $dlg.InitialDirectory = $DefaultOutputFolder
    $dlg.FileName = "IruPrep-Report-{0}.html" -f (Get-Date -Format "yyyyMMdd-HHmmss")

    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $sum = Get-ComplianceSummary
            $html = Convert-ResultsToHtml -Summary $sum -Title "$ToolName ($ToolVersion)"
            $html | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
            $lblStatus.Text = "Exported HTML: $([IO.Path]::GetFileName($dlg.FileName))"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to export HTML.`n$($_.Exception.Message)", "Export Error",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    }
})

# -----------------------------
# Run checks
# -----------------------------
# Runs the full Windows + network sweep, emitting one result per check.
function Invoke-AllChecks {
    $script:Results.Clear()
    $script:Grid.Rows.Clear()
    Update-SummaryUI

    Set-Progress 5 "Running checks..."

    $WinSection = "Windows requirements"

    $Win = Get-WindowsInfo
    $IsWin11 = ($null -ne $Win.BuildNumberInt -and $Win.BuildNumberInt -ge 22000)

    $Dv = if ($Win.DisplayVersion) { $Win.DisplayVersion } else { $Win.ReleaseId }
    $Is24Or25ByDv    = $Dv -in @("24H2", "25H2")
    $Is24Or25ByBuild = ($null -ne $Win.BuildNumberInt -and $Win.BuildNumberInt -ge 26100)
    $StatusWin       = if ($IsWin11 -and ($Is24Or25ByDv -or $Is24Or25ByBuild)) { "PASS" } else { "FAIL" }

    $TrueName = if ($Win.BuildNumberInt) { Get-WindowsBuildName $Win.BuildNumberInt } else { "Unknown" }

    # Row 1 - what was actually detected (always INFO so it is always visible)
    Add-CheckResult $WinSection "Detected OS" "INFO" `
        "OS: $TrueName | Build: $($Win.Build) | DisplayVersion: $Dv | Edition: $($Win.EditionId) | Kernel: $($Win.Version)" `
        -Data @{ Name = $TrueName; Build = $Win.Build; DisplayVersion = $Dv; Edition = $Win.EditionId }

    # Row 2 - does it meet the requirement?
    $SupportedVersions = "Supported: Windows 11 24H2 (Build 26100+), Windows 11 25H2"
    $ReqReason = if ($StatusWin -eq "PASS") {
        "$TrueName meets the minimum OS requirement."
    } elseif (-not $IsWin11) {
        "$TrueName is not Windows 11. Iru requires Windows 11 24H2 or later."
    } else {
        "$TrueName does not meet the minimum feature update. Upgrade to 24H2 or later."
    }
    Add-CheckResult $WinSection "OS version (min: Win 11 24H2)" $StatusWin "$ReqReason $SupportedVersions" `
        -Data @{ Reason = $ReqReason }

    Set-Progress 15 "Checking Windows edition..."
    $AllowedEditions = @("Professional","ProfessionalEducation","Enterprise","Education","Pro","ProEducation")
    $OkEdition = $false
    if ($Win.EditionId) {
        $OkEdition = ($AllowedEditions -contains $Win.EditionId) -or
                     ($Win.EditionId -match "Professional|Education|Enterprise")
    }
    $StatusEdition = if ($OkEdition) { "PASS" } else { "FAIL" }
    Add-CheckResult $WinSection "Supported Windows edition" $StatusEdition `
        "EditionID: $($Win.EditionId) (Allowed: Pro, Pro Education, Enterprise, Education)"

    Set-Progress 25 "Checking Microsoft Edge..."
    $Edge = Get-EdgeInfo
    $StatusEdge = if ($Edge.Installed) { "PASS" } else { "FAIL" }
    $DetailsEdge = if ($Edge.Installed) {
        "Detected via: {0}; Path: {1}; Version: {2}" -f $Edge.Method, $Edge.Path, $Edge.Version
    } else {
        "Edge not detected via App Paths, common paths, or AppX package."
    }
    Add-CheckResult $WinSection "Microsoft Edge installed" $StatusEdge $DetailsEdge

    Set-Progress 35 "Checking serial number..."
    $Sn = Get-SerialInfo
    $StatusSn = if ($Sn.Present) { "PASS" } else { "FAIL" }
    $SnValue  = if ($Sn.SerialNumber) { $Sn.SerialNumber } else { "(none detected)" }
    $SnReason = if ($Sn.Present) {
        "Serial number is present and valid."
    } elseif (-not $Sn.SerialNumber) {
        "No serial number was returned by BIOS/UEFI (Win32_BIOS.SerialNumber is empty)."
    } else {
        "Serial number '$($Sn.SerialNumber)' is a known placeholder value  -  BIOS/UEFI has not been programmed with a real serial."
    }
    Add-CheckResult $WinSection "Serial number present" $StatusSn "SerialNumber: $SnValue | $SnReason" `
        -Data @{ Serial = $SnValue; Reason = $SnReason }

    Set-Progress 36 "Checking current user + admin status..."
    $AdminCheck = Test-CurrentUserIsAdmin
    $StatusAdmin = if ($AdminCheck.IsAdmin) { "PASS" } else { "FAIL" }
    Add-CheckResult $WinSection "Current user is local admin" $StatusAdmin `
        "User: $($AdminCheck.User) | $($AdminCheck.Detail)"

    Set-Progress 38 "Checking for pending reboot..."
    $Reboot = Test-PendingReboot
    $StatusReboot = if ($Reboot.Pending) { "FAIL" } else { "PASS" }
    Add-CheckResult $WinSection "No pending reboot" $StatusReboot $Reboot.Detail

    # MDM enrollment must be NOT enrolled (ENROLLED => FAIL)
    Set-Progress 40 "Checking MDM enrollment..."
    $Mdm = Get-MdmEnrollmentInfo
    $StatusMdm = if ($Mdm.Enrolled) { "FAIL" } else { "PASS" }
    $MdmPrefix = if ($Mdm.Enrolled) { "Device IS enrolled in MDM. " } else { "Device is NOT enrolled in MDM. " }
    Add-CheckResult $WinSection "MDM enrollment status (must be NOT enrolled)" $StatusMdm ($MdmPrefix + $Mdm.Details)

    Set-Progress 42 "Checking MDM unenrollment policy..."
    $Exp = Get-ExperienceEnrollmentPolicy
    Add-CheckResult $WinSection "AllowManualMDMUnenrollment policy" $Exp.Status $Exp.Details

    Add-CheckResult $WinSection "SSO configured (recommended)" "INFO" `
        "Not automatically detectable here. If your org uses SSO, confirm its configured in Iru."

    # Network
    Set-Progress 50 "Preparing network tests..."
    $Region = $cmbRegion.SelectedItem.ToString()
    $Sub    = $txtSubdomain.Text.Trim()
    $Uuid   = $txtUUID.Text.Trim()
    $Dd     = $txtDeviceDomain.Text.Trim()
    $NetSection = "Network ($Region)"

    Add-CheckResult $NetSection "Region selected" "INFO" $Region

    $Domains = Get-RegionDomains -Region $Region -Subdomain $Sub -UUID $Uuid

    if ($Sub) {
        Set-Progress 52 "Validating tenant subdomain..."
        $GwHost = $script:RegionMap[$Region].GatewayHost
        $TenantCheck = Test-TenantSubdomain -Subdomain $Sub -GatewayHost $GwHost
        Add-CheckResult $NetSection "Tenant subdomain exists" $TenantCheck.Status $TenantCheck.Detail
    } else {
        Add-CheckResult $NetSection "Tenant subdomain domains" "INFO" `
            "Enter Tenant Subdomain to test subdomain.iru.com and related gateway/id domains."
    }
    if (-not $Uuid) {
        Add-CheckResult $NetSection "Tenant UUID domains" "INFO" `
            "Enter Tenant UUID to test UUID.web-api.* and UUID.devices.* domains."
    }

    if ($Dd) {
        $Domains = @($Domains + $Dd) | Select-Object -Unique
        Add-CheckResult $NetSection "Device Domain override" "INFO" "Including override hostname: $Dd"
    }

    $Wildcard = $script:RegionMap[$Region].Wildcard
    Add-CheckResult $NetSection "Wildcard telemetry domain" "INFO" `
        "Allow outbound TCP/443 to $Wildcard (wildcards cannot be directly probed without a concrete host)."

    $UniqueEndpoints = ($Domains | Where-Object { $_ } | Select-Object -Unique)
    $Total = $UniqueEndpoints.Count
    $I = 0

    foreach ($Endpoint in $UniqueEndpoints) {
        if ($script:CancelRequested) {
            Add-CheckResult $NetSection "Checks cancelled" "INFO" `
                "User cancelled remaining network checks after $I of $Total endpoints."
            break
        }

        $I++
        $Pct = 50 + [int](50 * ($I / [double]([math]::Max($Total, 1))))
        Set-Progress $Pct ("Testing: $Endpoint")

        # Single TCP connection per host: derive connectivity and latency from one call
        $Lat = Test-TcpLatency443 -TargetHost $Endpoint -TimeoutMs $TcpConnectTimeoutMs `
            -PassMaxMs $TcpRttPassMaxMs -InfoMaxMs $TcpRttInfoMaxMs

        $StatusNet  = if ($Lat.Status -ne "FAIL") { "PASS" } else { "FAIL" }
        $ConnDetail = if ($StatusNet -eq "PASS") { "TCP 443 reachable" } else { $Lat.Detail }
        $LatStatus  = $Lat.Status
        $LatDetail  = "$($Lat.Detail) (Healthy <= $TcpRttPassMaxMs ms)"

        # Provisioned but not yet serving traffic -- don't drag the score down.
        if ($script:NotYetActiveDomains -contains $Endpoint) {
            $Note = " Note: $Endpoint is not yet expected to be reachable; reported as INFO."
            if ($StatusNet -eq "FAIL") { $StatusNet = "INFO"; $ConnDetail = "$ConnDetail$Note" }
            if ($LatStatus -eq "FAIL") { $LatStatus = "INFO"; $LatDetail  = "$LatDetail$Note"  }
        }

        Add-CheckResult $NetSection "TCP 443 to $Endpoint" $StatusNet $ConnDetail
        Add-CheckResult $NetSection "Latency (TCP/443) to $Endpoint" $LatStatus $LatDetail
    }

    Update-SummaryUI
    $Sum = Get-ComplianceSummary
    $Avg = Get-AverageRtt
    $AvgText = if ($Avg.HasData) { ($Avg.AvgMs.ToString() + " ms") } else { "-" }

    $StatusPrefix = if ($script:CancelRequested) { "Cancelled" } else { "Done" }
    $lblStatus.Text = "$StatusPrefix - Overall: $($Sum.Overall), Score: $($Sum.Score)%, Avg TCP/443 latency: $AvgText"

    $btnExportHtml.Enabled = $true
}

$btnRun.Add_Click({
    Start-RunUI
    try { Invoke-AllChecks } finally { Stop-RunUI; [System.Windows.Forms.Application]::DoEvents() }
})

# Init
Reset-UIState
Update-ButtonStates
$form.Add_Shown({ Set-GridColumnWidths; Set-HeaderLayout })
[void]$form.ShowDialog()
