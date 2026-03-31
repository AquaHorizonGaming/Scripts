Set-StrictMode -Version Latest

function Test-ToolAdmin {
    [CmdletBinding()]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Get-ToolSecureBootStatus {
    [CmdletBinding()]
    param()

    try {
        return (Confirm-SecureBootUEFI -ErrorAction Stop)
    }
    catch {
        return 'Unknown/Unsupported'
    }
}

function Get-ToolTpmStatus {
    [CmdletBinding()]
    param()

    try {
        $tpm = Get-Tpm
        return if ($tpm.TpmPresent) {
            "Present=$($tpm.TpmPresent), Ready=$($tpm.TpmReady), Enabled=$($tpm.TpmEnabled), Activated=$($tpm.TpmActivated)"
        }
        else {
            'Not Present'
        }
    }
    catch {
        return 'Unknown'
    }
}

function Get-ToolNetworkSummary {
    [CmdletBinding()]
    param()

    try {
        $adapters = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -or $_.IPv6Address }
        if (-not $adapters) {
            return 'No active network adapters'
        }

        $parts = foreach ($adapter in $adapters) {
            $ip = @()
            if ($adapter.IPv4Address) { $ip += ($adapter.IPv4Address | Select-Object -ExpandProperty IPAddress) }
            if ($adapter.IPv6Address) { $ip += ($adapter.IPv6Address | Select-Object -ExpandProperty IPAddress) }
            "{0}: {1}" -f $adapter.InterfaceAlias, ($ip -join ', ')
        }

        return ($parts -join '; ')
    }
    catch {
        return 'Unable to read network status'
    }
}

function Get-ToolInventory {
    [CmdletBinding()]
    param()

    $bios = Get-CimInstance -ClassName Win32_BIOS
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem

    [pscustomobject]@{
        SerialNumber       = $bios.SerialNumber
        Manufacturer       = $cs.Manufacturer
        Model              = $cs.Model
        BIOSVersion        = (($bios.SMBIOSBIOSVersion, $bios.BIOSVersion) | Where-Object { $_ } | Select-Object -First 1)
        Hostname           = $env:COMPUTERNAME
        WindowsEdition     = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
        WindowsVersion     = $os.Version
        BuildNumber        = $os.BuildNumber
        TPMStatus          = Get-ToolTpmStatus
        SecureBootStatus   = Get-ToolSecureBootStatus
        CurrentUser        = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        RunningAsAdmin     = Test-ToolAdmin
        NetworkSummary     = Get-ToolNetworkSummary
        TimestampCollected = (Get-Date).ToString('s')
    }
}

function Convert-InventoryToDisplayText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Inventory
    )

    $ordered = @(
        'SerialNumber',
        'Manufacturer',
        'Model',
        'BIOSVersion',
        'Hostname',
        'WindowsEdition',
        'WindowsVersion',
        'BuildNumber',
        'TPMStatus',
        'SecureBootStatus',
        'CurrentUser',
        'RunningAsAdmin',
        'NetworkSummary',
        'TimestampCollected'
    )

    $lines = foreach ($name in $ordered) {
        $value = $Inventory.$name
        '{0}: {1}' -f $name, $value
    }

    return ($lines -join "`r`n")
}
