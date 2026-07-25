<p align="center">
  <img src="assets/banner.png" alt="Vencord AutoPatch banner" width="100%">
</p>

<h1 align="center">Vencord AutoPatch</h1>

<p align="center">
  <img src="assets/icon.png" alt="Icon" width="96" height="96">
</p>

<p align="center">
  Automatically repair Vencord after Discord updates with a clean Windows startup UI.
</p>

<p align="center">
  <strong>Vencord AutoPatch</strong> is a lightweight Windows helper for Discord + Vencord users. It checks whether Vencord is still patched at logon and repairs it quietly when Discord updates remove the patch.
</p>

## Why

Vencord is a popular Discord client mod with plugins, themes, custom CSS, privacy-friendly defaults, and support for Discord Stable, PTB, and Canary. Discord updates can sometimes remove the Vencord patch, which means you may need to run the installer again.

Vencord AutoPatch handles that routine check for you at Windows startup. If everything is still patched, it closes quietly. If repair is needed, it downloads the official Vencord installer CLI, applies the repair, and reopens Discord.

## What It Does

- Checks detected Discord installs on startup
- Verifies the Vencord patch marker
- Downloads the official Vencord installer CLI when repair is needed
- Closes and reopens Discord during repair
- Uses a polished WPF status UI with smooth motion instead of a console window
- Shows a themed console installer with an ASCII logo and clear setup status
- Adds a Start Menu shortcut so Windows Search can launch it manually
- Checks GitHub tags for newer AutoPatch versions and updates itself
- Asks before installing AutoPatch updates when launched manually
- Writes detailed logs locally for troubleshooting

## Search Keywords

Vencord AutoPatch, Vencord auto repair, Vencord startup check, Vencord Windows startup, Discord Vencord repair, Discord update removed Vencord, Vencord installer CLI, Discord client mod repair, Vencord patch checker, no-console PowerShell startup UI.

## Install

Paste this into PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command '$tags=irm https://api.github.com/repos/Beelzebub2/vencord-autopatch/tags; $tag=($tags.name | Where-Object { $_ -match ''^v\d+\.\d+\.\d+$'' } | Sort-Object { [version]($_ -replace ''^v'','''') } -Descending | Select-Object -First 1); & ([scriptblock]::Create((irm (''https://raw.githubusercontent.com/Beelzebub2/vencord-autopatch/'' + $tag + ''/install.ps1''))))'
```

The installer downloads the needed files from GitHub and copies them to:

```text
%LOCALAPPDATA%\VencordAutoPatch
```

and creates a Start Menu shortcut named:

```text
Vencord AutoPatch
```

For automatic startup, use the same command in normal PowerShell if you want the simple Startup folder shortcut. Open PowerShell as Administrator first if you want AutoPatch to try creating a scheduled task instead.

If scheduled task setup is blocked, the installer falls back to the normal user Startup folder shortcut.

The installer summary shows whether Windows Search and automatic startup were configured successfully.

If you already cloned the repo, you can still run the local installer:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## Run Manually

After installing, open the Windows search menu and search for:

```text
Vencord AutoPatch
```

Manual launches and direct script runs check for AutoPatch updates and ask before installing them. Startup launches installed by this installer pass an auto-update flag so they can stay quiet.

You can also run it directly from the source checkout:

```powershell
powershell -ExecutionPolicy Bypass -STA -File .\src\Check-Vencord-Startup.ps1
```

Preview without making changes:

```powershell
powershell -ExecutionPolicy Bypass -STA -File .\src\Check-Vencord-Startup.ps1 -DryRun
```

Skip the AutoPatch self-update check:

```powershell
powershell -ExecutionPolicy Bypass -STA -File .\src\Check-Vencord-Startup.ps1 -NoSelfUpdate
```

## Self Updates

Installed copies check the GitHub tags for this repository before running the Vencord repair check. When a newer `vX.Y.Z` tag exists, AutoPatch downloads that tagged source archive and replaces its installed script, launcher, and icons in `%LOCALAPPDATA%\VencordAutoPatch`.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## Log File

Logs are saved at:

```text
%LOCALAPPDATA%\VencordAutoRepair\vencord-startup.log
```

## Notes

This project is not affiliated with Discord or Vencord. It downloads the Vencord installer CLI from the official Vencord GitHub release URL used by the script.
