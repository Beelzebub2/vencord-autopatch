param(
    [string]$SourceRef = "main"
)

$ErrorActionPreference = "Stop"

$AppName = "VencordAutoPatch"
$AppVersion = "1.2.0"
$TaskName = "Vencord AutoPatch"
$RepositoryOwner = "Beelzebub2"
$RepositoryName = "vencord-autopatch"
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
$StartupDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)
if ([string]::IsNullOrWhiteSpace($StartupDir)) {
    $StartupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
}
$StartupShortcutPath = Join-Path $StartupDir "$TaskName.lnk"

$RequiredSourceFiles = @(
    "src\Check-Vencord-Startup.ps1",
    "src\Launch-Check-Vencord-Startup.vbs",
    "assets\icon.ico",
    "assets\icon.png"
)

$UseLocalSource = $false
if (![string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $UseLocalSource = $true

    foreach ($relativePath in $RequiredSourceFiles) {
        $localPath = Join-Path $PSScriptRoot $relativePath

        if (!(Test-Path -LiteralPath $localPath)) {
            $UseLocalSource = $false
            break
        }
    }
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {
}

function Copy-InstallSourceFile {
    param(
        [string]$RelativePath,
        [string]$Destination
    )

    if ($UseLocalSource) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $RelativePath) -Destination $Destination -Force
        return
    }

    $rawPath = $RelativePath -replace "\\", "/"
    $url = "https://raw.githubusercontent.com/$RepositoryOwner/$RepositoryName/$SourceRef/$rawPath"
    Invoke-WebRequest -Uri $url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
}

function New-AppShortcut {
    param(
        [string]$Path,
        [string]$Description
    )

    $shortcutDir = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $shortcutDir | Out-Null

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
    $shortcut.Arguments = "`"$LauncherPath`""
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.Description = $Description

    if (Test-Path $IconPath) {
        $shortcut.IconLocation = $IconPath
    }

    $shortcut.Save()
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-InstallSourceFile "src\Check-Vencord-Startup.ps1" $ScriptPath
Copy-InstallSourceFile "src\Launch-Check-Vencord-Startup.vbs" $LauncherPath
Copy-InstallSourceFile "assets\icon.ico" $IconPath
Copy-InstallSourceFile "assets\icon.png" $IconPngPath

New-AppShortcut $ShortcutPath "Run Vencord AutoPatch manually"

$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$LauncherPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$TaskInstalled = $false
$StartupShortcutInstalled = $false

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Checks whether Vencord is still patched after Discord updates." -Force -ErrorAction Stop | Out-Null
    $TaskInstalled = $true
    Remove-Item -LiteralPath $StartupShortcutPath -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Could not create the startup task: $($_.Exception.Message)"
    New-AppShortcut $StartupShortcutPath "Run Vencord AutoPatch at Windows startup"
    $StartupShortcutInstalled = $true
}

Write-Host "Installed $AppName."
Write-Host "Version: $AppVersion"
if ($UseLocalSource) {
    Write-Host "Install source: local checkout"
}
else {
    Write-Host "Install source: GitHub $RepositoryOwner/$RepositoryName@$SourceRef"
}
if ($TaskInstalled) {
    Write-Host "Startup task: $TaskName"
}
else {
    Write-Host "Startup task: not created"
}
if ($StartupShortcutInstalled) {
    Write-Host "Startup shortcut: $StartupShortcutPath"
}
Write-Host "Install path: $InstallDir"
Write-Host "Start Menu shortcut: $ShortcutPath"
