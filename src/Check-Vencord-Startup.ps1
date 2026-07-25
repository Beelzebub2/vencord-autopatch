param(
    [switch]$DryRun,
    [switch]$NoAutoClose,
    [switch]$NoSelfUpdate,
    [switch]$Manual,
    [switch]$AutoUpdate
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
$AppVersion = "1.5.2"
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
    Width="500"
    Height="350"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    WindowStartupLocation="Manual"
    Opacity="0"
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

    <Grid x:Name="RootGrid" Margin="10">
        <Grid.RenderTransform>
            <TranslateTransform Y="12" />
        </Grid.RenderTransform>

        <Border CornerRadius="18" Background="#0B1118">
            <Border.Effect>
                <DropShadowEffect Color="#000000" BlurRadius="28" ShadowDepth="0" Opacity="0.48" />
            </Border.Effect>
        </Border>

        <Border x:Name="MainCard" BorderBrush="#2F4058" BorderThickness="1" CornerRadius="18">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#151C25" Offset="0" />
                    <GradientStop Color="#0F141B" Offset="0.58" />
                    <GradientStop Color="#111821" Offset="1" />
                </LinearGradientBrush>
            </Border.Background>

        <Grid Margin="24">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="0,0,0,20">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="62" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="Auto" />
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0" Width="50" Height="50" CornerRadius="14" Background="#151C25" BorderBrush="#344255" BorderThickness="1" HorizontalAlignment="Left" ClipToBounds="True">
                    <Image x:Name="AppIconImage" Stretch="UniformToFill" />
                </Border>

                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="Vencord AutoPatch" FontSize="21" FontWeight="SemiBold" />
                    <TextBlock Text="Discord update repair" Foreground="#A9B4C2" FontSize="13" Margin="0,4,0,0" />
                </StackPanel>

                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Top" Margin="0,0,10,0">
                    <Border CornerRadius="9" Background="#1A2431" BorderBrush="#2D3B4E" BorderThickness="1" Padding="9,4" Margin="0,0,6,0">
                        <TextBlock x:Name="LaunchModeText" Text="Startup check" FontSize="11" Foreground="#B5C1D0" />
                    </Border>
                    <Border CornerRadius="9" Background="#1B2340" BorderBrush="#33407A" BorderThickness="1" Padding="9,4">
                        <TextBlock x:Name="VersionText" Text="v0.0.0" FontSize="11" Foreground="#AEB7FF" />
                    </Border>
                </StackPanel>

                <Button x:Name="CloseButton" Grid.Column="3" Content="X" Width="32" Height="32" Padding="0" Background="#151C25" BorderBrush="#2A3546" Foreground="#AEB8C5" VerticalAlignment="Top" />
            </Grid>

            <Border x:Name="StatusCard" Grid.Row="1" CornerRadius="14" Background="#161D27" BorderBrush="#283548" BorderThickness="1" Padding="18" Margin="0,0,0,18">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="54" />
                        <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>

                    <Border x:Name="StatusBadge" Grid.Row="0" Grid.Column="0" Width="38" Height="38" CornerRadius="19" Background="#5865F2" HorizontalAlignment="Left" VerticalAlignment="Top">
                        <Grid>
                            <Ellipse x:Name="StatusPulse" Width="38" Height="38" Stroke="#7C83FF" StrokeThickness="2" Opacity="0.35" />
                            <Path x:Name="StatusIcon" Data="M10,19 L16,25 L28,11" Stroke="#FFFFFF" StrokeThickness="2.6" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" />
                        </Grid>
                    </Border>

                    <StackPanel Grid.Row="0" Grid.Column="1">
                        <TextBlock x:Name="StatusText" Text="Starting..." FontSize="19" FontWeight="SemiBold" />
                        <TextBlock x:Name="DetailText" Text="This will only take a moment." Foreground="#A9B4C2" FontSize="13" Margin="0,6,0,0" TextWrapping="Wrap" />
                    </StackPanel>

                    <ProgressBar Grid.Row="1" Grid.ColumnSpan="2" x:Name="ProgressBar" Height="7" IsIndeterminate="True" Background="#263141" BorderThickness="0" Margin="0,18,0,0">
                        <ProgressBar.Foreground>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                <GradientStop Color="#5865F2" Offset="0" />
                                <GradientStop Color="#7C83FF" Offset="0.55" />
                                <GradientStop Color="#33D69F" Offset="1" />
                            </LinearGradientBrush>
                        </ProgressBar.Foreground>
                    </ProgressBar>

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
$script:RootGrid = $script:Window.FindName("RootGrid")
$script:StatusText = $script:Window.FindName("StatusText")
$script:DetailText = $script:Window.FindName("DetailText")
$script:ProgressBar = $script:Window.FindName("ProgressBar")
$script:FooterText = $script:Window.FindName("FooterText")
$script:AppIconImage = $script:Window.FindName("AppIconImage")
$script:LaunchModeText = $script:Window.FindName("LaunchModeText")
$script:VersionText = $script:Window.FindName("VersionText")
$script:StatusCard = $script:Window.FindName("StatusCard")
$script:StatusBadge = $script:Window.FindName("StatusBadge")
$script:StatusPulse = $script:Window.FindName("StatusPulse")
$script:StatusIcon = $script:Window.FindName("StatusIcon")
$script:OpenLogButton = $script:Window.FindName("OpenLogButton")
$script:CloseButton = $script:Window.FindName("CloseButton")
$script:DoneButton = $script:Window.FindName("DoneButton")
$script:HasError = $false
$script:InstalledSomething = $false
$script:SelfUpdated = $false
$script:SelfUpdatedVersion = $null
$script:IsClosing = $false

$script:VersionText.Text = "v$AppVersion"

if ($Manual) {
    $script:LaunchModeText.Text = "Manual check"
}
elseif ($DryRun) {
    $script:LaunchModeText.Text = "Dry run"
}
else {
    $script:LaunchModeText.Text = "Startup check"
}

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

function New-UiBrush {
    param([string]$Color)

    $converter = New-Object System.Windows.Media.BrushConverter
    return $converter.ConvertFromString($Color)
}

function Start-UiAnimation {
    try {
        $fade = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fade.From = 0
        $fade.To = 1
        $fade.Duration = [TimeSpan]::FromMilliseconds(240)
        $script:Window.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fade)

        $slide = New-Object System.Windows.Media.Animation.DoubleAnimation
        $slide.From = 12
        $slide.To = 0
        $slide.Duration = [TimeSpan]::FromMilliseconds(280)
        $slide.EasingFunction = New-Object System.Windows.Media.Animation.CubicEase -Property @{ EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut }
        $script:RootGrid.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slide)

        $pulse = New-Object System.Windows.Media.Animation.DoubleAnimation
        $pulse.From = 0.20
        $pulse.To = 0.85
        $pulse.Duration = [TimeSpan]::FromMilliseconds(900)
        $pulse.AutoReverse = $true
        $pulse.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $script:StatusPulse.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $pulse)
    }
    catch {
    }
}

