# dotfiles-windows Installation Script
#
# This script is the main operator-facing entrypoint for wiring a Windows host back to the
# repo. It stays in the repository root on purpose so fresh clones can use a short,
# memorable command: `.\Install-Dotfiles.ps1`.
#
# High-level behavior:
# - make sure the user profile can run local scripts
# - wire user config files back to the repo
# - merge repo-managed Windows Terminal preferences into the host-owned settings file
# - ensure both Windows PowerShell and PowerShell 7 load the repo profile
#
# The default mode is `ManagedCopy`, which prefers durable host-owned files over direct
# symlinks so the repo can work on machines where symlink creation is restricted.
#
# Run:      .\Install-Dotfiles.ps1                  (ManagedCopy, the default; no admin)
#           .\Install-Dotfiles.ps1 -InstallMode Symlink   (admin; only .gitconfig is linked)
# Platform: Windows, PowerShell 7 or Windows PowerShell 5.1.
# Needs:    git; Windows Terminal is optional (its merge is skipped if not found).
# Writes:   an [include] in ~/.gitconfig, one loader line in each $PROFILE
#           (PowerShell 7 and 5.1, found via the real Documents folder, which may
#           be on OneDrive), and merged settings in Windows Terminal's settings.json.
# Fate:     rewrite as chezmoi run_onchange scripts (docs/architecture.md in
#           seanbuckley/dotfiles). The loader and Terminal-merge ideas are kept.

param(
    [ValidateSet("ManagedCopy", "Symlink")]
    [string]$InstallMode = "ManagedCopy"
)

$ErrorActionPreference = "Stop"

# 1. Detection & Setup
# Load lightweight shared helpers first so the rest of the script can reuse the same UI,
# path-discovery, and Terminal-resolution behavior as the verifier.
$repoRoot = $PSScriptRoot
$uiHelpers = Join-Path $repoRoot "PowerShell\Scripts\UI-Helpers.ps1"
$utilities = Join-Path $repoRoot "PowerShell\Scripts\Utilities.ps1"
if (Test-Path $uiHelpers) { . $uiHelpers }
if (Test-Path $utilities) { . $utilities }
$terminalMergeScript = Join-Path $repoRoot "PowerShell\Scripts\Merge-WindowsTerminalSettings.ps1"
if (Test-Path $terminalMergeScript) { . $terminalMergeScript }

Write-Header "Dotfiles-Windows Installation"

# 2. Check for Elevation
# ManagedCopy works in a normal user shell. Direct symlink mode is opt-in and requires
# elevation on this host, so fail early with a clear message instead of partly wiring files.
function Test-Admin {
    $uid = [Security.Principal.WindowsIdentity]::GetCurrent()
    $ptr = New-Object Security.Principal.WindowsPrincipal($uid)
    return $ptr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($InstallMode -eq "Symlink" -and -not (Test-Admin)) {
    Write-TaskError "Symlink mode requires an elevated shell on this host. Re-run as Administrator or use the default ManagedCopy mode."
    exit 1
}

# 3. Set Execution Policy
# The installer does not assume the host already allows local scripts. Setting a
# CurrentUser policy keeps the change scoped to this user profile rather than the machine.
Write-Section "Execution Policy"
try {
    # Set a sensible default for the current user to allow local scripts (like our profile) to run.
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Success "Execution policy for CurrentUser set to RemoteSigned."
}
catch {
    Write-TaskError "Failed to set execution policy. You may need to run 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser' manually."
    Write-Warning "Profile scripts may fail to load on next terminal start if the policy is too restrictive."
}

# 4. Repository Context
# Echo the resolved repo root and install mode so handoffs and screenshots make it obvious
# which checkout was used when the installer ran.
Write-Section "Repository Context"
Write-Info "Using dotfiles repo at $repoRoot"
Write-Info "Install mode: $InstallMode"

# 5. Configuration Files
# These helpers intentionally focus on user-owned files at the edge of the repo: `.gitconfig`,
# Windows Terminal settings, and PowerShell entrypoint files. The repo-owned source content
# stays in version control under this checkout.
Write-Section "Configuring Files"

function Backup-ExistingFile {
    param(
        [string]$Target,
        [string]$BackupSuffix = ".bak"
    )

    if (-not (Test-Path $Target -PathType Leaf)) {
        return
    }

    # Use a simple side-by-side backup so humans can recover quickly without needing repo
    # history or a separate restore tool.
    $backupPath = "{0}{1}" -f $Target, $BackupSuffix
    Write-Info "Backing up existing file to $backupPath"
    Copy-Item -Path $Target -Destination $backupPath -Force
}

function New-Symlink {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$IsDirectory
    )

    if (Test-Path $Target) {
        Write-Info "Skipping $Target (already exists)"
        return
    }

    # Directory links use junctions for compatibility with the common Windows tooling stack.
    $itemType = if ($IsDirectory) { "Junction" } else { "SymbolicLink" }
    Write-TaskStart ("Creating {0}: {1}" -f $itemType, (Split-Path $Target -Leaf))
    try {
        New-Item -ItemType $itemType -Path $Target -Value $Source | Out-Null
        Write-TaskComplete
    }
    catch {
        Write-TaskError $_.Exception.Message
    }
}

