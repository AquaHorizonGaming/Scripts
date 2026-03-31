Set-StrictMode -Version Latest

function New-SafeFileName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)

    $invalid = [IO.Path]::GetInvalidFileNameChars()
    $safe = $Name
    foreach ($c in $invalid) {
        $safe = $safe.Replace($c, '_')
    }
    return $safe
}

function Export-ToolCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$Capture,
        [Parameter(Mandatory)] [string]$OutputDir
    )

    if (-not (Test-Path -Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = New-SafeFileName -Name "IntuneImport_$stamp.csv"
    $path = Join-Path -Path $OutputDir -ChildPath $name

    $row = [pscustomobject]@{
        'Device Serial Number' = $Capture.SerialNumber
        'Windows Product ID'   = $Capture.WindowsProductId
        'Hardware Hash'        = $Capture.HardwareHash
        'Group Tag'            = $Capture.GroupTag
        'Assigned User'        = $Capture.AssignedUser
    }
    $row | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
    return $path
}

function Export-ToolJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$SessionData,
        [Parameter(Mandatory)] [string]$OutputDir
    )

    if (-not (Test-Path -Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = New-SafeFileName -Name "IntuneDeploySession_$stamp.json"
    $path = Join-Path -Path $OutputDir -ChildPath $name

    $SessionData | ConvertTo-Json -Depth 8 | Set-Content -Path $path -Encoding UTF8
    return $path
}

function Export-ToolLogCopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$LogFilePath,
        [Parameter(Mandatory)] [string]$OutputDir
    )

    if (-not (Test-Path -Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    if (-not (Test-Path -Path $LogFilePath)) {
        throw "Log file not found: $LogFilePath"
    }

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = New-SafeFileName -Name "SessionLog_$stamp.log"
    $dest = Join-Path -Path $OutputDir -ChildPath $name
    Copy-Item -Path $LogFilePath -Destination $dest -Force
    return $dest
}

function Export-ToolBundle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$Capture,
        [Parameter(Mandatory)] [hashtable]$SessionData,
        [Parameter(Mandatory)] [string]$OutputDir,
        [Parameter(Mandatory)] [string]$LogFilePath
    )

    $csv = Export-ToolCsv -Capture $Capture -OutputDir $OutputDir
    $json = Export-ToolJson -SessionData $SessionData -OutputDir $OutputDir
    $log = Export-ToolLogCopy -LogFilePath $LogFilePath -OutputDir $OutputDir

    return [pscustomobject]@{
        CsvPath = $csv
        JsonPath = $json
        LogPath = $log
    }
}
