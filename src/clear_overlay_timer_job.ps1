Add-Type -AssemblyName PresentationFramework

class ClearOverlayTimerJob
{
    $taskbarItem = $null
    $timer = $null

    [void] Start($taskbarItem, [Int]$durationInMillisecond)
    {
        $this.taskbarItem = $taskbarItem

        if ($this.timer)
        {
            $this.timer.Stop()
        }
        $this.timer = New-Object System.Windows.Threading.DispatcherTimer
        $this.timer.Interval = [System.TimeSpan]::FromMilliseconds($durationInMillisecond)

        $thisObj = $this
        $this.timer.add_Tick({
            $thisObj.taskbarItem | Clear-TaskbarItemOverlay
            $thisObj.timer.Stop()
            $thisObj.timer = $null
        }.GetNewClosure())

        $this.timer.Start()
    }

    [Boolean] IsFinished()
    {
        return $null -eq $this.timer
    }
}
