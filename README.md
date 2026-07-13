<p align="center">
  <img src="assets/banner.png" alt="Vencord Startup Check banner" width="100%">
</p>

<h1 align="center">Vencord Startup Check</h1>

<p align="center">
  <img src="assets/icon.png" alt="Icon" width="96" height="96">
</p>

<p align="center">
  A small Windows startup helper that checks whether Discord is still patched with Vencord and quietly repairs it if needed.
</p>

## Why

Discord updates can sometimes remove the Vencord patch. This helper runs at logon, checks Discord stable/PTB/Canary, and only opens a small friendly status window instead of a suspicious-looking console.

## What It Does

- Checks detected Discord installs on startup
- Verifies the Vencord patch marker
- Downloads the official Vencord installer CLI when repair is needed
- Closes and reopens Discord during repair
- Uses a simple WPF UI instead of a console window
- Writes detailed logs locally for troubleshooting

## Install

Run PowerShell from this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer copies the scripts to:

```text
%LOCALAPPDATA%\VencordStartupCheck
```

and creates a startup task named:

```text
Check Vencord on Startup
```

## Run Manually

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
