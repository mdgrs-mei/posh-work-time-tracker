Import-Module $PSScriptRoot\PoshTaskbarItem\PoshTaskbarItem -Force
Add-Type -AssemblyName System.Windows.Forms

function Main()
{
    $rootFolder = GetFolderPath 'Pick a folder to store log and config files (The default is your user folder).' $env:USERPROFILE
    if (-not $rootFolder)
    {
        return
    }
    
    $logFolder = Join-Path $rootFolder 'posh_work_time_tracker'
    if (-not (Test-Path $logFolder))
    {
        New-Item -Path $logFolder -ItemType Directory
    }
    
    & $PSScriptRoot\show_config_window.ps1 $logFolder
    
    $shortcutPath = GetOutputFilePath 'Specify the shortcut file location (The default is your Startup folder).' '.lnk' 'Shortcut File|*.lnk' 'shell:startup' 'posh_work_time_tracker.lnk'
    if (-not $shortcutPath)
    {
        return
    }
    
    $trackerPath = "$PSScriptRoot\posh_work_time_tracker.ps1"
    $shortcutArgs = @{
        Path = $shortcutPath
        IconResourcePath = 'imageres.dll'
        IconResourceIndex = 96
        TargetPath = 'powershell.exe'
        Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" "{1}"' -f $trackerPath, $logFolder
        WindowStyle = 'Minimized'
    }
    
    New-TaskbarItemShortcut @shortcutArgs
}

function GetFolderPath($title, $defaultFolder)
{
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $title
    $dialog.SelectedPath = $defaultFolder
    $dialog.ShowNewFolderButton = $true

    $ret = $dialog.ShowDialog()
    if ($ret -eq [System.Windows.Forms.DialogResult]::OK)
    {
        return $dialog.SelectedPath
    }
    return ''
}

function GetOutputFilePath($title, $ext, $filter, $defaultFolder, $defaultFileName)
{
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = $title
    $dialog.DefaultExt = $ext
    $dialog.Filter = $filter
    $dialog.InitialDirectory = $defaultFolder
    $dialog.FileName = $defaultFileName
    $ret = $dialog.ShowDialog()
    if ($ret -eq [System.Windows.Forms.DialogResult]::OK)
    {
        return $dialog.FileName
    }
    return ''
}

Main
