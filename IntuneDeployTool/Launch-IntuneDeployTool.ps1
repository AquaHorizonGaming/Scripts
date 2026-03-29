#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    Write-Host 'IntuneDeployTool supports Windows only.'
    exit 1
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Host "Failed to load WinForms assemblies. $_"
    exit 1
}

$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $basePath 'modules/Logging.ps1')
. (Join-Path $basePath 'modules/Settings.ps1')
. (Join-Path $basePath 'modules/Inventory.ps1')
. (Join-Path $basePath 'modules/Autopilot.ps1')
. (Join-Path $basePath 'modules/GraphAuth.ps1')
. (Join-Path $basePath 'modules/GraphUpload.ps1')
. (Join-Path $basePath 'modules/Export.ps1')
. (Join-Path $basePath 'modules/Actions.ps1')
. (Join-Path $basePath 'modules/UiHelpers.ps1')
. (Join-Path $basePath 'modules/Validation.ps1')


try {
    $build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
    if ($build -lt 22000) {
        [System.Windows.Forms.MessageBox]::Show('IntuneDeployTool supports Windows 11 (build 22000+) only.','Unsupported OS','OK','Error') | Out-Null
        exit 1
    }
}
catch {
    Write-Host 'Unable to confirm Windows build. Proceeding with caution.'
}


if (-not (Test-ToolAdmin)) {
    $argList = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList | Out-Null
    exit 0
}

$settings = Import-ToolSettings -ConfigPath (Join-Path $basePath 'config/settings.json') -BasePath $basePath
$null = Initialize-Logging -LogDirectory $settings.LogDir -AppName $settings.AppName
Write-ToolLog -Level Info -Message 'Application startup complete.'

