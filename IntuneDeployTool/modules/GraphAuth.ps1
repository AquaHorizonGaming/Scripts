Set-StrictMode -Version Latest

$script:ToolGraphContext = [ordered]@{
    Connected     = $false
    AuthMode      = $null
    TenantId      = $null
    ClientId      = $null
    AccessToken   = $null
    ExpiresOn     = $null
    ConnectedOn   = $null
    GraphModule   = $false
}

function Test-GraphModuleAvailable {
    [CmdletBinding()]
    param()

    return [bool](Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)
}

function Get-GraphModuleInstallGuidance {
    [CmdletBinding()]
    param()

    return @(
        'Microsoft Graph PowerShell module is required for interactive login and preferred operations.',
        'Install-Module Microsoft.Graph -Scope CurrentUser',
        'Then restart PowerShell and re-open the tool.'
    ) -join [Environment]::NewLine
}

function Connect-ToolGraphInteractive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    if (-not (Test-GraphModuleAvailable)) {
        throw (Get-GraphModuleInstallGuidance)
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @('DeviceManagementServiceConfig.ReadWrite.All')
    Connect-MgGraph -TenantId $TenantId -Scopes $scopes -NoWelcome -ErrorAction Stop | Out-Null
    $ctx = Get-MgContext

    $script:ToolGraphContext.Connected = $true
    $script:ToolGraphContext.AuthMode = 'InteractiveDelegated'
    $script:ToolGraphContext.TenantId = $ctx.TenantId
    $script:ToolGraphContext.ClientId = $ctx.ClientId
    $script:ToolGraphContext.AccessToken = $null
    $script:ToolGraphContext.ExpiresOn = $null
    $script:ToolGraphContext.ConnectedOn = Get-Date
    $script:ToolGraphContext.GraphModule = $true

    return [pscustomobject]$script:ToolGraphContext
}

function Get-CertificateFromStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Thumbprint
    )

    $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1
    if (-not $cert) {
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1
    }
    if (-not $cert) {
        throw "Certificate with thumbprint '$Thumbprint' not found in CurrentUser or LocalMachine store."
    }
    if (-not $cert.HasPrivateKey) {
        throw "Certificate '$Thumbprint' does not have a private key."
    }

    return $cert
}

function ConvertTo-Base64Url {
    param([byte[]]$Bytes)
    [Convert]::ToBase64String($Bytes).TrimEnd('=') -replace '\+', '-' -replace '/', '_'
}

function New-ClientAssertionJwt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TenantId,
        [Parameter(Mandatory)] [string]$ClientId,
        [Parameter(Mandatory)] [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    $now = [DateTimeOffset]::UtcNow
    $header = @{ alg = 'RS256'; typ = 'JWT'; x5t = ConvertTo-Base64Url -Bytes $Certificate.GetCertHash() }
    $payload = @{
        aud = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        iss = $ClientId
        sub = $ClientId
        jti = [guid]::NewGuid().Guid
        nbf = $now.ToUnixTimeSeconds()
        exp = $now.AddMinutes(10).ToUnixTimeSeconds()
    }

    $headerJson = ($header | ConvertTo-Json -Compress)
    $payloadJson = ($payload | ConvertTo-Json -Compress)
    $unsigned = "$(ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($headerJson))).$(ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($payloadJson)))"

    $rsa = $Certificate.GetRSAPrivateKey()
    if (-not $rsa) { throw 'Unable to obtain RSA private key from certificate.' }
    $sig = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($unsigned), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)

    return "$unsigned.$(ConvertTo-Base64Url $sig)"
}

function Connect-ToolGraphAppOnly {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TenantId,
        [Parameter(Mandatory)] [string]$ClientId,
        [Parameter(Mandatory)] [string]$CertificateThumbprint
    )

    $cert = Get-CertificateFromStore -Thumbprint $CertificateThumbprint

    if (Test-GraphModuleAvailable) {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome -ErrorAction Stop | Out-Null

        $script:ToolGraphContext.Connected = $true
        $script:ToolGraphContext.AuthMode = 'AppOnlyCertificate'
        $script:ToolGraphContext.TenantId = $TenantId
        $script:ToolGraphContext.ClientId = $ClientId
        $script:ToolGraphContext.AccessToken = $null
        $script:ToolGraphContext.ExpiresOn = $null
        $script:ToolGraphContext.ConnectedOn = Get-Date
        $script:ToolGraphContext.GraphModule = $true
        return [pscustomobject]$script:ToolGraphContext
    }

    $assertion = New-ClientAssertionJwt -TenantId $TenantId -ClientId $ClientId -Certificate $cert
    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $tokenBody = @{
        client_id = $ClientId
        scope = 'https://graph.microsoft.com/.default'
        grant_type = 'client_credentials'
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion = $assertion
    }
    $token = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body $tokenBody -ContentType 'application/x-www-form-urlencoded'

    $script:ToolGraphContext.Connected = $true
    $script:ToolGraphContext.AuthMode = 'AppOnlyCertificate'
    $script:ToolGraphContext.TenantId = $TenantId
    $script:ToolGraphContext.ClientId = $ClientId
    $script:ToolGraphContext.AccessToken = $token.access_token
    $script:ToolGraphContext.ExpiresOn = (Get-Date).AddSeconds([int]$token.expires_in)
    $script:ToolGraphContext.ConnectedOn = Get-Date
    $script:ToolGraphContext.GraphModule = $false

    return [pscustomobject]$script:ToolGraphContext
}

function Get-ToolGraphContext {
    [CmdletBinding()]
    param()

    return [pscustomobject]$script:ToolGraphContext
}

function Disconnect-ToolGraph {
    [CmdletBinding()]
    param()

    if ($script:ToolGraphContext.GraphModule) {
        try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
    }

    foreach ($k in @('Connected','AuthMode','TenantId','ClientId','AccessToken','ExpiresOn','ConnectedOn','GraphModule')) {
        $script:ToolGraphContext[$k] = if ($k -eq 'Connected' -or $k -eq 'GraphModule') { $false } else { $null }
    }
}
