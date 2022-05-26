# 1. Make sure Visual studio is installed
# 2. Edit the list of apps to install.
# 3. Run this script as administrator.

Write-Output "Installing Apps"

$apps =  Get-Content -Path .\vscode_extensions.txt

Foreach ($app in $apps) {
    Write-host "Trying to install " $app
    
    code --install-extension $app
}