$script:Session = @{
    Settings = $settings
    Inventory = $null
    Capture = $null
    Upload = $null
    ImportStatus = $null
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "$($settings.AppName) - Windows Autopilot / Intune Bench Tool"
$form.Size = New-Object System.Drawing.Size(980, 760)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $false
$form.MinimumSize = New-Object System.Drawing.Size(980, 760)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = 'Fill'

$tabDevice = New-Object System.Windows.Forms.TabPage
$tabDevice.Text = 'Device Summary'
$tabCapture = New-Object System.Windows.Forms.TabPage
$tabCapture.Text = 'Autopilot Capture'
$tabGraph = New-Object System.Windows.Forms.TabPage
$tabGraph.Text = 'Graph Upload'
$tabExport = New-Object System.Windows.Forms.TabPage
$tabExport.Text = 'Export'
$tabActions = New-Object System.Windows.Forms.TabPage
$tabActions.Text = 'Actions'
$tabLogs = New-Object System.Windows.Forms.TabPage
$tabLogs.Text = 'Logs'

$tabs.TabPages.AddRange(@($tabDevice,$tabCapture,$tabGraph,$tabExport,$tabActions,$tabLogs))
$form.Controls.Add($tabs)

$statusLabel = New-UiStatusLabel -X 10 -Y 680 -W 940
$form.Controls.Add($statusLabel)

# Device tab
$txtDevice = New-UiTextBox -X 10 -Y 10 -W 920 -H 600 -Multiline $true -ReadOnly $true
$btnRefreshDevice = New-UiButton -Text 'Refresh Device Info' -X 10 -Y 620 -W 180
$txtDevice.Anchor = 'Top,Bottom,Left,Right'
$btnRefreshDevice.Anchor = 'Bottom,Left'
$tabDevice.Controls.AddRange(@($txtDevice,$btnRefreshDevice))

# Capture tab
$btnCapture = New-UiButton -Text 'Capture Autopilot Hash' -X 10 -Y 10 -W 200
$btnValidateCapture = New-UiButton -Text 'Validate Capture' -X 220 -Y 10 -W 160
$btnOpenOutput1 = New-UiButton -Text 'Open Output Folder' -X 390 -Y 10 -W 160
$txtCaptureRaw = New-UiTextBox -X 10 -Y 50 -W 920 -H 560 -Multiline $true -ReadOnly $true
$btnCapture.Anchor = 'Top,Left'
$btnValidateCapture.Anchor = 'Top,Left'
$btnOpenOutput1.Anchor = 'Top,Left'
$txtCaptureRaw.Anchor = 'Top,Bottom,Left,Right'
$tabCapture.Controls.AddRange(@($btnCapture,$btnValidateCapture,$btnOpenOutput1,$txtCaptureRaw))

# Graph tab
$lblAuth = New-UiLabel -Text 'Auth Mode:' -X 10 -Y 15 -W 80
$cmbAuth = New-Object System.Windows.Forms.ComboBox
$cmbAuth.Left = 100; $cmbAuth.Top = 10; $cmbAuth.Width = 220
$cmbAuth.DropDownStyle = 'DropDownList'
$cmbAuth.Items.AddRange(@('Auto','Interactive delegated','App-only certificate'))
$cmbAuth.SelectedItem = if ($settings.DefaultAuthMode) { $settings.DefaultAuthMode } else { 'Auto' }

$lblTenant = New-UiLabel -Text 'Tenant ID:' -X 10 -Y 50
$txtTenant = New-UiTextBox -X 130 -Y 45 -W 330
$txtTenant.Text = $settings.TenantId
$lblClient = New-UiLabel -Text 'Client ID:' -X 10 -Y 80
$txtClient = New-UiTextBox -X 130 -Y 75 -W 330
$txtClient.Text = $settings.ClientId
$lblThumb = New-UiLabel -Text 'Cert Thumbprint:' -X 10 -Y 110
$txtThumb = New-UiTextBox -X 130 -Y 105 -W 330
$txtThumb.Text = $settings.CertThumbprint
$lblGroup = New-UiLabel -Text 'Group Tag:' -X 10 -Y 140
$txtGroup = New-UiTextBox -X 130 -Y 135 -W 220
$txtGroup.Text = $settings.DefaultGroupTag
$lblUpn = New-UiLabel -Text 'Assigned User UPN:' -X 10 -Y 170
$txtUpn = New-UiTextBox -X 130 -Y 165 -W 330

$btnConnect = New-UiButton -Text 'Connect / Authenticate' -X 10 -Y 205 -W 190
$btnUpload = New-UiButton -Text 'Upload Autopilot Record' -X 210 -Y 205 -W 190
$btnCheckStatus = New-UiButton -Text 'Check Import Status' -X 410 -Y 205 -W 150
$btnSync = New-UiButton -Text 'Sync Autopilot' -X 570 -Y 205 -W 130

$grpPreview = New-UiGroupBox -Text 'Name Preview (Template Awareness)' -X 490 -Y 10 -W 440 -H 190
$lblPrefix = New-UiLabel -Text 'Prefix:' -X 10 -Y 25 -W 60
$txtPrefix = New-UiTextBox -X 70 -Y 22 -W 130
$btnPreview = New-UiButton -Text 'Preview' -X 210 -Y 20 -W 90 -H 26
$txtPreview = New-UiTextBox -X 10 -Y 55 -W 410 -H 110 -Multiline $true -ReadOnly $true
$grpPreview.Controls.AddRange(@($lblPrefix,$txtPrefix,$btnPreview,$txtPreview))

$txtGraphStatus = New-UiTextBox -X 10 -Y 245 -W 920 -H 365 -Multiline $true -ReadOnly $true
$txtGraphStatus.Anchor = 'Top,Bottom,Left,Right'
$tabGraph.Controls.AddRange(@($lblAuth,$cmbAuth,$lblTenant,$txtTenant,$lblClient,$txtClient,$lblThumb,$txtThumb,$lblGroup,$txtGroup,$lblUpn,$txtUpn,$btnConnect,$btnUpload,$btnCheckStatus,$btnSync,$grpPreview,$txtGraphStatus))

# Export tab
$txtCsvPreview = New-UiTextBox -X 10 -Y 10 -W 920 -H 140 -Multiline $true -ReadOnly $true
$txtJsonPreview = New-UiTextBox -X 10 -Y 160 -W 920 -H 320 -Multiline $true -ReadOnly $true
$btnExport = New-UiButton -Text 'Export CSV/JSON/Log Bundle' -X 10 -Y 490 -W 250
$txtExportResult = New-UiTextBox -X 10 -Y 530 -W 920 -H 80 -Multiline $true -ReadOnly $true
$txtCsvPreview.Anchor = 'Top,Left,Right'
$txtJsonPreview.Anchor = 'Top,Bottom,Left,Right'
$btnExport.Anchor = 'Bottom,Left'
$txtExportResult.Anchor = 'Bottom,Left,Right'
$tabExport.Controls.AddRange(@($txtCsvPreview,$txtJsonPreview,$btnExport,$txtExportResult))

# Actions tab
$lblRename = New-UiLabel -Text 'Rename device:' -X 10 -Y 15
$txtRename = New-UiTextBox -X 130 -Y 10 -W 240
$btnRename = New-UiButton -Text 'Rename' -X 380 -Y 8 -W 90 -H 26
$btnOpenWorkSchool = New-UiButton -Text 'Open Work or School' -X 10 -Y 45 -W 180
$btnCompanyPortal = New-UiButton -Text 'Open Company Portal' -X 200 -Y 45 -W 180
$btnOpenOutput2 = New-UiButton -Text 'Open Output Folder' -X 390 -Y 45 -W 160

$lblLocalAdmin = New-UiLabel -Text 'Bootstrap admin user:' -X 10 -Y 90 -W 120
$txtAdminUser = New-UiTextBox -X 130 -Y 85 -W 180
$txtAdminPass = New-UiTextBox -X 320 -Y 85 -W 180
$txtAdminPass.UseSystemPasswordChar = $true
$btnCreateAdmin = New-UiButton -Text 'Create Local Admin' -X 510 -Y 83 -W 150 -H 26

$txtPreflight = New-UiTextBox -X 10 -Y 130 -W 920 -H 200 -Multiline $true -ReadOnly $true
$txtSummary = New-UiTextBox -X 10 -Y 340 -W 920 -H 270 -Multiline $true -ReadOnly $true
$txtPreflight.Anchor = 'Top,Left,Right'
$txtSummary.Anchor = 'Top,Bottom,Left,Right'
$txtPreflight.Text = Get-ToolPreflightText
$txtSummary.Text = Get-ToolBenchCompletionText
$tabActions.Controls.AddRange(@($lblRename,$txtRename,$btnRename,$btnOpenWorkSchool,$btnCompanyPortal,$btnOpenOutput2,$lblLocalAdmin,$txtAdminUser,$txtAdminPass,$btnCreateAdmin,$txtPreflight,$txtSummary))

# Logs tab
$txtLogs = New-UiTextBox -X 10 -Y 10 -W 920 -H 560 -Multiline $true -ReadOnly $true
$btnRefreshLogs = New-UiButton -Text 'Refresh Logs' -X 10 -Y 580 -W 120
$btnOpenLog = New-UiButton -Text 'Open Log File' -X 140 -Y 580 -W 120
$txtLogs.Anchor = 'Top,Bottom,Left,Right'
$btnRefreshLogs.Anchor = 'Bottom,Left'
$btnOpenLog.Anchor = 'Bottom,Left'
$tabLogs.Controls.AddRange(@($txtLogs,$btnRefreshLogs,$btnOpenLog))
Set-GuiLogTextBox -TextBox $txtLogs

function Set-Status([string]$text) {
    $statusLabel.Text = $text
}

function Refresh-InventoryUi {
    try {
        $inv = Get-ToolInventory
        $script:Session.Inventory = $inv
        $txtDevice.Text = Convert-InventoryToDisplayText -Inventory $inv
        Set-Status 'Device inventory refreshed.'
        Write-ToolLog -Level Info -Message 'Device inventory refreshed.'
    }
    catch {
        $msg = "Inventory refresh failed: $($_.Exception.Message)"
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
}

function Refresh-ExportPreview {
    if (-not $script:Session.Capture) {
        $txtCsvPreview.Text = 'Capture required before export preview.'
        $txtJsonPreview.Text = ''
        return
    }

    $capture = $script:Session.Capture
    $csvPreview = [pscustomobject]@{
        'Device Serial Number' = $capture.SerialNumber
        'Windows Product ID' = $capture.WindowsProductId
        'Hardware Hash' = $capture.HardwareHash
        'Group Tag' = $capture.GroupTag
        'Assigned User' = $capture.AssignedUser
    } | ConvertTo-Csv -NoTypeInformation
    $txtCsvPreview.Text = $csvPreview -join [Environment]::NewLine

    $sessionObj = @{
        Inventory = $script:Session.Inventory
        Capture = $script:Session.Capture
        Upload = $script:Session.Upload
        ImportStatus = $script:Session.ImportStatus
        Timestamp = (Get-Date).ToString('s')
    }
    $txtJsonPreview.Text = ($sessionObj | ConvertTo-Json -Depth 8)
}

$btnRefreshDevice.Add_Click({ Refresh-InventoryUi })
$btnOpenOutput1.Add_Click({ Open-ToolOutputFolder -OutputDir $settings.OutputDir })
$btnOpenOutput2.Add_Click({ Open-ToolOutputFolder -OutputDir $settings.OutputDir })

$btnCapture.Add_Click({
    try {
        Set-Status 'Capturing Autopilot hardware hash...'
        Write-ToolLog -Level Info -Message 'Starting Autopilot capture.'

        $capture = Invoke-ToolAutopilotCapture -BasePath $basePath -OutputDir $settings.OutputDir -GroupTag $txtGroup.Text -AssignedUser $txtUpn.Text
        $script:Session.Capture = $capture

        $txtCaptureRaw.Text = @(
            "SerialNumber: $($capture.SerialNumber)"
            "WindowsProductId: $($capture.WindowsProductId)"
            "HardwareHash (length): $($capture.HardwareHash.Length)"
            "CsvPath: $($capture.CsvPath)"
            'Raw Output:'
            $capture.RawOutput
        ) -join "`r`n"

        Set-Status 'Autopilot capture complete.'
        Write-ToolLog -Level Info -Message "Autopilot capture completed. CSV: $($capture.CsvPath)"
        Refresh-ExportPreview
    }
    catch {
        $msg = "Autopilot capture failed: $($_.Exception.Message)"
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnValidateCapture.Add_Click({
    if (-not $script:Session.Capture) {
        Show-UiError -Message 'No capture available to validate.'
        return
    }
    $v = Test-ToolAutopilotCapture -Capture $script:Session.Capture
    if ($v.IsValid) {
        Show-UiInfo -Message 'Capture validation passed.'
        Write-ToolLog -Level Info -Message 'Capture validation passed.'
    }
    else {
        $msg = ($v.Errors -join [Environment]::NewLine)
        Show-UiError -Message "Capture validation failed:`n$msg"
        Write-ToolLog -Level Error -Message "Capture validation failed: $msg"
    }
})

$btnPreview.Add_Click({
    $r = Get-ToolAutopilotNamePreview -Prefix $txtPrefix.Text
    if (-not $r.IsValid) {
        $txtPreview.Text = $r.Warning
        return
    }
    $txtPreview.Text = @(
        "Example Name: $($r.Preview)"
        $r.Warning
        ''
        $r.Note
    ) -join "`r`n"
})

$btnConnect.Add_Click({
    try {
        $mode = [string]$cmbAuth.SelectedItem
        if (-not $mode) { $mode = 'Auto' }

        if ($mode -eq 'Auto') {
            $mode = if ($txtTenant.Text -and $txtClient.Text -and $txtThumb.Text) { 'App-only certificate' } else { 'Interactive delegated' }
        }

        if ($mode -eq 'App-only certificate') {
            $ctx = Connect-ToolGraphAppOnly -TenantId $txtTenant.Text -ClientId $txtClient.Text -CertificateThumbprint $txtThumb.Text
        }
        else {
            $ctx = Connect-ToolGraphInteractive -TenantId $txtTenant.Text
        }

        $txtGraphStatus.Text = "Connected to Graph.`r`nMode: $($ctx.AuthMode)`r`nTenant: $($ctx.TenantId)`r`nClient: $($ctx.ClientId)"
        Set-Status 'Graph authentication succeeded.'
        Write-ToolLog -Level Info -Message "Graph connected via $($ctx.AuthMode)."
    }
    catch {
        $msg = "Graph authentication failed: $($_.Exception.Message)"
        $txtGraphStatus.Text = $msg
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnUpload.Add_Click({
    try {
        if (-not $script:Session.Capture) { throw 'Capture Autopilot data before upload.' }

        $gt = Test-ToolGroupTag -GroupTag $txtGroup.Text
        if (-not $gt.IsValid) { throw $gt.Message }
        $up = Test-ToolUpn -Upn $txtUpn.Text
        if (-not $up.IsValid) { throw $up.Message }

        $ctx = Get-ToolGraphContext
        if (-not $ctx.Connected) { throw 'Authenticate to Graph first.' }

        $script:Session.Capture.GroupTag = $txtGroup.Text
        $script:Session.Capture.AssignedUser = $txtUpn.Text

        $upload = Upload-AutopilotDeviceImport -GraphContext $ctx -Capture $script:Session.Capture -GroupTag $txtGroup.Text -AssignedUserPrincipalName $txtUpn.Text
        $script:Session.Upload = $upload

        if (-not $upload.Success) {
            $txtGraphStatus.Text = @(
                "Upload failed"
                "Import ID: $($upload.ImportId)"
                "Error: $($upload.Error)"
                "Suggested next step: $($upload.NextAction)"
            ) -join "`r`n"
            Set-Status 'Autopilot upload failed.'
            Write-ToolLog -Level Error -Message "Upload failed. $($upload.Error)"
            return
        }

        $status = Get-AutopilotImportStatus -GraphContext $ctx -ImportId $upload.ImportId
        $script:Session.ImportStatus = $status

        $txtGraphStatus.Text = @(
            'Upload succeeded'
            "Serial Number: $($upload.SerialNumber)"
            "Group Tag: $($upload.GroupTag)"
            "Import ID: $($upload.ImportId)"
            "Uploaded On: $($upload.UploadedOn)"
            "Import Status: $(if($status.Found){$status.DeviceImportStatus}else{'Pending / Not yet queryable'})"
            "State Details: $(if($status.Found){$status.DeviceErrorName}else{$status.Message})"
        ) -join "`r`n"
        Set-Status 'Autopilot upload succeeded.'
        Write-ToolLog -Level Info -Message "Upload succeeded. ImportId=$($upload.ImportId)"

        if ($settings.SyncAfterUpload) {
            $sync = Sync-AutopilotDevices -GraphContext $ctx
            if ($sync.Success) {
                $txtGraphStatus.AppendText([Environment]::NewLine + $sync.Message)
                Write-ToolLog -Level Info -Message 'Auto sync requested after upload.'
            }
            else {
                $txtGraphStatus.AppendText([Environment]::NewLine + "Sync failed: $($sync.Error)" + [Environment]::NewLine + "Next action: $($sync.NextAction)")
                Write-ToolLog -Level Warn -Message "Auto sync failed: $($sync.Error)"
            }
        }

        Refresh-ExportPreview
    }
    catch {
        $msg = "Upload operation failed: $($_.Exception.Message)"
        $txtGraphStatus.Text = $msg
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnSync.Add_Click({
    try {
        $ctx = Get-ToolGraphContext
        if (-not $ctx.Connected) { throw 'Authenticate to Graph first.' }
        $sync = Sync-AutopilotDevices -GraphContext $ctx
        if ($sync.Success) {
            $txtGraphStatus.AppendText([Environment]::NewLine + $sync.Message)
            Set-Status 'Autopilot sync requested.'
            Write-ToolLog -Level Info -Message $sync.Message
        }
        else {
            $txtGraphStatus.AppendText([Environment]::NewLine + "Sync failed: $($sync.Error)" + [Environment]::NewLine + "Next action: $($sync.NextAction)")
            Set-Status 'Autopilot sync failed.'
            Write-ToolLog -Level Warn -Message "Sync failed: $($sync.Error)"
            Show-UiError -Message "Sync failed: $($sync.Error)`n$($sync.NextAction)"
        }
    }
    catch {
        $msg = "Sync request failed: $($_.Exception.Message)"
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnCheckStatus.Add_Click({
    try {
        $ctx = Get-ToolGraphContext
        if (-not $ctx.Connected) { throw 'Authenticate to Graph first.' }
        if (-not $script:Session.Upload -or [string]::IsNullOrWhiteSpace($script:Session.Upload.ImportId)) {
            throw 'No upload import ID in session. Upload a record first.'
        }

        $status = Get-AutopilotImportStatus -GraphContext $ctx -ImportId $script:Session.Upload.ImportId
        $script:Session.ImportStatus = $status

        if ($status.Found) {
            $txtGraphStatus.Text = @(
                'Import status retrieved'
                "Import ID: $($script:Session.Upload.ImportId)"
                "Serial Number: $($status.SerialNumber)"
                "Group Tag: $($status.GroupTag)"
                "Assigned User: $($status.AssignedUser)"
                "Device Import Status: $($status.DeviceImportStatus)"
                "Device Error Code: $($status.DeviceErrorCode)"
                "Device Error Name: $($status.DeviceErrorName)"
            ) -join "`r`n"
        }
        else {
            $txtGraphStatus.Text = @(
                'Import status not available yet'
                "Import ID: $($script:Session.Upload.ImportId)"
                "Details: $(if($status.Error){$status.Error}else{$status.Message})"
            ) -join "`r`n"
        }

        Write-ToolLog -Level Info -Message "Checked import status for $($script:Session.Upload.ImportId)."
    }
    catch {
        $msg = "Import status check failed: $($_.Exception.Message)"
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnExport.Add_Click({
    try {
        if (-not $script:Session.Capture) { throw 'Capture data is required before export.' }
        $bundle = Export-ToolBundle -Capture $script:Session.Capture -SessionData $script:Session -OutputDir $settings.OutputDir -LogFilePath (Get-LogFilePath)
        $txtExportResult.Text = @(
            "CSV:  $($bundle.CsvPath)"
            "JSON: $($bundle.JsonPath)"
            "LOG:  $($bundle.LogPath)"
        ) -join "`r`n"
        Set-Status 'Export bundle created.'
        Write-ToolLog -Level Info -Message "Export bundle created: $($bundle.CsvPath), $($bundle.JsonPath), $($bundle.LogPath)"
    }
    catch {
        $msg = "Export failed: $($_.Exception.Message)"
        Set-Status $msg
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnRename.Add_Click({
    try {
        $r = Test-ToolLocalRename -Name $txtRename.Text
        if (-not $r.IsValid) { throw $r.Message }

        $warning = "Final Autopilot device naming is controlled by the assigned deployment profile template.`nLocal rename does not change hardware hash import naming behavior.`n`nProceed with local rename?"
        $choice = [System.Windows.Forms.MessageBox]::Show($warning,'Rename Warning','YesNo','Warning')
        if ($choice -ne 'Yes') { return }

        $msg = Rename-ToolDevice -NewName $txtRename.Text
        Write-ToolLog -Level Info -Message $msg
        Show-UiInfo -Message "$msg`nRestart is required."
    }
    catch {
        $msg = "Rename failed: $($_.Exception.Message)"
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnOpenWorkSchool.Add_Click({ Open-ToolWorkSchoolSettings -Uri $settings.WorkSchoolUri })
$btnCompanyPortal.Add_Click({ Open-ToolCompanyPortal -FallbackUri $settings.CompanyPortalFallback })

$btnCreateAdmin.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($txtAdminUser.Text) -or [string]::IsNullOrWhiteSpace($txtAdminPass.Text)) {
            throw 'Username and password are required.'
        }
        $secure = ConvertTo-SecureString -String $txtAdminPass.Text -AsPlainText -Force
        $msg = New-ToolBootstrapLocalAdmin -UserName $txtAdminUser.Text -Password $secure
        Write-ToolLog -Level Info -Message $msg
        Show-UiInfo -Message $msg
    }
    catch {
        $msg = "Create local admin failed: $($_.Exception.Message)"
        Write-ToolLog -Level Error -Message $msg
        Show-UiError -Message $msg
    }
})

$btnRefreshLogs.Add_Click({
    try {
        $logPath = Get-LogFilePath
        if (Test-Path -Path $logPath) {
            $txtLogs.Text = Get-Content -Path $logPath -Raw
        }
    }
    catch {}
})

$btnOpenLog.Add_Click({
    $logPath = Get-LogFilePath
    if (Test-Path -Path $logPath) {
        Start-Process 'notepad.exe' -ArgumentList $logPath | Out-Null
    }
})

Refresh-InventoryUi
Refresh-ExportPreview
$txtSummary.AppendText([Environment]::NewLine + [Environment]::NewLine + 'Reset/Wipe handoff guidance: Run a reset or wipe after successful import, then validate OOBE/ESP behavior in a new session.')

[void]$form.ShowDialog()
