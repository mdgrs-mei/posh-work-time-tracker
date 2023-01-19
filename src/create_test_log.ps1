param ($LogFolderPath)

. $PSScriptRoot\tracker.ps1

$userInput = Read-Host 'This script is intended to be used for debugging purpose and deletes your log files. Press y to continue'
if ($userInput -ne 'y')
{
    return
}

$now = Get-Date
$yearMonth = $now.ToString('yyyy_MM')

function DeleteLogFile($yearMonth)
{
    $logFilePath = (Join-Path $script:LogFolderPath $yearMonth) + '.json'
    Remove-Item -Path $logFilePath -Force
}

function CreateTestLog($yearMonth)
{
    $monthLog = [MonthLog]::new()
    $monthLog.Load($script:LogFolderPath, $yearMonth)

    $firstDayOfMonth = $script:now.AddDays(1 - $script:now.Day)
    for ($day = $firstDayOfMonth; $day.Month -eq $script:now.Month; $day = $day.AddDays(1))
    {
        if (($day.DayOfWeek -eq 'Saturday') -or ($day.DayOfWeek -eq 'Sunday'))
        {
            continue
        }
        
        $works = [System.Collections.Generic.List[TimeRange]]::new()

        $dayStart = GetRandomTime (GetTime $day.Day 8 0) (GetTime $day.Day 12 59)
        $dayEnd = GetRandomTime (GetTime $day.Day 14 0) (GetTime $day.Day 22 0)

        $maxBreakCount = Get-Random -Minimum 1 -Maximum 5
        $lastBreakEnd = $dayStart
        $breaks = @()
        for ($i = 0; $i -lt $maxBreakCount; ++$i)
        {
            $breakStart = GetRandomTime $lastBreakEnd $dayEnd
            $breakMinute = Get-Random -Minimum 1 -Maximum 59
            $breakEnd = $breakStart.AddMinutes($breakMinute)

            if ($breakEnd -ge $dayEnd)
            {
                break
            }

            $break = [TimeRange]::new(@{
                startDate = $breakStart
                endDate = $breakEnd
            })
            $breaks += $break
            $lastBreakEnd = $breakEnd
        }

        $workStart = $dayStart
        foreach ($break in $breaks)
        {
            $workEnd = $break.startDate
            if ($workStart -ne $workEnd)
            {
                $work = [TimeRange]::new(@{
                    startDate = $workStart
                    endDate = $workEnd
                })
                $works.Add($work)
            }
            $workStart = $break.endDate
        }
        $work = [TimeRange]::new(@{
            startDate = $workStart
            endDate = $dayEnd
        })
        $works.Add($work)

        $likesCount = Get-Random -Minimum -5 -Maximum 5
        $likesCount = [Math]::Max($likesCount, 0)

        $dayString = $day.ToString('dd')
        $monthLog.SetLog($dayString, $works, $likesCount)
    }

    $monthLog.Save()
}

function GetTime($day, $hour, $minute)
{
    Get-Date -Year $script:now.Year -Month $script:now.Month -Day $day -Hour $hour -Minute $minute -Second 0
}

function GetRandomTime($start, $end)
{
    if ($start.Hour -ge $end.Hour)
    {
        $hour = $start.Hour
    }
    else
    {
        $hour = Get-Random -Minimum $start.Hour -Maximum $end.Hour
    }
    $minute = Get-Random -Minimum 0 -Maximum 59

    $rand = GetTime $start.Day $hour $minute
    if ($rand -lt $start)
    {
        return $start
    }
    if ($rand -gt $end)
    {
        return $end
    }

    $rand
}

DeleteLogFile $yearMonth
CreateTestLog $yearMonth
