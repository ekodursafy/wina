# Wrapper script to launch Chris Titus Tech's Windows Utility
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host "windows activity assist" -ForegroundColor Cyan

try {
    $uri = "https://christitus.com/win"
    $scriptContent = Invoke-RestMethod -Uri $uri -UseBasicParsing
    Invoke-Expression $scriptContent
}
catch {
    Write-Host "Failed to load the remote utility: $_" -ForegroundColor Red
}
