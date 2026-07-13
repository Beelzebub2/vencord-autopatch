$ErrorActionPreference = "Continue"

$AppName = "VencordStartupCheck"
$TaskName = "Check Vencord on Startup"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

if (Test-Path $InstallDir) {
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

Write-Host "Removed $AppName."
