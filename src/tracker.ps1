class TimeRange
{
    [DateTime]$startDate = [DateTime]::MinValue
    [DateTime]$endDate = [DateTime]::MinValue

    TimeRange()
    {}

    TimeRange([PSCustomObject]$psCustomObject)
    {
        $this.startDate = $psCustomObject.startDate
        $this.endDate = $psCustomObject.endDate

        $this.startDate = $this.startDate.ToLocalTime()
        $this.endDate = $this.endDate.ToLocalTime()
    }

    [Boolean] IsValid()
    {
        return ($this.startDate -ne [DateTime]::MinValue) -and ($this.endDate -ne [DateTime]::MinValue)
    }

    [void] Start()
    {
        $this.startDate = Get-Date
    }

    [void] Stop()
    {
        $this.endDate = Get-Date
    }

    [TimeSpan] GetTimeSpan()
    {
        $start = $this.startDate
        $end = $this.endDate

        if ($start -eq [DateTime]::MinValue)
        {
            $start = Get-Date
        }
        if ($end -eq [DateTime]::MinValue)
        {
            $end = Get-Date
        }
        
        return $end - $start
    }
}

class DayLog
{
    [System.Collections.Generic.List[TimeRange]]$works = $null
    [Int]$likesCount = 0

    DayLog([PSCustomObject]$psCustomObject)
    {
        $this.works = [System.Collections.Generic.List[TimeRange]]::new()
        foreach ($work in $psCustomObject.works)
        {
            $this.works.Add([TimeRange]$work)
        }

        $this.likesCount = $psCustomObject.likesCount
    }

    DayLog([System.Collections.Generic.List[TimeRange]]$worksToday, [TimeRange]$currentWork, [Int]$likesCount)
    {
        $this.works = [System.Collections.Generic.List[TimeRange]]::new($worksToday)
        if ($currentWork)
        {
            $this.works.Add($currentWork)
        }
        $this.likesCount = $likesCount
    }

    [DateTime[]] GetStartAndEndDate()
    {
        $minDate = [DateTime]::MaxValue
        $maxDate = [DateTime]::MinValue
        foreach ($work in $this.works)
        {
            if (-not $work.IsValid())
            {
                continue
            }

            if ($work.startDate -lt $minDate)
            {
                $minDate = $work.startDate
            }
            if ($work.endDate -gt $maxDate)
            {
                $maxDate = $work.endDate
            }
        }

        return $minDate, $maxDate
    }

    [TimeSpan] GetWorkTime()
    {
        $workTime = [TimeSpan]::Zero
        foreach ($work in $this.works)
        {
            $workTime += $work.GetTimeSpan()
        }
        return $workTime
    }
}

class MonthLog
{
    [string]$filePath = ''
    $dayLogs = [ordered]@{}

    [void] Load([string]$folderPath, [string]$yearMonth)
    {
        $this.filePath = (Join-Path $folderPath $yearMonth) + '.json'
        if (-not (Test-Path $this.filePath))
        {
            return
        }

        $json = Get-Content -Raw $this.filePath -Encoding UTF8
        $psobject = ConvertFrom-Json $json
        $days = $psobject.psobject.properties.name

        $this.dayLogs = [ordered]@{}
        foreach ($day in $days)
        {
            $dayLog = [DayLog]::new($psobject.$day)
            $this.SetLog($day, $dayLog)
        }
    }

    [void] Save()
    {
        $json = ConvertTo-Json $this.dayLogs -Depth 3
        $json | Out-File $this.filePath -Encoding UTF8
    }

    [string[]] GetDays()
    {
        $days = @()
        foreach ($day in $this.dayLogs.Keys)
        {
            $days += $day
        }
        return $days
    }

    [Object] GetDayLog([string]$day)
    {
        return $this.dayLogs[$day]
    }

    [void] SetLog([string]$day, [System.Collections.Generic.List[TimeRange]]$worksToday, [TimeRange]$currentWork, [Int]$likesCount)
    {
        $dayLog = [DayLog]::new($worksToday, $currentWork, $likesCount)
        $this.SetLog($day, $dayLog)
    }

    [void] SetLog([string]$day, [DayLog]$dayLog)
    {
        $this.dayLogs[$day] = $dayLog
    }
}

class Tracker
{
    [System.Collections.Generic.List[TimeRange]]$worksToday = $null
    [TimeRange]$currentWork = $null
    [Int]$likesCountToday = 0
    [string]$yearMonth
    [string]$day
    [string]$logFolderPath
    [MonthLog]$monthLog = $null

    Tracker($logFolderPath)
    {
        $this.logFolderPath = $logFolderPath
    }

    [void] Start()
    {
        $this.yearMonth, $this.day = $this.GetDate()
        $this.monthLog = [MonthLog]::new()
        $this.monthLog.Load($this.logFolderPath, $this.yearMonth)

        $todaysLog = $this.monthLog.GetDayLog($this.day)
        if ($todaysLog)
        {
            $this.worksToday = [System.Collections.Generic.List[TimeRange]]::new($todaysLog.works)
            $this.likesCountToday = $todaysLog.likesCount
        }
        else
        {
            $this.worksToday = [System.Collections.Generic.List[TimeRange]]::new()
        }

        $this.EnterWork()
    }

    [void] Stop()
    {
        $this.ExitWork()
    }

    [void] Update($isWorking)
    {
        $this.UpdateDate()

        if ($this.IsWorking())
        {
            if (-not $isWorking)
            {
                $this.ExitWork()
                $this.Export()
            }
        }
        else
        {
            if ($isWorking)
            {
                $this.EnterWork()
                $this.Export()
            }
        }
    }

    [void] UpdateDate()
    {
        $month, $today = $this.GetDate()
        if ($this.day -ne $today)
        {
            $this.Stop()
            $this.Export()
            $this.Start()
        }
    }

    [string[]] GetDate()
    {
        $today = Get-Date
        return $today.ToString('yyyy_MM'), $today.ToString('dd')
    }

    [Boolean] IsWorking()
    {
        return $null -ne $this.currentWork
    }

    [void] EnterWork()
    {
        if (-not $this.IsWorking())
        {
            $this.currentWork = [TimeRange]::new()
            $this.currentWork.Start()
        }
    }

    [void] ExitWork()
    {
        if ($this.IsWorking())
        {
            $this.currentWork.Stop()
            $this.worksToday.Add($this.currentWork)
            $this.currentWork = $null
        }
    }

    [void] Export()
    {
        if ($this.currentWork)
        {
            $this.currentWork.Stop()
        }

        $this.monthLog.SetLog($this.day, $this.worksToday, $this.currentWork, $this.GetLikesCountToday())
        $this.monthLog.Save()
    }

    [TimeSpan] GetWorkTimeToday()
    {
        $workTime = [TimeSpan]::Zero
        foreach ($work in $this.worksToday)
        {
            $workTime += $work.GetTimeSpan()
        }

        if ($this.currentWork)
        {
            $workTime += $this.currentWork.GetTimeSpan()
        }
        return $workTime
    }

    [void] IncrementLikesCountToday()
    {
        ++$this.likesCountToday
    }

    [Int] GetLikesCountToday()
    {
        return $this.likesCountToday
    }
}