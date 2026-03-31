Set-StrictMode -Version Latest

function Test-AutopilotUploadPayload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$Capture
    )

    $errors = @()
    if ([string]::IsNullOrWhiteSpace($Capture.SerialNumber)) { $errors += 'SerialNumber is required.' }
    if ([string]::IsNullOrWhiteSpace($Capture.HardwareHash)) { $errors += 'HardwareHash is required.' }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = $errors
    }
}

function New-ToolImportId {
    [CmdletBinding()]
    param()

    return [guid]::NewGuid().Guid
}

function Get-ToolGraphAuthHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$GraphContext
    )

    if (-not $GraphContext.Connected) {
        throw 'Not authenticated to Microsoft Graph.'
    }

    if ($GraphContext.GraphModule) {
        return $null
    }

    if (-not $GraphContext.AccessToken) {
        throw 'Missing access token for REST call.'
    }

    return @{ Authorization = "Bearer $($GraphContext.AccessToken)" }
}

function Invoke-ToolGraphRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$GraphContext,
        [Parameter(Mandatory)] [string]$Method,
        [Parameter(Mandatory)] [string]$Uri,
        [object]$Body
    )

    if ($GraphContext.GraphModule) {
        $json = if ($Body) { $Body | ConvertTo-Json -Depth 8 -Compress } else { $null }
        return Invoke-MgGraphRequest -Method $Method -Uri $Uri -Body $json -ContentType 'application/json'
    }

    $headers = Get-ToolGraphAuthHeader -GraphContext $GraphContext
    $params = @{
        Method = $Method
        Uri = "https://graph.microsoft.com$Uri"
        Headers = $headers
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
    if ($Body) { $params['Body'] = ($Body | ConvertTo-Json -Depth 8) }

    return Invoke-RestMethod @params
}

function Upload-AutopilotDeviceImport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$GraphContext,
        [Parameter(Mandatory)] [pscustomobject]$Capture,
        [string]$GroupTag,
        [string]$AssignedUserPrincipalName
    )

    $validation = Test-AutopilotUploadPayload -Capture $Capture
    if (-not $validation.IsValid) {
        return [pscustomobject]@{
            Success = $false
            ImportId = $null
            Error = ($validation.Errors -join ' ')
            NextAction = 'Collect a valid Autopilot capture before uploading.'
        }
    }

    $importId = New-ToolImportId

    $state = @{ deviceImportStatus = 'pending' }
    $item = @{
        '@odata.type' = '#microsoft.graph.importedWindowsAutopilotDeviceIdentity'
        serialNumber = $Capture.SerialNumber
        hardwareIdentifier = $Capture.HardwareHash
        importId = $importId
        groupTag = $GroupTag
        state = $state
    }
    if ($AssignedUserPrincipalName) {
        $item.assignedUserPrincipalName = $AssignedUserPrincipalName
    }

    $body = @{ importedWindowsAutopilotDeviceIdentities = @($item) }

    try {
        $resp = Invoke-ToolGraphRequest -GraphContext $GraphContext -Method POST -Uri '/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities/import' -Body $body
        return [pscustomobject]@{
            Success = $true
            ImportId = $importId
            Response = $resp
            UploadedOn = (Get-Date)
            SerialNumber = $Capture.SerialNumber
            GroupTag = $GroupTag
        }
    }
    catch {
        $msg = $_.Exception.Message
        $hint = if ($msg -match 'Forbidden|Authorization|permission') {
            'Check DeviceManagementServiceConfig.ReadWrite.All permission and admin consent.'
        }
        elseif ($msg -match '400|Bad Request') {
            'Validate serial number/hardware hash format and provided fields.'
        }
        elseif ($msg -match '409|Conflict|duplicate') {
            'Device may already be imported. Check existing Autopilot identities.'
        }
        else {
            'Review log details and Graph response for troubleshooting.'
        }

        return [pscustomobject]@{
            Success = $false
            ImportId = $importId
            Error = $msg
            NextAction = $hint
        }
    }
}

function Get-AutopilotImportStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$GraphContext,
        [Parameter(Mandatory)] [string]$ImportId
    )

    try {
        $uri = "/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities?`$filter=importId eq '$ImportId'"
        $resp = Invoke-ToolGraphRequest -GraphContext $GraphContext -Method GET -Uri $uri
        $entry = @($resp.value)[0]
        if (-not $entry) {
            return [pscustomobject]@{ Found = $false; Message = 'No import record returned yet.' }
        }

        return [pscustomobject]@{
            Found = $true
            Id = $entry.id
            SerialNumber = $entry.serialNumber
            GroupTag = $entry.groupTag
            AssignedUser = $entry.assignedUserPrincipalName
            DeviceImportStatus = $entry.state.deviceImportStatus
            DeviceErrorCode = $entry.state.deviceErrorCode
            DeviceErrorName = $entry.state.deviceErrorName
        }
    }
    catch {
        return [pscustomobject]@{ Found = $false; Error = $_.Exception.Message }
    }
}

function Sync-AutopilotDevices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$GraphContext
    )

    try {
        Invoke-ToolGraphRequest -GraphContext $GraphContext -Method POST -Uri '/beta/deviceManagement/windowsAutopilotSettings/sync' -Body @{} | Out-Null
        return [pscustomobject]@{ Success = $true; Message = 'Autopilot sync requested successfully.' }
    }
    catch {
        $msg = $_.Exception.Message
        $hint = if ($msg -match '429|throttle|Too Many Requests') {
            'Graph throttled the request. Wait and retry later.'
        }
        elseif ($msg -match '409|Conflict') {
            'A sync operation may already be in progress. Retry shortly.'
        }
        else {
            'Review permissions and service health, then retry.'
        }
        return [pscustomobject]@{ Success = $false; Error = $msg; NextAction = $hint }
    }
}
