param ($LogFolderPath)

Import-Module $PSScriptRoot\PoshTaskbarItem\PoshTaskbarItem -Force
. $PSScriptRoot\tracker.ps1
. $PSScriptRoot\clear_overlay_timer_job.ps1
. $PSScriptRoot\config.ps1

$kUpdateIntervalInSecond = 7
$kSaveLogIntervalInSecond = 35

$config = LoadConfig $LogFolderPath
$tracker = [Tracker]::new($LogFolderPath)
$clearOverlayJob = [ClearOverlayTimerJob]::new()
$ti = New-TaskbarItem -Title 'Posh Work Time Tracker' -IconResourcePath 'imageres.dll' -IconResourceIndex 96
$isPaused = $false
$configWindow = $null
$saveLogFrameCounter = 0

function Main()
{
    SetTimerFunction
    AddThumbButtons
    AddJumpTasks
    
    $script:tracker.Start()
    
    Update
    $script:ti | Show-TaskbarItem
    
    $script:tracker.Stop()
    $script:tracker.Export()
}

function SetTimerFunction()
{
    $script:ti | Set-TaskbarItemTimerFunction -IntervalInMillisecond ($kUpdateIntervalInSecond * 1000) -ScriptBlock {
        Update
    }    
}

function AddThumbButtons()
{
    $pauseButton = New-TaskbarItemThumbButton -Description 'Pause' -IconResourcePath 'wmploc.dll' -IconResourceIndex 135 -OnClicked {
        $script:isPaused = -not $script:isPaused
        Update
    }
    $openLogFolderButton = New-TaskbarItemThumbButton -Description 'Config' -IconResourcePath 'wmploc.dll' -IconResourceIndex 17 -OnClicked {
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" "{1}"' -f "$PSScriptRoot\show_config_window.ps1", $script:LogFolderPath
        $script:configWindow = Start-Process -PassThru -FilePath 'powershell.exe' -NoNewWindow -ArgumentList $arguments
    }
    $showReportButton = New-TaskbarItemThumbButton -Description 'Show Report' -IconResourcePath 'imageres.dll' -IconResourceIndex 144 -OnClicked {
        $script:tracker.Export()
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" "{1}"' -f "$PSScriptRoot\show_report.ps1", $script:LogFolderPath
        Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments
    }
    $likeButton = New-TaskbarItemThumbButton -Description 'Today is a good day!' -KeepOpenWhenClicked -IconResourcePath 'imageres.dll' -IconResourceIndex 204 -OnClicked {
        $script:tracker.IncrementLikesCountToday()
        $likesCount = $script:tracker.GetLikesCountToday()
        $script:ti | Set-TaskbarItemOverlayBadge -Text $likesCount -BackgroundColor 'Orange'
        $script:clearOverlayJob.Start($script:ti, 1500)
    }
    $script:ti | Add-TaskbarItemThumbButton -ThumbButton $pauseButton
    $script:ti | Add-TaskbarItemThumbButton -ThumbButton $openLogFolderButton
    $script:ti | Add-TaskbarItemThumbButton -ThumbButton $showReportButton
    $script:ti | Add-TaskbarItemThumbButton -ThumbButton $likeButton

}

function AddJumpTasks()
{
    $openLogFolder = New-TaskbarItemJumpTask -Title 'Open Log Folder' -IconResourcePath 'imageres.dll' -IconResourceIndex 5 -ApplicationPath 'explorer.exe' -Arguments $script:LogFolderPath

    $runWithDebugConsoleArgs = '-NoProfile -ExecutionPolicy Bypass -File "{0}" "{1}"' -f $PSCommandPath, $script:LogFolderPath
    $runWithDebugConsole = New-TaskbarItemJumpTask -Title 'Run with Debug Console' -ApplicationPath 'powershell.exe' -Arguments $runWithDebugConsoleArgs

    $script:ti | Add-TaskbarItemJumpTask -JumpTask $openLogFolder
    $script:ti | Add-TaskbarItemJumpTask -JumpTask $runWithDebugConsole
}

function Update()
{
    UpdateSaveLog

    $isWorking = IsWorking
    $script:tracker.Update($isWorking)
    $workTimeToday = $script:tracker.GetWorkTimeToday()

    $script:ti | Set-TaskbarItemDescription -Description ("---- You worked ----`n`n {0,2} hours {1,2} minutes" -f $workTimeToday.Hours, $workTimeToday.Minutes)

    $progress = $workTimeToday.TotalHours / $script:config.MaxWorkTime.TotalHours
    $progressState = 'Normal'
    $isOvertime = $false
    if ($workTimeToday.TotalHours -gt $script:config.WarningWorkTime.TotalHours)
    {
        $progressState = 'Paused'
    }
    if ($progress -ge 1)
    {
        $progressState = 'Error'
        $progress = 1
        $isOvertime = $true
    }
    $script:ti | Set-TaskbarItemProgressIndicator -Progress $progress -State $progressState

    if ($script:clearOverlayJob.IsFinished())
    {
        if (-not $isWorking)
        {
            $script:ti | Set-TaskbarItemOverlayIcon -IconResourcePath 'wmploc.dll' -IconResourceIndex 135
        }
        elseif ($isOvertime)
        {
            $script:ti | Set-TaskbarItemOverlayIcon -IconResourcePath 'comres.dll' -IconResourceIndex 8
        }
        else
        {
            $script:ti | Clear-TaskbarItemOverlay
        }
    }

    if ($script:configWindow)
    {
        if ($script:configWindow.HasExited)
        {
            ReloadConfig
            $script:configWindow = $null
        }
    }
}

function UpdateSaveLog()
{
    $saveLogIntervalFrame = $kSaveLogIntervalInSecond/$kUpdateIntervalInSecond

    $script:saveLogFrameCounter++
    if ($script:saveLogFrameCounter -ge $saveLogIntervalFrame)
    {
        $script:saveLogFrameCounter = 0
        $script:tracker.Export()
    }
}

function ReloadConfig()
{
    $script:config = LoadConfig $script:LogFolderPath
}

function IsWorking()
{
    (-not (IsScreenLocked)) -and (-not $script:isPaused)
}

Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();
'@ -Namespace WorkTimeTracker -Name Win32

function IsScreenLocked()
{
    $foregroundWindow = [WorkTimeTracker.Win32]::GetForegroundWindow()
    $foregroundWindow -eq 0
}

Main