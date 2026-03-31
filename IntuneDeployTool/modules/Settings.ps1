Set-StrictMode -Version Latest

function Get-DefaultToolSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath
    )

    return [ordered]@{
        AppName               = 'IntuneDeployTool'
        OutputDir             = Join-Path -Path $BasePath -ChildPath 'output'
        LogDir                = Join-Path -Path $BasePath -ChildPath 'logs'
        DefaultGroupTag       = ''
        DefaultAuthMode       = 'Auto'
        TenantId              = ''
        ClientId              = ''
        CertThumbprint        = ''
        OnboardingDataPath    = Join-Path -Path $BasePath -ChildPath 'data/sample-onboarding-requests.json'
        SyncAfterUpload       = $true
        CompanyPortalFallback = 'ms-windows-store://pdp/?productid=9WZDNCRFJ3PZ'
        WorkSchoolUri         = 'ms-settings:workplace'
        FutureConnectors      = [ordered]@{
            SharePointEnabled = $false
            AzureIdentityEnabled = $false
            IntuneTicketLinkEnabled = $false
        }
    }
}

function Resolve-ToolPathSetting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$Value
    )

    if ([System.IO.Path]::IsPathRooted($Value)) {
        return $Value
    }

    return Join-Path -Path $BasePath -ChildPath $Value
}

function Import-ToolSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$BasePath
    )

    $defaults = Get-DefaultToolSettings -BasePath $BasePath
    $merged = [ordered]@{}
    foreach ($key in $defaults.Keys) {
        $merged[$key] = $defaults[$key]
    }

    if (Test-Path -Path $ConfigPath) {
        try {
            $json = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            foreach ($p in $json.PSObject.Properties) {
                $merged[$p.Name] = $p.Value
            }
        }
        catch {
            throw "Failed to parse settings file '$ConfigPath'. $_"
        }
    }

    $merged.OutputDir = Resolve-ToolPathSetting -BasePath $BasePath -Value $merged.OutputDir
    $merged.LogDir = Resolve-ToolPathSetting -BasePath $BasePath -Value $merged.LogDir
    $merged.OnboardingDataPath = Resolve-ToolPathSetting -BasePath $BasePath -Value $merged.OnboardingDataPath

    foreach ($dir in @($merged.OutputDir, $merged.LogDir)) {
        if (-not (Test-Path -Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    return [pscustomobject]$merged
}
