Set-StrictMode -Version Latest

$script:LogFilePath = $null
$script:GuiLogTextBox = $null

function Initialize-Logging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogDirectory,

        [string]$AppName = 'IntuneDeployTool'
    )

    if (-not (Test-Path -Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $fileName = '{0}_{1}.log' -f $AppName, $timestamp
    $script:LogFilePath = Join-Path -Path $LogDirectory -ChildPath $fileName
    New-Item -ItemType File -Path $script:LogFilePath -Force | Out-Null

    Write-ToolLog -Level Info -Message "Logging initialized at $script:LogFilePath"
    return $script:LogFilePath
}

function Set-GuiLogTextBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.TextBox]$TextBox
    )

    $script:GuiLogTextBox = $TextBox
}

function Get-LogFilePath {
    [CmdletBinding()]
    param()

    return $script:LogFilePath
}

function Write-ToolLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Debug', 'Info', 'Warn', 'Error')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$NoUi
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $line = "[$stamp] [$Level] $Message"

    if ($script:LogFilePath) {
        Add-Content -Path $script:LogFilePath -Value $line
    }

    switch ($Level) {
        'Error' { Write-Error -Message $Message -ErrorAction Continue }
        'Warn'  { Write-Warning $Message }
        'Debug' { Write-Verbose $Message }
        default { Write-Host $line }
    }

    if (-not $NoUi -and $script:GuiLogTextBox) {
        $append = {
            param($txt, $newLine)
            $txt.AppendText($newLine + [Environment]::NewLine)
        }
        if ($script:GuiLogTextBox.InvokeRequired) {
            $script:GuiLogTextBox.Invoke($append, @($script:GuiLogTextBox, $line)) | Out-Null
        }
        else {
            & $append $script:GuiLogTextBox $line
        }
    }
}
