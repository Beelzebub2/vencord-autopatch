$ErrorActionPreference = "Continue"

$AppName = "VencordAutoPatch"
$AppDisplayName = "Vencord AutoPatch"
$AppVersion = "1.5.3"
$TaskName = "Vencord AutoPatch"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName

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

$RemovedItems = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]

try {
    $host.UI.RawUI.WindowTitle = "$AppDisplayName Uninstaller"
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
    Write-ThemeLine "              Uninstall cleanup          " DarkGray
    Write-ThemeLine ""
}

function Write-Section {
    param([string]$Text)

    Write-ThemeLine ""
    Write-ThemeText "  :: " Blue
    Write-ThemeLine $Text White
}

function Write-Ok {
    param([string]$Text)

    Write-ThemeText "     [OK] " Green
    Write-ThemeLine $Text Gray
}

function Write-Step {
    param([string]$Text)

    Write-ThemeText "     [..] " DarkGray
    Write-ThemeLine $Text Gray
}

function Write-Warn {
    param([string]$Text)

    $Warnings.Add($Text) | Out-Null
    Write-ThemeText "     [!!] " Yellow
    Write-ThemeLine $Text Yellow
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

function Remove-PathIfPresent {
    param(
        [string]$Path,
        [string]$Label,
        [switch]$Recurse
    )

    if (!(Test-Path -LiteralPath $Path)) {
        Write-Step "$Label was not present."
        return
    }

    try {
        if ($Recurse) {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        }
        else {
            Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        }

        $RemovedItems.Add($Label) | Out-Null
        Write-Ok "$Label removed."
    }
    catch {
        Write-Warn "Could not remove $Label`: $($_.Exception.Message.Trim())"
    }
}

Write-InstallerBanner

Write-Section "Stopping auto-start"
try {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($null -eq $task) {
        Write-Step "Scheduled task was not present."
    }
    else {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        $RemovedItems.Add("scheduled task") | Out-Null
        Write-Ok "Scheduled task removed."
    }
}
catch {
    Write-Warn "Could not remove scheduled task: $($_.Exception.Message.Trim())"
}

Remove-PathIfPresent $StartupShortcutPath "Startup folder shortcut"

Write-Section "Removing shortcuts"
Remove-PathIfPresent $ShortcutPath "Start Menu shortcut"

Write-Section "Removing app files"
Remove-PathIfPresent $InstallDir "installed app folder" -Recurse

Write-Section "Result"
Write-SummaryRow "App" "$AppDisplayName $AppVersion" Cyan

if ($RemovedItems.Count -gt 0) {
    Write-SummaryRow "Removed" ($RemovedItems -join ", ") Green
}
else {
    Write-SummaryRow "Removed" "nothing was installed" Yellow
}

if ($Warnings.Count -gt 0) {
    Write-SummaryRow "Warnings" $Warnings.Count Yellow
}

Write-ThemeLine ""
Write-ThemeLine "  Done. $AppDisplayName has been uninstalled." Cyan
Write-ThemeLine ""
