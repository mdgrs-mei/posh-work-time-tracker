param ($LogFolderPath)

. $PSScriptRoot\config.ps1
. $PSScriptRoot\tracker.ps1

$config = LoadConfig $LogFolderPath

# Create tracker to load the log
$tracker = [Tracker]::new($LogFolderPath)
$tracker.Start()
$tracker.Stop()

$kHourDivision = 4

function Main()
{
    $slots, $minTimeIndex, $maxTimeIndex = GetTimeSlots
    $minDisplayTimeIndex = [Math]::Max($minTimeIndex - $script:kHourDivision, 0)
    $maxDisplayTimeIndex = [Math]::Min($maxTimeIndex + $script:kHourDivision, 24 * $script:kHourDivision - 1)

    PrintYearMonth
    PrintTimeScale $minDisplayTimeIndex $maxDisplayTimeIndex
    PrintTimeSlots $slots $minDisplayTimeIndex $maxDisplayTimeIndex

    ''
    Read-Host 'Press any key to close'
}

function GetTimeSlots()
{
    $days = $script:tracker.monthLog.GetDays()
    $slots = [Boolean[,]]::new($days.Count, (24 * $script:kHourDivision))

    $minTimeIndex = 24 * $script:kHourDivision
    $maxTimeIndex = 0
    for ($dayIndex = 0; $dayIndex -ne $days.Count; ++$dayIndex)
    {
        $day = $days[$dayIndex]
        $dayLog = $script:tracker.monthLog.GetDayLog($day)
        $works = $dayLog.works

        foreach ($work in $works)
        {
            if (-not $work.IsValid()) 
            {
                continue
            }

            $startTimeIndex = $work.startDate.Hour * $script:kHourDivision + [Int]($work.startDate.Minute * $script:kHourDivision / 60)
            $endTimeIndex = $work.endDate.Hour * $script:kHourDivision + [Int]($work.endDate.Minute * $script:kHourDivision / 60)

            $minTimeIndex = [Math]::Min($startTimeIndex, $minTimeIndex)
            $maxTimeIndex = [Math]::Max($endTimeIndex, $maxTimeIndex)

            for ($i = $startTimeIndex; $i -le $endTimeIndex; ++$i)
            {
                $slots[$dayIndex, $i] = $true
            }
        }
    }

    $slots, $minTimeIndex, $maxTimeIndex
}

function PrintYearMonth()
{
    $year, $month = $script:tracker.yearMonth.Split('_')
    ''
    '---------------------------------------'
    ' Posh Work Time Tracker Report {0}/{1:D2}' -f $year, $month
    '---------------------------------------'
    ''
}

function PrintTimeScale($minDisplayTimeIndex, $maxDisplayTimeIndex)
{
    $line = [System.Text.StringBuilder]::new()
    $line.Append(' ' * 27) | Out-Null
    for ($i = $minDisplayTimeIndex; $i -le $maxDisplayTimeIndex;)
    {
        if (($i % $script:kHourDivision) -eq 0)
        {
            $hour = [Int]($i / $script:kHourDivision)
            $string = $hour.ToString()
        }
        else 
        {
            $string = '-'
        }
        $i += $string.Length
        $line.Append($string) | Out-Null
    }
    $line.ToString()
}

function PrintTimeSlots($slots, $minDisplayTimeIndex, $maxDisplayTimeIndex)
{
    $kFullBlock = [char]0x2588
    $kWhiteMediumStar = [char]0x2B50

    $line = [System.Text.StringBuilder]::new()
    $days = $script:tracker.monthLog.GetDays()

    for ($dayIndex = 0; $dayIndex -ne $days.Count; ++$dayIndex)
    {
        $day = $days[$dayIndex]
        $dayLog = $script:tracker.monthLog.GetDayLog($day)

        $line.Clear() | Out-Null

        $workTime = $dayLog.GetWorkTime()
        $overtimeMark = ''
        if ($workTime -gt $script:config.MaxWorkTime)
        {
            $overtimeMark = '*'
        }
        $startDate, $endDate = $dayLog.GetStartAndEndDate()
        $line.Append('{0,1}[{1:D2}] {2:D2}:{3:D2} ({4:D2}:{5:D2} - {6:D2}:{7:D2})' -f @($overtimeMark, [Int]$day, $workTime.Hours, $workTime.Minutes, $startDate.Hour, $startDate.Minute, $endDate.Hour, $endDate.Minute)) | Out-Null

        for ($i = $minDisplayTimeIndex; $i -le $maxDisplayTimeIndex; ++$i)
        {
            if ($slots[$dayIndex, $i])
            {
                $string = $kFullBlock
            }
            else 
            {
                $string = ' '
            }
            $line.Append($string) | Out-Null
        }

        $likesCount = $dayLog.likesCount
        if ($likesCount)
        {
            $string = '  ' + $kWhiteMediumStar + (" x {0}" -f $likesCount)
            $line.Append($string) | Out-Null
        }

        $line.ToString()
    }
}

Main
