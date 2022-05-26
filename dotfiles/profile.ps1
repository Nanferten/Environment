#-----------------------------------------------------------------
### PowerShell template profile 
### Version 1.03 - Tim Sneath <tim@sneath.org>
### From https://gist.github.com/timsneath/19867b12eee7fd5af2ba
# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If so and the current host is a command line, then change to red color 
# as warning to user that they are operating in an elevated context
if (($host.Name -match "ConsoleHost") -and ($isAdmin))
{
     $host.UI.RawUI.BackgroundColor = "DarkRed"
     $host.PrivateData.ErrorBackgroundColor = "White"
     $host.PrivateData.ErrorForegroundColor = "DarkRed"
     Clear-Host
}

# Useful shortcuts for traversing directories
function cd...  { cd ..\.. }
function cd.... { cd ..\..\.. }

# Compute file hashes - useful for checking successful downloads 
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n      { notepad $args }

# Drive shortcuts
function HKLM:  { Set-Location HKLM: }
function HKCU:  { Set-Location HKCU: }
function Env:   { Set-Location Env: }

# Creates drive shortcut for Work Folders, if current user account is using it
if (Test-Path "$env:USERPROFILE\Work Folders")
{
    New-PSDrive -Name Work -PSProvider FileSystem -Root "$env:USERPROFILE\Work Folders" -Description "Work Folders"
    function Work: { Set-Location Work: }
}

# Creates drive shortcut for OneDrive, if current user account is using it
if (Test-Path HKCU:\SOFTWARE\Microsoft\OneDrive)
{
    $onedrive = Get-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\OneDrive
    if (Test-Path $onedrive.UserFolder)
    {
        New-PSDrive -Name OneDrive -PSProvider FileSystem -Root $onedrive.UserFolder -Description "OneDrive"
        function OneDrive: { Set-Location OneDrive: }
    }
    Remove-Variable onedrive
}

# Set up command prompt and window title. Use UNIX-style convention for identifying 
# whether user is elevated (root) or not. Window title shows current version of PowerShell
# and appends [ADMIN] if appropriate for easy taskbar identification
function prompt 
{ 
    if ($isAdmin) 
    {
        "[" + (Get-Location) + "] # " 
    }
    else 
    {
        "[" + (Get-Location) + "] $ "
    }
}

$Host.UI.RawUI.WindowTitle = "PowerShell {0}" -f $PSVersionTable.PSVersion.ToString()
if ($isAdmin)
{
    $Host.UI.RawUI.WindowTitle += " [ADMIN]"
}

# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs
{
    if ($args.Count -gt 0)
    {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    }
    else
    {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

# Simple function to start a new elevated process. If arguments are supplied then 
# a single command is started with admin rights; if not then a new admin instance
# of PowerShell is started.
function admin
{
    if ($args.Count -gt 0)
    {   
       $argList = "& '" + $args + "'"
       Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $argList
    }
    else
    {
       Start-Process "$psHome\powershell.exe" -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin


# Make it easy to edit this profile once it's installed
function Edit-Profile
{
    if ($host.Name -match "ise")
    {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    }
    else
    {
        notepad $profile.CurrentUserAllHosts
    }
}

# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable identity
Remove-Variable principal

# -----------------------------------------------------------------

oh-my-posh --init --shell pwsh --config ~/.mytheme.omp.json | Invoke-Expression

Import-Module posh-git

Register-ArgumentCompleter -Native -CommandName nuke -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        nuke :complete "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}