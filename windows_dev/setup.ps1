if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Write-Host "Script has to executed in an evelated shell!" -ForegroundColor Red; exit;
}

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


  
# ------------------------------------------------------------------------------
# Manage windows optional features
Dism /online /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux /All
Dism /online /Enable-Feature /FeatureName:VirtualMachinePlatform /All

Dism /online /Disable-Feature /FeatureName:Printing-XPSServices-Features 

# -----------------------------------------------------------------------------
# Check for winget
if (!(Check-Command -cmdname 'winget')) {
    Write-Host "No winget installation found!" -ForegroundColor Red
    Write-Host "Skipping installation of packages" -ForegroundColor Yellow
}
else {
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

$FontItem = Get-Item -Path $ExtractPath
$FontList = Get-ChildItem -Path "$FontItem\*" -Include ('*.fon', '*.otf', '*.ttc', '*.ttf')
  
Install-Font ($FontList)

Remove-Item -Recurse -Force -Path $ExtractPath

Install-Module posh-git -Scope CurrentUser

# Copy Powershell profile to destination
Copy-Item -Path ./../dotfiles/profile.ps1 -Destination $PSHOME\Microsoft.PowerShell_profile.ps1