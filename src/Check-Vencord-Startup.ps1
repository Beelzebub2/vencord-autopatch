param(
    [switch]$DryRun,
    [switch]$NoAutoClose,
    [switch]$NoSelfUpdate
)

$ErrorActionPreference = "Continue"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ConsoleWindow {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

$consoleHandle = [ConsoleWindow]::GetConsoleWindow()
if ($consoleHandle -ne [IntPtr]::Zero) {
    [ConsoleWindow]::ShowWindow($consoleHandle, 0) | Out-Null
}

$AppName = "VencordAutoPatch"
$AppDisplayName = "Vencord AutoPatch"
$AppVersion = "1.2.0"
$RepositoryOwner = "Beelzebub2"
$RepositoryName = "vencord-autopatch"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$InstalledScriptPath = Join-Path $InstallDir "Check-Vencord-Startup.ps1"
$InstalledLauncherPath = Join-Path $InstallDir "Launch-Check-Vencord-Startup.vbs"
$InstalledIconPath = Join-Path $InstallDir "icon.ico"
$InstalledIconPngPath = Join-Path $InstallDir "icon.png"
$WorkDir = Join-Path $env:LOCALAPPDATA "VencordAutoRepair"
$LogFile = Join-Path $WorkDir "vencord-startup.log"
$Installer = Join-Path $WorkDir "VencordInstallerCli.exe"

New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase

[xml]$Xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Vencord AutoPatch"
    Width="460"
    Height="315"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    WindowStartupLocation="Manual"
    Background="Transparent"
    Foreground="#F6F8FA"
    FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Height" Value="32" />
            <Setter Property="Padding" Value="14,0" />
            <Setter Property="Foreground" Value="#F7F8FB" />
            <Setter Property="Background" Value="#202A36" />
            <Setter Property="BorderBrush" Value="#344255" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ButtonBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="#2A3544" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="#1B2430" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Border BorderBrush="#273345" BorderThickness="1" Background="#0F141B" CornerRadius="16">
            <Border.Effect>
                <DropShadowEffect Color="#000000" BlurRadius="22" ShadowDepth="0" Opacity="0.42" />
            </Border.Effect>
        </Border>

        <Border BorderBrush="#273345" BorderThickness="1" Background="#0F141B" CornerRadius="16">
        <Grid Margin="24">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="0,0,0,22">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="62" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0" Width="50" Height="50" CornerRadius="14" Background="#151C25" HorizontalAlignment="Left" ClipToBounds="True">
                    <Image x:Name="AppIconImage" Stretch="UniformToFill" />
                </Border>

                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="Vencord AutoPatch" FontSize="21" FontWeight="SemiBold" />
                    <TextBlock Text="Discord update repair" Foreground="#A9B4C2" FontSize="13" Margin="0,4,0,0" />
                </StackPanel>

                <Button x:Name="CloseButton" Grid.Column="2" Content="X" Width="32" Height="32" Padding="0" Background="#151C25" BorderBrush="#2A3546" Foreground="#AEB8C5" VerticalAlignment="Top" />
            </Grid>

            <Border Grid.Row="1" CornerRadius="12" Background="#161D27" BorderBrush="#283548" BorderThickness="1" Padding="18" Margin="0,0,0,18">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="42" />
                        <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>

                    <Border Grid.Row="0" Grid.Column="0" Width="30" Height="30" CornerRadius="15" Background="#1F8F5F" HorizontalAlignment="Left" VerticalAlignment="Top">
                        <Path Data="M8,15 L13,20 L22,9" Stroke="#FFFFFF" StrokeThickness="2.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" />
                    </Border>

                    <StackPanel Grid.Row="0" Grid.Column="1">
                        <TextBlock x:Name="StatusText" Text="Starting..." FontSize="18" FontWeight="SemiBold" />
                        <TextBlock x:Name="DetailText" Text="This will only take a moment." Foreground="#A9B4C2" FontSize="13" Margin="0,6,0,0" TextWrapping="Wrap" />
                    </StackPanel>

                    <ProgressBar Grid.Row="1" Grid.ColumnSpan="2" x:Name="ProgressBar" Height="6" IsIndeterminate="True" Foreground="#5865F2" Background="#263141" BorderThickness="0" Margin="0,18,0,0" />
                </Grid>
            </Border>

            <Grid Grid.Row="2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>

                <TextBlock x:Name="FooterText" Grid.Column="0" Text="Running quietly at startup." Foreground="#7F8B98" FontSize="12" VerticalAlignment="Center" />
                <Button x:Name="OpenLogButton" Grid.Column="1" Content="View log" Width="78" Margin="0,0,8,0" />
                <Button x:Name="DoneButton" Grid.Column="2" Content="Done" Width="72" Background="#5865F2" BorderBrush="#5865F2" />
            </Grid>
        </Grid>
        </Border>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $Xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
$script:StatusText = $script:Window.FindName("StatusText")
$script:DetailText = $script:Window.FindName("DetailText")
$script:ProgressBar = $script:Window.FindName("ProgressBar")
$script:FooterText = $script:Window.FindName("FooterText")
$script:AppIconImage = $script:Window.FindName("AppIconImage")
$script:OpenLogButton = $script:Window.FindName("OpenLogButton")
$script:CloseButton = $script:Window.FindName("CloseButton")
$script:DoneButton = $script:Window.FindName("DoneButton")
$script:HasError = $false
$script:InstalledSomething = $false
$script:SelfUpdated = $false
$script:SelfUpdatedVersion = $null

$iconCandidates = @(
    (Join-Path $PSScriptRoot "icon.png"),
    (Join-Path $PSScriptRoot "..\assets\icon.png"),
    $InstalledIconPngPath,
    (Join-Path $PSScriptRoot "icon.ico"),
    (Join-Path $PSScriptRoot "..\assets\icon.ico"),
    $InstalledIconPath
)

foreach ($iconPath in $iconCandidates) {
    if (Test-Path $iconPath) {
        try {
            $iconUri = [Uri]::new((Resolve-Path $iconPath).Path)
            $script:Window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create($iconUri)
            $script:AppIconImage.Source = [System.Windows.Media.Imaging.BitmapImage]::new($iconUri)
            break
        }
        catch {
        }
    }
}

$script:OpenLogButton.Add_Click({
    if (Test-Path $LogFile) {
        Start-Process -FilePath "notepad.exe" -ArgumentList "`"$LogFile`""
    }
})

$script:CloseButton.Add_Click({
    $script:Window.Close()
})

$script:DoneButton.Add_Click({
    $script:Window.Close()
})

$script:Window.Add_MouseLeftButtonDown({
    if ($_.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
        try {
            $script:Window.DragMove()
        }
        catch {
        }
    }
})

function Sync-Ui {
    $script:Window.Dispatcher.Invoke(
        [Action] {},
        [System.Windows.Threading.DispatcherPriority]::Background
    )
}

function Set-UiStatus {
    param(
        [string]$Status,
        [string]$Detail,
        [string]$Footer
    )

    if ($Status) {
        $script:StatusText.Text = $Status
    }

    if ($Detail) {
        $script:DetailText.Text = $Detail
    }

    if ($Footer) {
        $script:FooterText.Text = $Footer
    }

    Sync-Ui
}

function Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time  $Message"

    Add-Content -Path $LogFile -Value $line

    if ($Level -eq "Error") {
        $script:HasError = $true
    }

    Sync-Ui
}

function Get-StartMenuProgramsPath {
    $startMenuDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)

    if ([string]::IsNullOrWhiteSpace($startMenuDir)) {
        $startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    }

    return $startMenuDir
}

function Update-StartMenuShortcut {
    param(
        [string]$LauncherPath,
        [string]$IconPath
    )

    try {
        $startMenuDir = Get-StartMenuProgramsPath
        $shortcutPath = Join-Path $startMenuDir "$AppDisplayName.lnk"

        New-Item -ItemType Directory -Force -Path $startMenuDir -ErrorAction Stop | Out-Null

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
        $shortcut.Arguments = "`"$LauncherPath`""
        $shortcut.WorkingDirectory = $InstallDir
        $shortcut.Description = "Run Vencord AutoPatch manually"

        if (Test-Path $IconPath) {
            $shortcut.IconLocation = $IconPath
        }

        $shortcut.Save()
        Log "Start Menu shortcut refreshed: $shortcutPath" "Success"
    }
    catch {
        Log "WARNING: Could not refresh the Start Menu shortcut." "Warning"
        Log $_.Exception.Message "Warning"
    }
}

function ConvertTo-SelfUpdateVersion {
    param([string]$TagName)

    if ([string]::IsNullOrWhiteSpace($TagName)) {
        return $null
    }

    $cleanTag = $TagName.Trim()

    if ($cleanTag.StartsWith("v", [StringComparison]::OrdinalIgnoreCase)) {
        $cleanTag = $cleanTag.Substring(1)
    }

    if ($cleanTag -notmatch "^\d+(\.\d+){1,3}$") {
        return $null
    }

    try {
        return [version]$cleanTag
    }
    catch {
        return $null
    }
}

function Test-RunningInstalledCopy {
    try {
        $scriptRootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $PSScriptRoot -ErrorAction Stop).Path).TrimEnd("\")
        $installPath = [System.IO.Path]::GetFullPath($InstallDir).TrimEnd("\")

        return [string]::Equals($scriptRootPath, $installPath, [StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        return $false
    }
}

function Get-LatestSelfUpdate {
    $currentVersion = ConvertTo-SelfUpdateVersion $AppVersion

    if ($null -eq $currentVersion) {
        Log "WARNING: Current AutoPatch version could not be parsed: $AppVersion" "Warning"
        return $null
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    catch {
    }

    try {
        $tagsUrl = "https://api.github.com/repos/$RepositoryOwner/$RepositoryName/tags?per_page=30"
        $headers = @{
            "Accept" = "application/vnd.github+json"
            "User-Agent" = "$AppName/$AppVersion"
        }

        Log "Checking AutoPatch updates from: $tagsUrl"
        $tags = @(Invoke-RestMethod -Uri $tagsUrl -Headers $headers -ErrorAction Stop)

        $updates = foreach ($tag in $tags) {
            $tagVersion = ConvertTo-SelfUpdateVersion $tag.name

            if (($null -ne $tagVersion) -and ($tagVersion -gt $currentVersion)) {
                [pscustomobject]@{
                    Name = $tag.name
                    Version = $tagVersion
                    ZipUrl = $tag.zipball_url
                }
            }
        }

        $updateList = @($updates)

        if ($updateList.Count -eq 0) {
            Log "AutoPatch is up to date: $AppVersion" "Success"
            return $null
        }

        return $updateList | Sort-Object -Property Version -Descending | Select-Object -First 1
    }
    catch {
        Log "WARNING: Could not check for AutoPatch updates." "Warning"
        Log $_.Exception.Message "Warning"
        return $null
    }
}

function Invoke-SelfUpdate {
    if ($NoSelfUpdate) {
        Log "Self-update skipped by -NoSelfUpdate."
        return $false
    }

    if ($DryRun) {
        Log "Dry run enabled. Self-update check skipped." "Warning"
        return $false
    }

    if (!(Test-RunningInstalledCopy)) {
        Log "Self-update skipped because this copy is not running from the install folder: $PSScriptRoot"
        return $false
    }

    Set-UiStatus "Checking for updates" "Looking for a newer AutoPatch release." "This only updates the helper."
    $latestUpdate = Get-LatestSelfUpdate

    if ($null -eq $latestUpdate) {
        return $false
    }

    $updateRoot = Join-Path $WorkDir "self-update"

    try {
        Set-UiStatus "Updating AutoPatch" "Installing $($latestUpdate.Name)." "The Vencord check will continue after update."
        Log "AutoPatch update available: $($latestUpdate.Name) (current: $AppVersion)"

        if (Test-Path $updateRoot) {
            Remove-Item -LiteralPath $updateRoot -Recurse -Force -ErrorAction Stop
        }

        $extractDir = Join-Path $updateRoot "source"
        $zipPath = Join-Path $updateRoot "source.zip"

        New-Item -ItemType Directory -Force -Path $extractDir -ErrorAction Stop | Out-Null
        Invoke-WebRequest -Uri $latestUpdate.ZipUrl -Headers @{ "User-Agent" = "$AppName/$AppVersion" } -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force -ErrorAction Stop

        $sourceRoot = Get-ChildItem -LiteralPath $extractDir -Directory -ErrorAction Stop | Select-Object -First 1

        if ($null -eq $sourceRoot) {
            throw "Downloaded AutoPatch archive did not contain a source folder."
        }

        $filesToInstall = @(
            @{
                Source = Join-Path $sourceRoot.FullName "src\Check-Vencord-Startup.ps1"
                Destination = $InstalledScriptPath
                Label = "startup script"
            },
            @{
                Source = Join-Path $sourceRoot.FullName "src\Launch-Check-Vencord-Startup.vbs"
                Destination = $InstalledLauncherPath
                Label = "launcher"
            },
            @{
                Source = Join-Path $sourceRoot.FullName "assets\icon.ico"
                Destination = $InstalledIconPath
                Label = "icon"
            },
            @{
                Source = Join-Path $sourceRoot.FullName "assets\icon.png"
                Destination = $InstalledIconPngPath
                Label = "UI icon"
            }
        )

        foreach ($file in $filesToInstall) {
            if (!(Test-Path -LiteralPath $file.Source)) {
                throw "Downloaded AutoPatch archive is missing $($file.Label): $($file.Source)"
            }
        }

        foreach ($file in $filesToInstall) {
            Copy-Item -LiteralPath $file.Source -Destination $file.Destination -Force -ErrorAction Stop
            Log "Updated AutoPatch $($file.Label): $($file.Destination)"
        }

        Update-StartMenuShortcut -LauncherPath $InstalledLauncherPath -IconPath $InstalledIconPath

        $script:SelfUpdated = $true
        $script:SelfUpdatedVersion = $latestUpdate.Name
        Log "AutoPatch updated to $($latestUpdate.Name)." "Success"
        return $true
    }
    catch {
        Log "WARNING: AutoPatch self-update failed." "Warning"
        Log $_.Exception.Message "Warning"
        return $false
    }
    finally {
        if (Test-Path $updateRoot) {
            Remove-Item -LiteralPath $updateRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-LatestDiscordApp($discordDir) {
    if (!(Test-Path $discordDir)) {
        return $null
    }

    return Get-ChildItem $discordDir -Directory -Filter "app-*" |
        Sort-Object Name -Descending |
        Select-Object -First 1
}

function Test-VencordPatched($discordDir) {
    $latestApp = Get-LatestDiscordApp $discordDir

    if ($null -eq $latestApp) {
        Log "No Discord app-* folder found in: $discordDir" "Warning"
        return $false
    }

    $patchedMarker = Join-Path $latestApp.FullName "resources\_app.asar"

    Log "Checking patch marker: $patchedMarker"

    return (Test-Path $patchedMarker)
}

function Stop-DiscordProcesses($processNames) {
    foreach ($processName in $processNames) {
        $running = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if ($null -ne $running) {
            Set-UiStatus "Repairing Vencord" "Discord will restart when this is done." "Working quietly in the background."
            Log "Closing running process: $processName"

            try {
                Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
            catch {
                Log "WARNING: Failed to close $processName" "Warning"
                Log $_.Exception.Message "Warning"
            }
        }
    }
}

function Start-Discord($install) {
    try {
        Set-UiStatus "Opening Discord" "Starting Discord again." "Finishing up."
        Log "Trying to open $($install.Name)..."

        $updateExe = Join-Path $install.Path "Update.exe"

        if (Test-Path $updateExe) {
            Log "Starting through Update.exe: $updateExe"
            Start-Process -FilePath $updateExe -ArgumentList "--processStart $($install.ExeName)"
            Log "RESULT: $($install.Name) opened." "Success"
            return
        }

        $latestApp = Get-LatestDiscordApp $install.Path

        if ($null -ne $latestApp) {
            $discordExe = Join-Path $latestApp.FullName $install.ExeName

            if (Test-Path $discordExe) {
                Log "Starting directly: $discordExe"
                Start-Process -FilePath $discordExe
                Log "RESULT: $($install.Name) opened." "Success"
                return
            }
        }

        Log "ERROR: Could not find executable for $($install.Name)." "Error"
    }
    catch {
        Log "ERROR while opening $($install.Name):" "Error"
        Log $_.Exception.Message "Error"
    }
}

function Install-Vencord($install) {
    if ($DryRun) {
        Log "DRY RUN: $($install.Name) is missing Vencord. Repair would run here." "Warning"
        return $false
    }

    try {
        Set-UiStatus "Updating Vencord" "Getting everything ready." "Network access may take a moment."
        Log "Downloading latest VencordInstallerCli.exe..."

        $url = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
        Invoke-WebRequest -Uri $url -OutFile $Installer -UseBasicParsing

        if (!(Test-Path $Installer)) {
            Log "ERROR: Installer download failed. File was not created." "Error"
            return $false
        }

        Set-UiStatus "Repairing Vencord" "Applying the startup fix." "Discord may close briefly."
        Log "Closing Discord before patching..."
        Stop-DiscordProcesses $install.ProcessNames

        Log "Running Vencord repair/install for branch: $($install.Branch)"
        Log "Installer path: $Installer"

        & $Installer -repair -branch $install.Branch

        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Log "Vencord installer finished successfully." "Success"

            Start-Sleep -Seconds 2

            if (Test-VencordPatched $install.Path) {
                Log "RESULT: Patch confirmed after install." "Success"
                Start-Discord $install
                return $true
            }
            else {
                Log "WARNING: Installer finished, but patch marker was still not found." "Warning"
                Start-Discord $install
                return $true
            }
        }
        else {
            Log "ERROR: Vencord installer exited with code: $exitCode" "Error"
            return $false
        }
    }
    catch {
        Log "ERROR while installing Vencord:" "Error"
        Log $_.Exception.Message "Error"
        return $false
    }
}

function Invoke-VencordStartupCheck {
    $DiscordInstalls = @(
        @{
            Name = "Discord"
            Branch = "stable"
            Path = Join-Path $env:LOCALAPPDATA "Discord"
            ExeName = "Discord.exe"
            ProcessNames = @("Discord")
        },
        @{
            Name = "Discord PTB"
            Branch = "ptb"
            Path = Join-Path $env:LOCALAPPDATA "DiscordPTB"
            ExeName = "DiscordPTB.exe"
            ProcessNames = @("DiscordPTB")
        },
        @{
            Name = "Discord Canary"
            Branch = "canary"
            Path = Join-Path $env:LOCALAPPDATA "DiscordCanary"
            ExeName = "DiscordCanary.exe"
            ProcessNames = @("DiscordCanary")
        }
    )

    Log "=============================="
    Log "Vencord startup check started."
    Log "AutoPatch version: $AppVersion"
    Log "Running as user: $env:USERNAME"
    Log "LocalAppData: $env:LOCALAPPDATA"
    Log "Log file: $LogFile"
    if ($DryRun) {
        Log "Dry run enabled. No repair/install action will be performed." "Warning"
    }
    Log "=============================="

    Invoke-SelfUpdate | Out-Null

    $foundDiscord = $false

    foreach ($install in $DiscordInstalls) {
        Set-UiStatus "Checking Discord" "Making sure Vencord is ready." "Running quietly at startup."
        Log "Checking $($install.Name)..."
        Log "Path: $($install.Path)"

        if (!(Test-Path $install.Path)) {
            Log "$($install.Name) is not installed. Skipping."
            continue
        }

        $foundDiscord = $true

        if (Test-VencordPatched $install.Path) {
            Log "RESULT: $($install.Name) already has Vencord patched." "Success"
            continue
        }

        Log "RESULT: $($install.Name) is missing Vencord. Reinstalling..." "Warning"
        $success = Install-Vencord $install

        if ($success) {
            $script:InstalledSomething = $true
        }
    }

    if ($foundDiscord -eq $false) {
        Log "RESULT: No Discord install was found." "Warning"
    }

    if ($script:InstalledSomething -eq $false) {
        Log "RESULT: Nothing needed to be installed." "Success"
    }

    Log "Vencord startup check finished."
    Log "=============================="
}

function Complete-Ui {
    $script:ProgressBar.IsIndeterminate = $false
    $script:ProgressBar.Value = 100

    if ($script:HasError) {
        Set-UiStatus "Needs attention" "The check could not finish cleanly." "Open the log for details."
        return
    }

    if ($script:InstalledSomething) {
        if ($script:SelfUpdated) {
            Set-UiStatus "Ready" "Vencord was repaired and AutoPatch was updated." "Completed successfully."
        }
        else {
            Set-UiStatus "Ready" "Vencord was repaired successfully." "Completed successfully."
        }
    }
    elseif ($DryRun) {
        Set-UiStatus "Preview complete" "No changes were made." "Completed successfully."
    }
    elseif ($script:SelfUpdated) {
        Set-UiStatus "Ready" "AutoPatch updated to $($script:SelfUpdatedVersion)." "This window will close automatically."
    }
    else {
        Set-UiStatus "Ready" "Vencord is already set up." "This window will close automatically."
    }

    if (!$NoAutoClose) {
        $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
        $closeTimer.Interval = [TimeSpan]::FromSeconds(4)
        $closeTimer.Add_Tick({
            $this.Stop()
            $script:Window.Close()
        })
        $closeTimer.Start()
    }
}

$startupTimer = New-Object System.Windows.Threading.DispatcherTimer
$startupTimer.Interval = [TimeSpan]::FromMilliseconds(250)
$startupTimer.Add_Tick({
    $this.Stop()

    try {
        Invoke-VencordStartupCheck
    }
    catch {
        Log "ERROR: Unexpected startup check failure." "Error"
        Log $_.Exception.Message "Error"
    }
    finally {
        Complete-Ui
    }
})

$startupTimer.Start()
$primaryWorkArea = [System.Windows.SystemParameters]::WorkArea
$script:Window.Left = $primaryWorkArea.Left + (($primaryWorkArea.Width - $script:Window.Width) / 2)
$script:Window.Top = $primaryWorkArea.Top + (($primaryWorkArea.Height - $script:Window.Height) / 2)
[void]$script:Window.ShowDialog()
