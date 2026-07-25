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
- Uses a simple WPF status UI instead of a console window
- Adds a Start Menu shortcut so Windows Search can launch it manually
- Writes detailed logs locally for troubleshooting

## Search Keywords

Vencord AutoPatch, Vencord auto repair, Vencord startup check, Vencord Windows startup, Discord Vencord repair, Discord update removed Vencord, Vencord installer CLI, Discord client mod repair, Vencord patch checker, no-console PowerShell startup UI.

## Install

Run PowerShell from this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer copies the scripts to:

```text
%LOCALAPPDATA%\VencordAutoPatch
```

and creates a startup task plus a Start Menu shortcut named:

```text
Vencord AutoPatch
```

## Run Manually

After installing, open the Windows search menu and search for:

```text
Vencord AutoPatch
```

You can also run it directly from the source checkout:

```powershell
powershell -ExecutionPolicy Bypass -STA -File .\src\Check-Vencord-Startup.ps1
```

Preview without making changes:

```powershell
powershell -ExecutionPolicy Bypass -STA -File .\src\Check-Vencord-Startup.ps1 -DryRun
```

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
