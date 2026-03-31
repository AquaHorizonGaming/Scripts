Set-StrictMode -Version Latest

function Test-ToolAutopilotCsvRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$CsvRow
    )

    $errors = @()
    if ([string]::IsNullOrWhiteSpace($CsvRow.'Device Serial Number')) {
        $errors += "CSV is missing required field 'Device Serial Number'."
    }
    if ([string]::IsNullOrWhiteSpace($CsvRow.'Hardware Hash')) {
        $errors += "CSV is missing required field 'Hardware Hash'."
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = $errors
    }
}

function Invoke-ToolAutopilotCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$OutputDir,

        [string]$GroupTag,
        [string]$AssignedUser
    )

    $scriptPath = Join-Path -Path $BasePath -ChildPath 'powershell/Get-WindowsAutopilotInfo.ps1'
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Autopilot collector script not found at $scriptPath"
    }

    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $captureFile = Join-Path -Path $OutputDir -ChildPath ("AutopilotCapture_{0}.csv" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

    $args = @(
        '-NoProfile'
        '-ExecutionPolicy'; 'Bypass'
        '-File'; $scriptPath
        '-OutputFile'; $captureFile
    )
    if ($GroupTag) { $args += @('-GroupTag', $GroupTag) }
    if ($AssignedUser) { $args += @('-AssignedUser', $AssignedUser) }

    $result = & powershell.exe @args 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $combined = ($result | Out-String)
        throw "Autopilot hash capture failed with exit code $exitCode. $combined"
    }

    $csv = Import-Csv -Path $captureFile | Select-Object -First 1
    if (-not $csv) {
        throw "Capture CSV was written but empty: $captureFile"
    }

    $csvValidation = Test-ToolAutopilotCsvRow -CsvRow $csv
    if (-not $csvValidation.IsValid) {
        throw ($csvValidation.Errors -join ' ')
    }

    return [pscustomobject]@{
        SerialNumber     = $csv.'Device Serial Number'
        WindowsProductId = $csv.'Windows Product ID'
        HardwareHash     = $csv.'Hardware Hash'
        CsvPath          = $captureFile
        RawOutput        = ($result | Out-String).Trim()
        GroupTag         = $csv.'Group Tag'
        AssignedUser     = $csv.'Assigned User'
    }
}

function Test-ToolAutopilotCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Capture
    )

    $errors = @()
    if (-not $Capture.SerialNumber) { $errors += 'SerialNumber is missing.' }
    if (-not $Capture.HardwareHash) { $errors += 'HardwareHash is missing.' }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors  = $errors
    }
}
