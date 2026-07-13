$ErrorActionPreference = "Stop"

$AppName = "VencordAutoPatch"
$TaskName = "Vencord AutoPatch"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$ScriptPath = Join-Path $InstallDir "Check-Vencord-Startup.ps1"
$LauncherPath = Join-Path $InstallDir "Launch-Check-Vencord-Startup.vbs"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "src\Check-Vencord-Startup.ps1") -Destination $ScriptPath -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "src\Launch-Check-Vencord-Startup.vbs") -Destination $LauncherPath -Force

$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$LauncherPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Checks whether Vencord is still patched after Discord updates." -Force | Out-Null

Write-Host "Installed $AppName."
Write-Host "Startup task: $TaskName"
Write-Host "Install path: $InstallDir"
