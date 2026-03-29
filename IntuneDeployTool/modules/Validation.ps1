Set-StrictMode -Version Latest

function Test-ToolGroupTag {
    [CmdletBinding()]
    param([string]$GroupTag)

    if ([string]::IsNullOrWhiteSpace($GroupTag)) {
        return [pscustomobject]@{ IsValid = $true; Message = 'Group Tag is optional.' }
    }
    if ($GroupTag.Length -gt 128) {
        return [pscustomobject]@{ IsValid = $false; Message = 'Group Tag cannot exceed 128 characters.' }
    }
    if ($GroupTag -notmatch '^[\w\-\. ]+$') {
        return [pscustomobject]@{ IsValid = $false; Message = 'Group Tag can include letters, numbers, spaces, dot, underscore, hyphen.' }
    }
    return [pscustomobject]@{ IsValid = $true; Message = 'Group Tag is valid.' }
}

function Test-ToolUpn {
    [CmdletBinding()]
    param([string]$Upn)

    if ([string]::IsNullOrWhiteSpace($Upn)) {
        return [pscustomobject]@{ IsValid = $true; Message = 'Assigned User UPN is optional.' }
    }
    if ($Upn -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        return [pscustomobject]@{ IsValid = $false; Message = 'Assigned User UPN format is invalid.' }
    }
    return [pscustomobject]@{ IsValid = $true; Message = 'Assigned User UPN is valid.' }
}

function Test-ToolNamingPrefix {
    [CmdletBinding()]
    param([string]$Prefix)

    if ([string]::IsNullOrWhiteSpace($Prefix)) {
        return [pscustomobject]@{ IsValid = $true; Message = 'Prefix is optional.' }
    }
    if ($Prefix -notmatch '^[A-Za-z0-9\-]+$') {
        return [pscustomobject]@{ IsValid = $false; Message = 'Prefix must be alphanumeric or hyphen only.' }
    }
    if ($Prefix.Length -gt 10) {
        return [pscustomobject]@{ IsValid = $false; Message = 'Prefix too long for practical Autopilot naming template use.' }
    }
    return [pscustomobject]@{ IsValid = $true; Message = 'Prefix is valid.' }
}

function Test-ToolLocalRename {
    [CmdletBinding()]
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return [pscustomobject]@{ IsValid = $false; Message = 'Device name is required.' }
    }
    if ($Name.Length -gt 15) {
        return [pscustomobject]@{ IsValid = $false; Message = 'Computer name cannot exceed 15 characters.' }
    }
    if ($Name -notmatch '^[A-Za-z0-9\-]+$') {
        return [pscustomobject]@{ IsValid = $false; Message = 'Computer name allows letters, numbers, and hyphen only.' }
    }

    return [pscustomobject]@{ IsValid = $true; Message = 'Rename value is valid.' }
}

function Get-ToolAutopilotNamePreview {
    [CmdletBinding()]
    param([string]$Prefix)

    $prefixResult = Test-ToolNamingPrefix -Prefix $Prefix
    if (-not $prefixResult.IsValid) {
        return [pscustomobject]@{ IsValid = $false; Preview = ''; Warning = $prefixResult.Message }
    }

    $sample = if ($Prefix) { "$Prefix`12345" } else { 'DESKTOP12345' }
    $warning = Get-ToolNameLengthWarning -Name $sample

    return [pscustomobject]@{
        IsValid = $true
        Preview = $sample
        Warning = $warning
        Note = 'Final Autopilot device naming is controlled by the assigned deployment profile template.'
    }
}

function Get-ToolNameLengthWarning {
    [CmdletBinding()]
    param([string]$Name)

    if ($Name.Length -gt 15) {
        return 'Warning: Name preview exceeds 15 characters; NetBIOS-compatible device names should be 15 or fewer.'
    }
    return 'Name preview length is within the 15-character guideline.'
}
