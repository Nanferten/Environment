#github url to download zip file
#Assign zip file url to local variable
$Url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip"
$DownloadZipFile = "$HOME\Downloads\" + $(Split-Path -Path $Url -Leaf)
$ExtractPath = "$HOME\Downloads\CascadiaCode\"
mkdir $ExtractPath
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile
$ExtractShell = New-Object -ComObject Shell.Application 
$ExtractFiles = $ExtractShell.Namespace($DownloadZipFile).Items() 
$ExtractShell.NameSpace($ExtractPath).CopyHere($ExtractFiles) 
Start-Process $ExtractPath

# Run this as a Computer Startup script to allow installing fonts from C:\InstallFont\
# Based on http://www.edugeek.net/forums/windows-7/123187-installation-fonts-without-admin-rights-2.html
# Run this as a Computer Startup Script in Group Policy

# Full details on my website - https://mediarealm.com.au/articles/windows-font-install-no-password-powershell/

$FONTS = 0x14
$Path="$HOME\Downloads\CascadiaCode\"
$FontItem = Get-Item -Path $Path
$FontList = Get-ChildItem -Path "$FontItem\*" -Include ('*.fon','*.otf','*.ttc','*.ttf')
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)
$Fontdir = dir $Path
$username = $env:UserName
  
foreach($File in $FontList) {
    if(!($file.name -match "pfb$"))
    {
        $try = $true
        $installedFonts = @(Get-ChildItem C:\Users\$username\AppData\Local\Microsoft\Windows\Fonts | Where-Object {$_.PSIsContainer -eq $false} | Select-Object basename)
        $name = $File.baseName
    
        foreach($font in $installedFonts)
        {
            $font = $font -replace "_", ""
            $name = $name -replace "_", ""
            if ($font -match $name)
            {
                $try = $false
            }
        }
        if ($try)
        {
            $objFolder.CopyHere($File.fullname)
        }
    }
}