function Set-ManagedCopy {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$BackupExisting
    )

    $targetDir = Split-Path -Parent $Target
    if ($targetDir -and -not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    if ($BackupExisting) {
        Backup-ExistingFile -Target $Target
    }

    Write-TaskStart ("Copying {0}" -f (Split-Path $Target -Leaf))
    try {
        Copy-Item -Path $Source -Destination $Target -Force
        Write-TaskComplete
    }
    catch {
        Write-TaskError ("Failed to copy to {0}: {1}" -f $Target, $_.Exception.Message)
    }
}

function Set-GitConfigInclude {
    # `.gitconfig` is safer as a host-owned file with an include to the repo config because
    # it leaves room for machine-local credentials and ignored local overrides.
    $targetPath = Join-Path $env:USERPROFILE ".gitconfig"
    $repoGitConfig = (Join-Path $repoRoot ".gitconfig").Replace('\', '/')
    $includeBlock = @"
[include]
    path = $repoGitConfig
"@.Trim()

    if (-not (Test-Path $targetPath)) {
        Write-TaskStart "Creating user .gitconfig include"
        try {
            Set-Content -Path $targetPath -Value $includeBlock
            Write-TaskComplete
        }
        catch {
            Write-TaskError ("Failed to create {0}: {1}" -f $targetPath, $_.Exception.Message)
        }
        return
    }

    $currentContent = Get-Content $targetPath -Raw
    if ($currentContent -match [regex]::Escape($repoGitConfig)) {
        Write-Success "User .gitconfig already includes repo config."
        return
    }

    Write-TaskStart "Updating user .gitconfig include"
    try {
        Add-Content -Path $targetPath -Value ("`n{0}`n" -f $includeBlock)
        Write-TaskComplete
    }
    catch {
        Write-TaskError ("Failed to update {0}: {1}" -f $targetPath, $_.Exception.Message)
    }
}

function Get-ProfileTargets {
    $documentsDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
    return @(
        [pscustomobject]@{
            Label = "Windows PowerShell"
            Path  = Join-Path $documentsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        }
        [pscustomobject]@{
            Label = "PowerShell 7+"
            Path  = Join-Path $documentsDir "PowerShell\Microsoft.PowerShell_profile.ps1"
        }
    )
}

function Set-ProfileLoader {
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath,
        [Parameter(Mandatory)]
        [string]$ProfileLabel,
        [Parameter(Mandatory)]
        [string]$ProfileLoader
    )

    $profileDir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path $profileDir)) {
        try {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        catch {
            Write-TaskError ("Failed to create {0} profile directory at {1}: {2}" -f $ProfileLabel, $profileDir, $_.Exception.Message)
            return
        }
    }

    if (Test-Path $ProfilePath) {
        $currentContent = Get-Content $ProfilePath -Raw
        if ($currentContent -match [regex]::Escape($ProfileLoader)) {
            Write-Success ("{0} profile already contains dotfiles loader." -f $ProfileLabel)
        }
        else {
            Write-Info ("Appending dotfiles loader to {0} profile at {1}" -f $ProfileLabel, $ProfilePath)
            Backup-ExistingFile -Target $ProfilePath
            try {
                Add-Content -Path $ProfilePath -Value "`n$ProfileLoader"
                Write-Success ("{0} profile updated." -f $ProfileLabel)
            }
            catch {
                Write-TaskError ("Failed to update {0} profile at {1}: {2}" -f $ProfileLabel, $ProfilePath, $_.Exception.Message)
            }
        }
    }
    else {
        Write-Info ("Creating new {0} profile at {1}" -f $ProfileLabel, $ProfilePath)
        try {
            Set-Content -Path $ProfilePath -Value $ProfileLoader
            Write-Success ("{0} profile created." -f $ProfileLabel)
        }
        catch {
            Write-TaskError ("Failed to create {0} profile at {1}: {2}" -f $ProfileLabel, $ProfilePath, $_.Exception.Message)
        }
    }
}

