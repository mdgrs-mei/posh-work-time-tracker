function LoadConfig($configFolderPath)
{
    $configFilePath = Join-Path $configFolderPath 'config.xml'
    if (Test-Path $configFilePath)
    {
        $config = Import-Clixml -Path $configFilePath
    }

    if ($null -eq $config)
    {
        $config = @{}
    }

    if ($null -eq $config.MaxWorkTime)
    {
        # 8 hours
        $config.MaxWorkTime = [TimeSpan]::new(8, 0, 0)
    }
    if ($null -eq $config.WarningWorkTime)
    {
        # 7 hours
        $config.WarningWorkTime = [TimeSpan]::new(7, 0, 0)
    }
    $config
}

function SaveConfig($config, $configFolderPath)
{
    $configFilePath = Join-Path $configFolderPath 'config.xml'
    Export-Clixml -InputObject $config -Path $configFilePath
}