function Animate-StatusRefresh {
    try {
        $fade = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fade.From = 0.72
        $fade.To = 1
        $fade.Duration = [TimeSpan]::FromMilliseconds(180)
        $script:StatusCard.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fade)
    }
    catch {
    }
}

function Set-UiTone {
    param([string]$Tone = "Info")

    $accent = "#5865F2"
    $pulse = "#7C83FF"
    $iconData = "M10,19 L16,25 L28,11"

    switch ($Tone) {
        "Success" {
            $accent = "#1F8F5F"
            $pulse = "#33D69F"
            $iconData = "M10,19 L16,25 L28,11"
        }
        "Warning" {
            $accent = "#A46A16"
            $pulse = "#F2B84B"
            $iconData = "M19,8 L30,28 H8 Z M19,15 V21 M19,25 V26"
        }
        "Error" {
            $accent = "#B63B3B"
            $pulse = "#FF6B6B"
            $iconData = "M11,11 L27,27 M27,11 L11,27"
        }
        "Update" {
            $accent = "#5865F2"
            $pulse = "#9AA2FF"
            $iconData = "M20,9 A10,10 0 1 1 11,14 M20,9 V16 H27"
        }
    }

    try {
        $accentBrush = New-UiBrush $accent
        $pulseBrush = New-UiBrush $pulse
        $script:StatusBadge.Background = $accentBrush
        $script:StatusPulse.Stroke = $pulseBrush
        $script:ProgressBar.Foreground = $accentBrush
        $script:StatusIcon.Data = [System.Windows.Media.Geometry]::Parse($iconData)
    }
    catch {
    }
}

