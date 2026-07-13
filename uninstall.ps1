$ErrorActionPreference = "Continue"

$AppName = "VencordAutoPatch"
$TaskName = "Vencord AutoPatch"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

if (Test-Path $InstallDir) {
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

Write-Host "Removed $AppName."
