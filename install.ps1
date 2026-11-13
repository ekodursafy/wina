# Windows and Office Diagnostic Tool
# Read-only checks. Does not change licensing settings.

Write-Host ""
Write-Host "======================================"
Write-Host " WINDOWS & OFFICE DIAGNOSTICS"
Write-Host "======================================"

# Windows information
$os = Get-CimInstance Win32_OperatingSystem

Write-Host ""
Write-Host "WINDOWS INFORMATION"
Write-Host "-------------------"
Write-Host "Edition: $($os.Caption)"
Write-Host "Version: $($os.Version)"
Write-Host "Build: $($os.BuildNumber)"

# Windows activation status
Write-Host ""
Write-Host "WINDOWS ACTIVATION"
Write-Host "------------------"

cscript.exe //nologo "$env:windir\System32\slmgr.vbs" /xpr

# Office installation detection
Write-Host ""
Write-Host "OFFICE INFORMATION"
Write-Host "------------------"

$paths = @(
    "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
)

$found = $false

foreach ($path in $paths) {
    if (Test-Path $path) {
        $found = $true
        Write-Host "Office licensing script found:"
        Write-Host $path

        Write-Host ""
        Write-Host "Office licensing status:"

        cscript.exe //nologo $path /dstatus
    }
}

if (-not $found) {
    Write-Host "Office licensing script not found in standard locations."
}

Write-Host ""
Write-Host "======================================"
Write-Host " DIAGNOSTICS COMPLETED"
Write-Host "======================================"