function Close-AppWindow {
    if ($script:IsClosing) {
        return
    }

    $script:IsClosing = $true

    try {
        $fade = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fade.To = 0
        $fade.Duration = [TimeSpan]::FromMilliseconds(150)
        $fade.Add_Completed({
            $script:Window.Close()
        })

        $script:Window.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fade)
    }
    catch {
        $script:Window.Close()
    }
}

$script:OpenLogButton.Add_Click({
    if (Test-Path $LogFile) {
        Start-Process -FilePath "notepad.exe" -ArgumentList "`"$LogFile`""
    }
})

$script:CloseButton.Add_Click({
    Close-AppWindow
})

$script:DoneButton.Add_Click({
    Close-AppWindow
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
        [string]$Footer,
        [ValidateSet("Info", "Success", "Warning", "Error", "Update")]
        [string]$Tone = "Info"
    )

    Set-UiTone $Tone

    if ($Status) {
        $script:StatusText.Text = $Status
    }

    if ($Detail) {
        $script:DetailText.Text = $Detail
    }

    if ($Footer) {
        $script:FooterText.Text = $Footer
    }

    Animate-StatusRefresh
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

function Get-StartupFolderPath {
    $startupDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)

    if ([string]::IsNullOrWhiteSpace($startupDir)) {
        $startupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    }

    return $startupDir
}

function Update-StartMenuShortcut {
    param(
        [string]$LauncherPath,
        [string]$IconPath,
        [string]$LauncherArguments = "-Manual"
    )

    try {
        $startMenuDir = Get-StartMenuProgramsPath
        $shortcutPath = Join-Path $startMenuDir "$AppDisplayName.lnk"

        New-Item -ItemType Directory -Force -Path $startMenuDir -ErrorAction Stop | Out-Null

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
        $shortcut.Arguments = "`"$LauncherPath`" $LauncherArguments"
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

function Update-StartupShortcut {
    param(
        [string]$LauncherPath,
        [string]$IconPath
    )

    try {
        $startupDir = Get-StartupFolderPath
        $shortcutPath = Join-Path $startupDir "$AppDisplayName.lnk"

        if (!(Test-Path -LiteralPath $shortcutPath)) {
            return
        }

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $env:WINDIR "System32\wscript.exe"
        $shortcut.Arguments = "`"$LauncherPath`" -AutoUpdate"
        $shortcut.WorkingDirectory = $InstallDir
        $shortcut.Description = "Run Vencord AutoPatch at Windows startup"

        if (Test-Path $IconPath) {
            $shortcut.IconLocation = $IconPath
        }

        $shortcut.Save()
        Log "Startup shortcut refreshed: $shortcutPath" "Success"
    }
    catch {
        Log "WARNING: Could not refresh the Startup folder shortcut." "Warning"
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

    Set-UiStatus "Checking for updates" "Looking for a newer AutoPatch release." "This only updates the helper." "Update"
    $latestUpdate = Get-LatestSelfUpdate

    if ($null -eq $latestUpdate) {
        return $false
    }

    if (!$AutoUpdate) {
        Set-UiStatus "Update available" "AutoPatch $($latestUpdate.Name) is ready to install." "Waiting for your choice." "Update"
        Log "AutoPatch update available. Asking before install: $($latestUpdate.Name) (current: $AppVersion)"

        try {
            $script:Window.Activate() | Out-Null
        }
        catch {
        }

        $message = "AutoPatch $($latestUpdate.Name) is available.`n`nCurrent version: $AppVersion`n`nDo you want to install it now?"
        $choice = [System.Windows.MessageBox]::Show(
            $script:Window,
            $message,
            "Vencord AutoPatch Update",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )

        if ($choice -ne [System.Windows.MessageBoxResult]::Yes) {
            Log "AutoPatch update skipped by user."
            Set-UiStatus "Checking Discord" "Update skipped. Checking Vencord now." "Running manual check." "Info"
            return $false
        }

        Log "User accepted AutoPatch update: $($latestUpdate.Name)"
    }
    else {
        Log "Auto-update launch enabled. Installing AutoPatch update without prompting."
    }

    $updateRoot = Join-Path $WorkDir "self-update"

    try {
        Set-UiStatus "Updating AutoPatch" "Installing $($latestUpdate.Name)." "The Vencord check will continue after update." "Update"
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
        Update-StartupShortcut -LauncherPath $InstalledLauncherPath -IconPath $InstalledIconPath

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
            Set-UiStatus "Repairing Vencord" "Discord will restart when this is done." "Working quietly in the background." "Warning"
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
        Set-UiStatus "Updating Vencord" "Getting everything ready." "Network access may take a moment." "Update"
        Log "Downloading latest VencordInstallerCli.exe..."

        $url = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
        Invoke-WebRequest -Uri $url -OutFile $Installer -UseBasicParsing

        if (!(Test-Path $Installer)) {
            Log "ERROR: Installer download failed. File was not created." "Error"
            return $false
        }

        Set-UiStatus "Repairing Vencord" "Applying the startup fix." "Discord may close briefly." "Warning"
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
    if ($AutoUpdate) {
        Log "Auto-update launch enabled. AutoPatch updates can install without prompting."
    }
    else {
        Log "Interactive update mode enabled. AutoPatch updates will ask before installing."
    }
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
        Set-UiStatus "Checking Discord" "Making sure Vencord is ready." "Running quietly at startup." "Info"
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

    try {
        $progressAnimation = New-Object System.Windows.Media.Animation.DoubleAnimation
        $progressAnimation.From = [double]$script:ProgressBar.Value
        $progressAnimation.To = 100
        $progressAnimation.Duration = [TimeSpan]::FromMilliseconds(260)
        $script:ProgressBar.BeginAnimation([System.Windows.Controls.Primitives.RangeBase]::ValueProperty, $progressAnimation)
    }
    catch {
        $script:ProgressBar.Value = 100
    }

    if ($script:HasError) {
        Set-UiStatus "Needs attention" "The check could not finish cleanly." "Open the log for details." "Error"
        return
    }

    if ($script:InstalledSomething) {
        if ($script:SelfUpdated) {
            Set-UiStatus "Ready" "Vencord was repaired and AutoPatch was updated." "Completed successfully." "Success"
        }
        else {
            Set-UiStatus "Ready" "Vencord was repaired successfully." "Completed successfully." "Success"
        }
    }
    elseif ($DryRun) {
        Set-UiStatus "Preview complete" "No changes were made." "Completed successfully." "Success"
    }
    elseif ($script:SelfUpdated) {
        Set-UiStatus "Ready" "AutoPatch updated to $($script:SelfUpdatedVersion)." "This window will close automatically." "Success"
    }
    else {
        Set-UiStatus "Ready" "Vencord is already set up." "This window will close automatically." "Success"
    }

    if (!$NoAutoClose) {
        $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
        $closeTimer.Interval = [TimeSpan]::FromSeconds(4)
        $closeTimer.Add_Tick({
            $this.Stop()
            Close-AppWindow
        })
        $closeTimer.Start()
    }
}

$script:Window.Add_Loaded({
    Start-UiAnimation
})

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
