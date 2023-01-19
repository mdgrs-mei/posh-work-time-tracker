param ($ConfigFolderPath)

Add-Type -AssemblyName System.Windows.Forms
. $PSScriptRoot\config.ps1

class TimePicker
{
    $table = $null
    $label = ''
    $comboBoxHour = $null
    $comboBoxMinutes = $null

    TimePicker($label, [TimeSpan]$defaultTime)
    {
        $this.table = New-Object System.Windows.Forms.TableLayoutPanel
        $this.table.ColumnCount = 4
        $this.table.RowCount = 1
        $this.table.Dock = 'Fill'

        $this.label = New-Object System.Windows.Forms.Label
        $this.label.Text = $label
        $this.label.TextAlign = 'MiddleLeft'
        $this.table.Controls.Add($this.label, 0, 0)

        $this.comboBoxHour = New-Object System.Windows.Forms.Combobox
        $this.comboBoxHour.DropDownStyle = 'DropDownList'
        foreach ($i in @(0..23))
        {
            $this.comboBoxHour.Items.Add($i) | Out-Null
        }
        $this.comboBoxHour.SelectedIndex = $defaultTime.Hours
        $this.table.Controls.Add($this.comboBoxHour, 1, 0)

        $colon = New-Object System.Windows.Forms.Label
        $colon.Text = ':'
        $colon.TextAlign = 'MiddleLeft'
        $colon.AutoSize = $true
        $this.table.Controls.Add($colon, 2, 0)

        $this.comboBoxMinutes = New-Object System.Windows.Forms.Combobox
        $this.comboBoxMinutes.DropDownStyle = 'DropDownList'
        foreach ($i in @(0..11))
        {
            $minutes = '{0:d2}' -f ($i * 5)
            $this.comboBoxMinutes.Items.Add($minutes) | Out-Null
        }
        $this.comboBoxMinutes.SelectedIndex = [Int]($defaultTime.Minutes / 5)
        $this.table.Controls.Add($this.comboBoxMinutes, 3, 0)
    }

    [TimeSpan] GetTimeSpan()
    {
        return [TimeSpan]::new($this.comboBoxHour.Text, $this.comboBoxMinutes.Text, 0)
    }
}

function Main()
{
    $config = LoadConfig $script:ConfigFolderPath

    $form, $maxWorkTime, $warningWarkTime = CreateUi $config

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $config.MaxWorkTime = $maxWorkTime.GetTimeSpan()
        $config.WarningWorkTime = $warningWarkTime.GetTimeSpan()
        SaveConfig $config $ConfigFolderPath
    }
}

function CreateUi($config)
{
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Posh Work Time Tracker - Config"
    $form.Width = 400
    $form.Height = 210
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.Add_Load({
        $form.Activate()
    })

    $table = New-Object System.Windows.Forms.TableLayoutPanel
    $table.ColumnCount = 1
    $table.RowCount = 4
    $table.Dock = "Fill"
    $form.Controls.Add($table)

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = "Configure settings and press the 'Save' button."
    $desc.TextAlign = 'MiddleLeft'
    $desc.Width = 300
    $desc.Height = 40
    $table.Controls.Add($desc, 0, 0)
    $table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null

    $maxWorkTime = [TimePicker]::new('Work Time a day', $config.MaxWorkTime)
    $table.Controls.Add($maxWorkTime.table, 0, 1)
    $table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null

    $warningWorkTime = [TimePicker]::new('Show Warning at', $config.WarningWorkTime)
    $table.Controls.Add($warningWorkTime.table, 0, 2)
    $table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null

    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Save"
    $button.Anchor = "Left, Right, Top"
    $button.Margin = 10
    $button.BackColor = [System.Drawing.Color]::DarkSeaGreen
    $button.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }.GetNewClosure())
    $table.Controls.Add($button, 0, 3)
    $table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null

    $form, $maxWorkTime, $warningWorkTime
}

Main
