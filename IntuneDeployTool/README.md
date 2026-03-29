# IntuneDeployTool

IntuneDeployTool is a production-focused, PowerShell-first WinForms desktop tool for Windows 11 bench technicians preparing devices for Windows Autopilot and Intune enrollment.

## What this tool does
- Collects local device inventory (CIM + OS + TPM + Secure Boot + network).
- Captures local Windows Autopilot hardware hash with a self-contained script (no download dependency).
- Accepts Group Tag and optional Assigned User UPN.
- Authenticates to Microsoft Graph using:
  - Interactive delegated login, or
  - App-only certificate (Tenant ID + Client ID + cert thumbprint).
- Uploads imported Windows Autopilot device identity records to Graph.
- Retrieves upload/import status.
- Optionally triggers Autopilot sync.
- Exports CSV, JSON, and session log bundles locally.
- Supports bench technician actions (rename, open settings, open Company Portal, bootstrap local admin, preflight and completion checklists).
- Adds an onboarding admin portal shell tab that reviews local placeholder onboarding requests and staged tasks (manager validation, IT approval, identity creation, stock PC assignment, image/deploy).

## Prerequisites
- Windows 11 technician station or target device.
- Run as Administrator (tool self-elevates).
- **Windows PowerShell 5.1 is the baseline target**.
- PowerShell 7+ is supported where cmdlets/API behavior match, but bench validation should be done on Windows PowerShell 5.1.
- Network connectivity to:
  - `https://graph.microsoft.com`
  - `https://login.microsoftonline.com`
- Microsoft Graph permissions configured for operator/app:
  - `DeviceManagementServiceConfig.ReadWrite.All`

## Run
```powershell
cd .\IntuneDeployTool
powershell -ExecutionPolicy Bypass -File .\Launch-IntuneDeployTool.ps1
```

## Execution policy guidance (important)
If script execution is blocked:

- **Process-scope bypass for a single launch**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\Launch-IntuneDeployTool.ps1
  ```
- **Current user policy option**:
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
  ```
- Group Policy can override local policy settings. If so, follow your enterprise policy process.

The tool does **not** make permanent execution policy changes automatically.

## Graph auth modes
### 1) Interactive delegated
- Uses `Connect-MgGraph -Scopes DeviceManagementServiceConfig.ReadWrite.All`.
- Recommended for technician/admin bench workflows.
- Supports **Azure sign-in tenant mode** in the UI, which lets the technician sign in and select tenant context without storing Tenant ID / Client ID in app settings.

### 2) App-only certificate
- Uses Tenant ID + Client ID + certificate thumbprint.
- Prefers Microsoft Graph PowerShell if available.
- Falls back to direct REST token acquisition with JWT client assertion if Graph module is unavailable.
- No password storage, no plain-text secrets.

## Required Graph permission
The tool is designed around:
- `DeviceManagementServiceConfig.ReadWrite.All`

## Local hardware hash behavior
- The collector file is bundled in-project: `powershell/Get-WindowsAutopilotInfo.ps1`.
- Hardware hash is collected from local MDM bridge class:
  - `root/cimv2/mdm/dmmap:MDM_DevDetail_Ext01.DeviceHardwareData`
- Output includes:
  - Device Serial Number
  - Windows Product ID (best effort)
  - Hardware Hash
  - Group Tag
  - Assigned User

### Capture CSV required vs optional fields
- **Required for upload:** `Device Serial Number`, `Hardware Hash`
- **Optional / best effort:** `Windows Product ID`
- The tool fails capture validation if required fields are missing.

## Group Tag behavior
- Group Tag is included in the imported Autopilot identity payload.
- Group Tag helps profile assignment/grouping logic in Intune environments.

## Device naming truth (important)
- This tool **does not** claim that a freeform typed name is embedded into hardware hash import.
- The UI includes prefix/name preview for planning only.
- Final Autopilot device naming is controlled by the assigned deployment profile template.

## OOBE / reset truth
- This tool prepares the device for Autopilot registration.
- Full OOBE and ESP validation happens only after reset/wipe.
- The same desktop app session does not continue through OOBE.

## Onboarding request review shell (new)
- The **Onboarding Requests** tab is designed as a broader IT admin portal foundation.
- It currently reads local JSON data (`data/sample-onboarding-requests.json` by default) to model request lifecycle state.
- Workflow modeled in the tab:
  1. HR enters employee in ADP.
  2. HR submits New User Setup request.
  3. Manager validates request.
  4. IT approves request.
  5. IT performs identity creation tasks.
  6. IT assigns stock PC if available.
  7. If no stock PC, IT executes image/deploy tasks.
  8. Request remains open until all tasks complete.

## Staged connector plan (SharePoint/Azure)
- Current build: local JSON/sample records only (no mandatory live Azure credentials).
- Planned next stage: connector module to pull onboarding tickets from SharePoint lists.
- Planned future stage: Azure connectors for identity/device task automation.
- The config includes `FutureConnectors` flags so tenant-specific integrations can be enabled later without redesigning the UI.

## Known limitations
- App-only auth requires certificate private key access on the local machine/user store.
- Interactive auth requires Microsoft Graph PowerShell module availability.
- Import status can be eventually consistent and may not return immediately.
- Sync can return throttling/conflict responses when service is busy.

## Packaging suggestions
- You can package `Launch-IntuneDeployTool.ps1` with `ps2exe` for operational convenience.
- Keep modules/config folder structure intact if running as script.

## Settings file
`config/settings.json` supports:
- `AppName`
- `OutputDir`
- `LogDir`
- `DefaultGroupTag`
- `DefaultAuthMode`
- `TenantId`
- `ClientId`
- `CertThumbprint`
- `OnboardingDataPath`
- `SyncAfterUpload`
- `CompanyPortalFallback`
- `WorkSchoolUri`
- `FutureConnectors` (SharePoint/Azure feature flags for staged rollout)