# Wire Git first because it has the least host-specific behavior and gives an early signal
# that the installer can write to user-owned config files.
if ($InstallMode -eq "Symlink") {
    New-Symlink -Source (Join-Path $repoRoot ".gitconfig") -Target (Join-Path $env:USERPROFILE ".gitconfig")
}
else {
    Set-GitConfigInclude
}

# Merge Windows Terminal settings into the host-owned file rather than replacing the file.
# This preserves Terminal-generated defaults and other host-local customizations while still
# enforcing the repo's shared actions, profiles, schemes, and defaults.
if (Get-Command Invoke-DotfilesWindowsTerminalMerge -ErrorAction SilentlyContinue) {
    $templatePath = Join-Path $repoRoot "Windows Terminal\settings.merge-template.json"
    # Resolve the target path before invoking the merge helper so the installer owns the
    # user-facing diagnostics and avoids ambiguity from older globally loaded helpers.
    $resolvedTerminalSettings = $null
    if (Get-Command Resolve-WindowsTerminalSettingsPath -ErrorAction SilentlyContinue) {
        $resolvedTerminalSettings = Resolve-WindowsTerminalSettingsPath
    }

    if ($resolvedTerminalSettings -and -not $resolvedTerminalSettings.Found) {
        Write-Info "Windows Terminal settings file not found. Skipping Terminal merge. $($resolvedTerminalSettings.Detail)"
    }
    elseif ($resolvedTerminalSettings -and -not $resolvedTerminalSettings.Accessible) {
        Write-Info "Unable to inspect Windows Terminal settings at $($resolvedTerminalSettings.Path). Skipping Terminal merge. $($resolvedTerminalSettings.Detail)"
    }
    else {
        $settingsPath = if ($resolvedTerminalSettings) {
            $resolvedTerminalSettings.Path
        } else {
            Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        }

        # Use positional arguments against the repo-specific helper name so an already-loaded
        # generic helper in the interactive profile cannot capture `-TemplatePath`.
        Invoke-DotfilesWindowsTerminalMerge $settingsPath $templatePath
    }
}
else {
    Write-Info "Windows Terminal merge script not available. Skipping Terminal settings."
}

# 6. Configure PowerShell Profile
# Always wire both Windows PowerShell and PowerShell 7. Users bounce between hosts and tools,
# and keeping both entrypoints aligned avoids "works in one shell but not the other" drift.
Write-Section "Configuring PowerShell Profile"
$profileLoader = ". `"$repoRoot\PowerShell\Microsoft.PowerShell_profile.ps1`""

foreach ($target in Get-ProfileTargets) {
    Set-ProfileLoader -ProfilePath $target.Path -ProfileLabel $target.Label -ProfileLoader $profileLoader
}

Write-Host ""
Write-Header "Installation Complete"
if ($InstallMode -eq "ManagedCopy") {
    Write-Info "Managed-copy mode keeps repo edits separate from live app config until you re-run the installer."
}
Write-Info "Please restart your terminal to apply changes."
Write-Host ""
