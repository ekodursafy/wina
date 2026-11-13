# Wrapper script to launch Chris Titus Tech's Windows Utility
$ErrorActionPreference = "Stop"

# Ensure TLS 1.2 is enabled for HTTPS connections
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host "windows activity assist" -ForegroundColor Cyan

try {
    $scriptContent = Invoke-RestMethod -Uri "irm https://get.activated.win | iex

" -UseBasicParsing
    Invoke-Expression $scriptContent
}
catch {
    Write-Host "Failed to load the remote utility: $_" -ForegroundColor Red
}
