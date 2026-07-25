$ErrorActionPreference = "Stop"

$AppName = "VencordAutoPatch"
$AppVersion = "1.1.0"
$TaskName = "Vencord AutoPatch"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$ScriptPath = Join-Path $InstallDir "Check-Vencord-Startup.ps1"
$LauncherPath = Join-Path $InstallDir "Launch-Check-Vencord-Startup.vbs"
$IconPath = Join-Path $InstallDir "icon.ico"
$IconPngPath = Join-Path $InstallDir "icon.png"
$StartMenuDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
if ([string]::IsNullOrWhiteSpace($StartMenuDir)) {
    $StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
}
$ShortcutPath = Join-Path $StartMenuDir "$TaskName.lnk"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "src\Check-Vencord-Startup.ps1") -Destination $ScriptPath -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "src\Launch-Check-Vencord-Startup.vbs") -Destination $LauncherPath -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "assets\icon.ico") -Destination $IconPath -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "assets\icon.png") -Destination $IconPngPath -Force

New-Item -ItemType Directory -Force -Path $StartMenuDir | Out-Null
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
$Shortcut.Arguments = "`"$LauncherPath`""
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "Run Vencord AutoPatch manually"
if (Test-Path $IconPath) {
    $Shortcut.IconLocation = $IconPath
}
$Shortcut.Save()

$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$LauncherPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$TaskInstalled = $false

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Checks whether Vencord is still patched after Discord updates." -Force -ErrorAction Stop | Out-Null
    $TaskInstalled = $true
}
catch {
    Write-Warning "Could not create the startup task: $($_.Exception.Message)"
}

Write-Host "Installed $AppName."
Write-Host "Version: $AppVersion"
if ($TaskInstalled) {
    Write-Host "Startup task: $TaskName"
}
else {
    Write-Host "Startup task: not created"
}
Write-Host "Install path: $InstallDir"
Write-Host "Start Menu shortcut: $ShortcutPath"
