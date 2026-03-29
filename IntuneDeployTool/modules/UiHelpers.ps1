Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-UiLabel {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=140,[int]$H=20)
    $c = New-Object System.Windows.Forms.Label
    $c.Text = $Text; $c.Left = $X; $c.Top = $Y; $c.Width = $W; $c.Height = $H
    return $c
}

function New-UiButton {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=160,[int]$H=30)
    $c = New-Object System.Windows.Forms.Button
    $c.Text = $Text; $c.Left = $X; $c.Top = $Y; $c.Width = $W; $c.Height = $H
    return $c
}

function New-UiTextBox {
    param([int]$X,[int]$Y,[int]$W=300,[int]$H=24,[bool]$Multiline=$false,[bool]$ReadOnly=$false)
    $c = New-Object System.Windows.Forms.TextBox
    $c.Left = $X; $c.Top = $Y; $c.Width = $W; $c.Height = $H
    $c.Multiline = $Multiline; $c.ReadOnly = $ReadOnly
    if ($Multiline) {
        $c.ScrollBars = 'Vertical'
        $c.WordWrap = $false
    }
    return $c
}

function New-UiGroupBox {
    param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H)
    $c = New-Object System.Windows.Forms.GroupBox
    $c.Text = $Text; $c.Left = $X; $c.Top = $Y; $c.Width = $W; $c.Height = $H
    return $c
}

function New-UiStatusLabel {
    param([int]$X,[int]$Y,[int]$W=760,[int]$H=24)
    $c = New-Object System.Windows.Forms.Label
    $c.Left = $X; $c.Top = $Y; $c.Width = $W; $c.Height = $H
    $c.BorderStyle = 'Fixed3D'
    $c.Text = 'Ready.'
    return $c
}

function Show-UiInfo {
    param([string]$Message,[string]$Title='Info')
    [System.Windows.Forms.MessageBox]::Show($Message,$Title,[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Show-UiError {
    param([string]$Message,[string]$Title='Error')
    [System.Windows.Forms.MessageBox]::Show($Message,$Title,[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}
