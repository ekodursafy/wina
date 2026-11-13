# Windows and Office Diagnostic Tool
# Read-only checks. Does not change licensing settings.

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " WINDOWS & OFFICE DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Windows information
$os = Get-CimInstance Win32_OperatingSystem

Write-Host ""
Write-Host "WINDOWS INFORMATION" -ForegroundColor Yellow
Write-Host "-------------------"
Write-Host "Edition: $($os.Caption)"
Write-Host "Version: $($os.Version)"
Write-Host "Build:   $($os.BuildNumber)"

# Windows activation status
Write-Host ""
Write-Host "WINDOWS ACTIVATION" -ForegroundColor Yellow
Write-Host "------------------"

$winStatus = (cscript.exe //nologo "$env:windir\System32\slmgr.vbs" /xpr) -join " "
if ($winStatus -match "permanently activated") {
    Write-Host "Status: Permanently Activated" -ForegroundColor Green
} else {
    Write-Host "Status: $($winStatus.Trim())" -ForegroundColor Red
}

# Office Click-to-Run & Microsoft 365 Subscription Check
Write-Host ""
Write-Host "MICROSOFT 365 / SUBSCRIPTION STATUS" -ForegroundColor Yellow
Write-Host "-----------------------------------"

$c2rPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
if (Test-Path $c2rPath) {
    $c2r = Get-ItemProperty $c2rPath -ErrorAction SilentlyContinue
    if ($c2r.ProductReleaseIds) {
        Write-Host "Installed SKUs: $($c2r.ProductReleaseIds)"
    }
    if ($c2r.VersionToReport) {
        Write-Host "Office Version: $($c2r.VersionToReport)"
    }
}

$vnextReg = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Licensing\LicensingNext"
$m365Found = $false

if (Test-Path $vnextReg) {
    $props = Get-ItemProperty $vnextReg -ErrorAction SilentlyContinue
    $products = $props.PSObject.Properties | Where-Object {
        $_.Name -notmatch "^PS" -and $_.Value -eq 2
    }

    if ($products) {
        $m365Found = $true
        foreach ($prod in $products) {
            Write-Host "Subscription SKU: $($prod.Name)"
            Write-Host "License Mode:     Modern Subscription (vNext Active)" -ForegroundColor Green
        }
    }
}

# Check Microsoft's built-in vnextdiag.ps1 if available for user/tenant details
$vnextScripts = @(
    "$env:ProgramFiles\Microsoft Office\Office16\vnextdiag.ps1",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\vnextdiag.ps1"
)

foreach ($vScript in $vnextScripts) {
    if (Test-Path $vScript) {
        $vOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $vScript -action list 2>$null
        $licensedLines = $vOutput | Where-Object { $_ -match "State\s*:\s*Licensed|Email\s*:|Product\s*:" }
        if ($licensedLines) {
            $m365Found = $true
            Write-Host ""
            Write-Host "vNext License Details:" -ForegroundColor Cyan
            foreach ($line in $licensedLines) {
                Write-Host "  $($line.Trim())" -ForegroundColor Green
            }
        }
    }
}

if (-not $m365Found) {
    Write-Host "Status: No active Microsoft 365 subscription found in current user registry." -ForegroundColor Gray
}

# Legacy / Perpetual Office Licensing (OSPP.VBS)
Write-Host ""
Write-Host "PERPETUAL / LEGACY OFFICE LICENSING (OSPP)" -ForegroundColor Yellow
Write-Host "------------------------------------------"

$paths = @(
    "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
)

$found = $false

foreach ($path in $paths) {
    if (Test-Path $path) {
        $found = $true
        Write-Host "Script Path: $path"
        Write-Host ""

        $rawOutput = cscript.exe //nologo $path /dstatus
        $licenses = ($rawOutput -join "`n") -split "---------------------------------------"

        foreach ($block in $licenses) {
            if ($block -match "LICENSE NAME:\s*(.+)") {
                $name = $matches[1].Trim()
                $status = if ($block -match "LICENSE STATUS:\s*(.+)") { $matches[1].Trim() } else { "Unknown" }
                $key = if ($block -match "Last 5 characters of installed product key:\s*(.+)") { $matches[1].Trim() } else { "N/A" }

                Write-Host "Product: $name"
                Write-Host "Key End: $key"

                if ($status -match "LICENSED") {
                    Write-Host "Status:  Activated (Licensed)" -ForegroundColor Green
                }
                elseif ($status -match "OOB_GRACE") {
                    $grace = if ($block -match "REMAINING GRACE:\s*(.+)") { $matches[1].Trim() } else { "Active" }
                    Write-Host "Status:  Unactivated - Grace Period ($grace)" -ForegroundColor Yellow
                }
                elseif ($status -match "NOTIFICATION") {
                    Write-Host "Status:  Unactivated - Grace Period Expired" -ForegroundColor Red
                }
                else {
                    Write-Host "Status:  $status" -ForegroundColor Yellow
                }
                Write-Host "---------------------------------------"
            }
        }
    }
}

if (-not $found) {
    Write-Host "Office licensing script not found in standard locations." -ForegroundColor Gray
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " DIAGNOSTICS COMPLETED" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
