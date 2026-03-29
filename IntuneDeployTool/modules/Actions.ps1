Set-StrictMode -Version Latest

function Rename-ToolDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$NewName
    )

    Rename-Computer -NewName $NewName -Force -ErrorAction Stop
    return "Computer rename initiated to '$NewName'. Restart required."
}

function Open-ToolWorkSchoolSettings {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Uri)

    Start-Process $Uri | Out-Null
}

function Open-ToolCompanyPortal {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FallbackUri)

    try {
        Start-Process 'companyportal:' -ErrorAction Stop | Out-Null
    }
    catch {
        Start-Process $FallbackUri | Out-Null
    }
}

function Open-ToolOutputFolder {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$OutputDir)

    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    Start-Process 'explorer.exe' -ArgumentList $OutputDir | Out-Null
}

function New-ToolBootstrapLocalAdmin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$UserName,
        [Parameter(Mandatory)] [securestring]$Password
    )

    if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
        throw "Local user '$UserName' already exists."
    }

    New-LocalUser -Name $UserName -Password $Password -PasswordNeverExpires -AccountNeverExpires -ErrorAction Stop | Out-Null
    Add-LocalGroupMember -Group 'Administrators' -Member $UserName -ErrorAction Stop
    return "Created local admin user '$UserName'."
}

function Get-ToolPreflightText {
    [CmdletBinding()]
    param()

    return @'
Preflight Checklist:
1. Verify device is on Windows 11 and running elevated.
2. Verify internet access to graph.microsoft.com and login.microsoftonline.com.
3. Capture Autopilot hardware hash successfully.
4. Validate Group Tag / Assigned User values.
5. Authenticate to Graph with required permission: DeviceManagementServiceConfig.ReadWrite.All.
6. Upload Autopilot import and review returned state.
7. Optionally trigger sync and confirm no throttle/conflict errors.
'@
}

function Get-ToolBenchCompletionText {
    [CmdletBinding()]
    param()

    return @'
Bench Completion Summary:
- Device inventory captured.
- Autopilot hardware hash captured and exported.
- Import record uploaded to Intune (if successful in this session).
- Optional sync triggered.

Important:
This tool prepares the device for Autopilot registration.
Full OOBE and Enrollment Status Page validation occurs only after reset/wipe.
The current desktop app session will not continue through OOBE.
'@
}
