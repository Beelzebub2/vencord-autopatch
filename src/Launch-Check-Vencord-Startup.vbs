Set shell = CreateObject("WScript.Shell")
scriptPath = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\VencordAutoPatch\Check-Vencord-Startup.ps1"
extraArgs = ""

For i = 0 To WScript.Arguments.Count - 1
    extraArgs = extraArgs & " " & WScript.Arguments(i)
Next

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File " & Chr(34) & scriptPath & Chr(34) & extraArgs
shell.Run command, 0, False
