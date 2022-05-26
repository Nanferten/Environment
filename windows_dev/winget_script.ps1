# 1. Make sure the Microsoft App Installer is installed:
#    https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1
# 2. Edit the list of apps to install.
# 3. Run this script as administrator.

Write-Output "Installing Apps"

$apps =  Get-Content -Path .\winget_apps.txt

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