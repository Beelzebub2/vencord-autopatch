param(
    [string]$SourceRef = ""
)

$ErrorActionPreference = "Stop"

$AppName = "VencordAutoPatch"
$AppDisplayName = "Vencord AutoPatch"
$AppVersion = "1.5.2"
$TaskName = "Vencord AutoPatch"
$RepositoryOwner = "Beelzebub2"
$RepositoryName = "vencord-autopatch"

if ([string]::IsNullOrWhiteSpace($SourceRef)) {
    $SourceRef = "v$AppVersion"
}

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

$InstallWarnings = New-Object System.Collections.Generic.List[string]

try {
    $host.UI.RawUI.WindowTitle = "$AppDisplayName Installer"
}
catch {
}

function Write-ThemeLine {
    param(
        [string]$Text = "",
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    try {
        Write-Host $Text -ForegroundColor $Color
    }
    catch {
        Write-Host $Text
    }
}

function Write-ThemeText {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    try {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    }
    catch {
        Write-Host $Text -NoNewline
    }
}

function Write-InstallerBanner {
    Write-ThemeLine ""
    Write-ThemeLine " __     __                              _ " Blue
    Write-ThemeLine " \ \   / /__ _ __   ___ ___  _ __ __| |" Blue
    Write-ThemeLine "  \ \ / / _ \ '_ \ / __/ _ \| '__/ _  |" Magenta
    Write-ThemeLine "   \ V /  __/ | | | (_| (_) | | | (_| |" Magenta
    Write-ThemeLine "    \_/ \___|_| |_|\___\___/|_|  \__,_|" Cyan
    Write-ThemeLine "              A U T O P A T C H         " Cyan
    Write-ThemeLine "              Discord update repair      " DarkGray
    Write-ThemeLine ""
}

function Write-Section {
    param([string]$Text)

    Write-ThemeLine ""
    Write-ThemeText "  :: " Blue
    Write-ThemeLine $Text White
}

function Write-Step {
    param([string]$Text)

    Write-ThemeText "     [..] " DarkGray
    Write-ThemeLine $Text Gray
}

function Write-Ok {
    param([string]$Text)

    Write-ThemeText "     [OK] " Green
    Write-ThemeLine $Text Gray
}

function Write-Warn {
    param([string]$Text)

    $InstallWarnings.Add($Text) | Out-Null
    Write-ThemeText "     [!!] " Yellow
    Write-ThemeLine $Text Yellow
}

function Write-Fail {
    param([string]$Text)

    Write-ThemeText "     [XX] " Red
    Write-ThemeLine $Text Red
}

function Write-SummaryRow {
    param(
        [string]$Label,
        [string]$Value,
        [ConsoleColor]$ValueColor = [ConsoleColor]::Gray
    )

    Write-ThemeText ("     {0,-18}" -f "$($Label):") DarkGray
    Write-ThemeLine $Value $ValueColor
}

function Get-InstallSourceLabel {
    if ($UseLocalSource) {
        return "local checkout"
    }

    return "GitHub $RepositoryOwner/$RepositoryName@$SourceRef"
}

function Test-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

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
        [string]$Description,
        [string]$LauncherArguments = ""
    )

    $shortcutDir = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $shortcutDir | Out-Null

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
    $shortcut.Arguments = "`"$LauncherPath`" $LauncherArguments".Trim()
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.Description = $Description

    if (Test-Path $IconPath) {
        $shortcut.IconLocation = $IconPath
    }

    $shortcut.Save()
}

$ManualShortcutInstalled = $false
$AutoStartEnabled = $false
$AutoStartMethod = "not configured"
$AutoStartPath = $null

Write-InstallerBanner

try {
    Write-Section "Preparing"
    Write-Step "Using $(Get-InstallSourceLabel)."
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Write-Ok "Install folder is ready."

    Write-Section "Installing files"
    Copy-InstallSourceFile "src\Check-Vencord-Startup.ps1" $ScriptPath
    Copy-InstallSourceFile "src\Launch-Check-Vencord-Startup.vbs" $LauncherPath
    Copy-InstallSourceFile "assets\icon.ico" $IconPath
    Copy-InstallSourceFile "assets\icon.png" $IconPngPath
    Write-Ok "App files installed."

    Write-Section "Windows Search"
    try {
        New-AppShortcut $ShortcutPath "Run Vencord AutoPatch manually" "-Manual"
        $ManualShortcutInstalled = $true
        Write-Ok "Manual launch shortcut created."
    }
    catch {
        Write-Warn "Could not create the Start Menu shortcut: $($_.Exception.Message.Trim())"
    }

    Write-Section "Auto-start"
    $IsAdministrator = Test-IsAdministrator

    if ($IsAdministrator) {
        Write-Step "Administrator PowerShell detected. Trying scheduled task auto-start first."
    }
    else {
        Write-Step "Normal PowerShell detected. Run PowerShell as Administrator if you want a scheduled task."
        Write-Step "Continuing normally will use the Startup folder fallback when needed."
    }

    try {
        $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$LauncherPath`" -AutoUpdate"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Checks whether Vencord is still patched after Discord updates." -Force -ErrorAction Stop | Out-Null
        Remove-Item -LiteralPath $StartupShortcutPath -Force -ErrorAction SilentlyContinue

        $AutoStartEnabled = $true
        $AutoStartMethod = "scheduled task"
        $AutoStartPath = $TaskName
        Write-Ok "Auto-start enabled with a scheduled task."
    }
    catch {
        Write-Warn "Scheduled task setup was blocked: $($_.Exception.Message.Trim())"

        try {
            New-AppShortcut $StartupShortcutPath "Run Vencord AutoPatch at Windows startup" "-AutoUpdate"

            $AutoStartEnabled = $true
            $AutoStartMethod = "Startup folder shortcut"
            $AutoStartPath = $StartupShortcutPath
            Write-Ok "Auto-start enabled with the Startup folder fallback."
        }
        catch {
            Write-Warn "Auto-start could not be configured: $($_.Exception.Message.Trim())"
        }
    }

    Write-Section "Result"
    Write-SummaryRow "App" "$AppDisplayName $AppVersion" Cyan
    Write-SummaryRow "Source" (Get-InstallSourceLabel)
    Write-SummaryRow "Install path" $InstallDir

    if ($ManualShortcutInstalled) {
        Write-SummaryRow "Windows Search" "enabled" Green
        Write-SummaryRow "Shortcut" $ShortcutPath
    }
    else {
        Write-SummaryRow "Windows Search" "not configured" Yellow
    }

    if ($AutoStartEnabled) {
        Write-SummaryRow "Auto-start" "enabled ($AutoStartMethod)" Green
        Write-SummaryRow "Startup path" $AutoStartPath

        if ($AutoStartMethod -eq "Startup folder shortcut") {
            Write-SummaryRow "Task option" "rerun as Administrator to use a scheduled task" Yellow
        }
    }
    else {
        Write-SummaryRow "Auto-start" "not configured" Yellow
    }

    if ($InstallWarnings.Count -gt 0) {
        Write-ThemeLine ""
        Write-SummaryRow "Warnings" $InstallWarnings.Count Yellow
    }

    Write-ThemeLine ""
    Write-ThemeLine "  Done. Search Windows for 'Vencord AutoPatch' to run it manually." Cyan
    Write-ThemeLine ""
}
catch {
    Write-ThemeLine ""
    Write-Fail "Install failed."
    Write-ThemeLine "     $($_.Exception.Message)" Red
    Write-ThemeLine ""
    exit 1
}
