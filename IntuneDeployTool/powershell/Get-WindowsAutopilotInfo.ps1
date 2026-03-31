[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OutputFile,
    [switch]$Append,
    [string]$GroupTag,
    [string]$AssignedUser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LocalAutopilotRecord {
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $csProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct
    $os = Get-CimInstance -ClassName Win32_OperatingSystem

    $devDetail = Get-CimInstance -Namespace root/cimv2/mdm/dmmap -ClassName MDM_DevDetail_Ext01 -ErrorAction Stop
    $hashValue = ($devDetail | Where-Object { $_.InstanceID -eq 'Ext' } | Select-Object -ExpandProperty DeviceHardwareData -First 1)

    if (-not $hashValue) {
        throw 'DeviceHardwareData is empty. Ensure this is a supported Windows client and run elevated.'
    }

    [pscustomobject]@{
        'Device Serial Number'   = $bios.SerialNumber
        'Windows Product ID'     = $os.SerialNumber
        'Hardware Hash'          = $hashValue
        'Group Tag'              = $GroupTag
        'Assigned User'          = $AssignedUser
        'Manufacturer Name'      = $csProduct.Vendor
        'Device Model'           = $csProduct.Name
    }
}

try {
    $record = Get-LocalAutopilotRecord

    $targetDir = Split-Path -Path $OutputFile -Parent
    if ($targetDir -and -not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $useAppend = $Append.IsPresent -and (Test-Path -Path $OutputFile)
    if ($useAppend) {
        $record | Export-Csv -Path $OutputFile -NoTypeInformation -Append -Encoding UTF8
    }
    else {
        $record | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
    }

    Write-Host "Autopilot capture successful: $OutputFile"
    exit 0
}
catch {
    Write-Error "Autopilot capture failed: $($_.Exception.Message)"
    exit 1
}
