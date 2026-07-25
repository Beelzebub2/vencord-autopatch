$ErrorActionPreference = "Continue"

$AppName = "VencordAutoPatch"
$TaskName = "Vencord AutoPatch"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$StartMenuDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
if ([string]::IsNullOrWhiteSpace($StartMenuDir)) {
    $StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
}
$ShortcutPath = Join-Path $StartMenuDir "$TaskName.lnk"

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $ShortcutPath -Force -ErrorAction SilentlyContinue

if (Test-Path $InstallDir) {
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}

Write-Host "Removed $AppName."
