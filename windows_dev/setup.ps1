if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

function Check-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# -----------------------------------------------------------------------------
# Set a new computer name
# $computerName = Read-Host 'Enter New Computer Name'
# Write-Host "Renaming this computer to: " $computerName  -ForegroundColor Yellow
# Rename-Computer -NewName $computerName

# -----------------------------------------------------------------------------
# Remove a few pre-installed UWP applications
# To list all appx packages:
# Get-AppxPackage | Format-Table -Property Name,Version,PackageFullName
Write-Host "Removing UWP Rubbish..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
$uwpRubbishApps = @(
    "king.com.CandyCrushFriends",
    "Microsoft.3DBuilder",
    "Microsoft.Print3D",
    "Microsoft.BingNews",
    "Microsoft.OneConnect",
    "Microsoft.Microsoft3DViewer",
    "HolographicFirstRun",
    "Microsoft.MixedReality.Portal"
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.Getstarted",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.XboxApp",
    "Fitbit.FitbitCoach",
    "4DF9E0F8.Netflix")

foreach ($uwp in $uwpRubbishApps) {
    Get-AppxPackage -Name $uwp | Remove-AppxPackage
}

# -----------------------------------------------------------------------------
# Check for winget
if (Check-Command -cmdname 'winget') {
    Write-Host "Winget is already installed, skip installation."
}
else {
    Write-Host "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
  
# ------------------------------------------------------------------------------
# Manage windows optional features
Dism /online /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux /All
Dism /online /Enable-Feature /FeatureName:VirtualMachinePlatform /All

Dism /online /Disable-Feature /FeatureName:Printing-XPSServices-Features 

# ------------------------------------------------------------------------------
# Setup application to be installed by default

# 1. Make sure the Microsoft App Installer is installed:
#    https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1
# 2. Edit the list of apps to install.
# 3. Run this script as administrator.

Write-Output "Installing Apps"

$apps = Get-Content -Path .\winget_apps.txt

Foreach ($app in $apps) {
    Write-host "Trying to install " $app
    $listApp = winget list --exact -q $app
    if (![String]::Join("", $listApp).Contains($app)) {
        Write-host "Installing: " $app
        winget install -e -h --accept-source-agreements --accept-package-agreements --id $app 
    }
    else {
        Write-host "Skipping: " $app " (already installed)"
    }
}

# ------------------------------------------------------------------------------
# Setup shell environment
#github url to download zip file
#Assign zip file url to local variable
$Url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip"
$DownloadZipFile = "$HOME\Downloads\" + $(Split-Path -Path $Url -Leaf)
$ExtractPath = "$HOME\Downloads\CascadiaCode\"
New-Item -ItemType Directory -Path $ExtractPath -Force
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile
$ExtractShell = New-Object -ComObject Shell.Application 
$ExtractFiles = $ExtractShell.Namespace($DownloadZipFile).Items() 
$ExtractShell.NameSpace($ExtractPath).CopyHere($ExtractFiles) 

function Install-Font {
	
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [System.IO.FileInfo[]]
        $FontFile,
		
        [switch]
        $WhatIf
    )
	
    begin {
        $shell = New-Object -ComObject 'Shell.Application';
    }
	
    process {
        foreach ( $file in $FontFile ) {
            if ( $WhatIf ) {
                Write-Host -Message(
                    'Installing font "{0}".' -f $file.Name
                );
            }
            else {
                $shell.NameSpace(
                    $file.Directory.FullName
                ).ParseName(
                    $file.Name
                ).Verbs() | ForEach-Object {
                    if ( $_.Name -eq 'Install for &all users' ) {
                        $_.DoIt();
                    }
                };
            }
        }
    }
}

# Run this as a Computer Startup script to allow installing fonts from C:\InstallFont\
# Based on http://www.edugeek.net/forums/windows-7/123187-installation-fonts-without-admin-rights-2.html
# Run this as a Computer Startup Script in Group Policy

# Full details on my website - https://mediarealm.com.au/articles/windows-font-install-no-password-powershell/

$FontItem = Get-Item -Path $ExtractPath
$FontList = Get-ChildItem -Path "$FontItem\*" -Include ('*.fon', '*.otf', '*.ttc', '*.ttf')
  
Install-Font ($FontList)

Remove-Item -Recurse -Force -Path $ExtractPath

Install-Module posh-git -Scope CurrentUser

 # Copy Powershell profile to destination
Copy-Item -Path ./../dotfiles/Microsoft.PowerShell_profile.ps1 -Destination $PSHOME\Microsoft.PowerShell_profile.ps1

&.\vscode_extensions.ps1