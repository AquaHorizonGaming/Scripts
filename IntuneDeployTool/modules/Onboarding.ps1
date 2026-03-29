Set-StrictMode -Version Latest

function Get-OnboardingSampleDataPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath
    )

    return Join-Path -Path $BasePath -ChildPath 'data/sample-onboarding-requests.json'
}

function Import-OnboardingRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Onboarding request data file not found: $Path"
    }

    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $data = $raw | ConvertFrom-Json
    if ($data -isnot [System.Collections.IEnumerable]) {
        return @($data)
    }

    return @($data)
}

function Get-OnboardingTaskRows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Request
    )

    return @(
        [pscustomobject]@{ Task = 'HR entered employee in ADP'; Status = 'Completed'; Owner = 'HR' }
        [pscustomobject]@{ Task = 'Manager validation'; Status = [string]$Request.ManagerValidation; Owner = 'Manager' }
        [pscustomobject]@{ Task = 'IT approval'; Status = [string]$Request.ITApproval; Owner = 'IT' }
        [pscustomobject]@{ Task = 'Identity creation'; Status = [string]$Request.IdentityCreation; Owner = 'IT Identity' }
        [pscustomobject]@{ Task = 'Stock PC assignment'; Status = [string]$Request.StockPcAssignment; Owner = 'IT Endpoint' }
        [pscustomobject]@{ Task = 'Image / deploy tasks'; Status = [string]$Request.ImageDeploy; Owner = 'IT Endpoint' }
    )
}

function Convert-OnboardingRequestToDisplayText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Request
    )

    $lines = @(
        "Request ID: $($Request.RequestId)",
        "Employee Name: $($Request.EmployeeName)",
        "Department: $($Request.Department)",
        "Title: $($Request.Title)",
        "Start Date: $($Request.StartDate)",
        "Manager: $($Request.Manager)",
        "Overall Status: $($Request.OverallStatus)",
        "Notes: $($Request.Notes)",
        '',
        'Workflow Progress:',
        "- Manager Validation: $($Request.ManagerValidation)",
        "- IT Approval: $($Request.ITApproval)",
        "- Identity Creation: $($Request.IdentityCreation)",
        "- Stock PC Assignment: $($Request.StockPcAssignment)",
        "- Image/Deploy Tasks: $($Request.ImageDeploy)",
        '',
        'Important: Keep onboarding request open until all tasks are complete.'
    )

    return ($lines -join "`r`n")
}
