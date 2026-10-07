# dotfiles-windows Profile Management
# Refactored for portability and environment awareness
#
# What:     Backup-Profile (copies $PROFILE to a backup folder) and Copy-Profile
#           (copies the repo profile over $PROFILE); used by Update-Profile.
# Loaded:   eagerly by the profile.
# Gotchas:  copying the profile predates the thin-loader design and can fight
#           with it (dotfiles-windows#33).
# Fate:     drop; chezmoi deploys the profile (P4).

# 1. Path Discovery
# Use Global DotfilesRoot if set, otherwise derive from script location
$profileScriptRoot = Split-Path -Parent $PSCommandPath
$localRepoRoot = if ($Global:DotfilesRoot) { $Global:DotfilesRoot } else { Split-Path -Parent $profileScriptRoot }

# 2. Source Discovery
$sourceDirectory = Join-Path $localRepoRoot "PowerShell"
$destinationDirectory = Split-Path -Parent $PROFILE
$profilePath = $PROFILE

function Backup-Profile {
    # Dynamically discover all OneDrive roots
    $targetRoots = Get-OneDrivePaths
    $powerShellBackupName = "PowerShell Backup"
    $backupFileName = "Microsoft.PowerShell_profile_$(Get-Date -Format 'yyyy-MM-dd').ps1"

    foreach ($root in $targetRoots) {
        $backupDirectory = Join-Path $root $powerShellBackupName
        
        # Ensure backup directory exists
        if (-not (Test-Path $backupDirectory)) {
            New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null
        }
        
        $backupFullPath = Join-Path $backupDirectory $backupFileName

        if (Test-Path $profilePath) {
            Copy-Item -Path $profilePath -Destination $backupFullPath -Force
            if (Get-Command Write-Success -ErrorAction SilentlyContinue) {
                Write-Success "Profile backed up to $backupFullPath"
            } else {
                Write-Host "Backup of PowerShell profile created at $backupFullPath" -ForegroundColor Green
            }
        }
    }
}

function Copy-Profile {
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        
        # Check if the file is a redirect loader
        $isRedirect = ($profileContent.Length -lt 1000) -and ($profileContent -match "Microsoft\.PowerShell_profile\.ps1")
        
        if ($isRedirect) {
            if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
                Write-Info "Profile is already linked to the git repo. Skipping copy."
            } else {
                Write-Host "Profile is already linked to the git repo. Skipping copy." -ForegroundColor Cyan
            }
            return
        }
    }

    try {
        $sourceFile = Join-Path $sourceDirectory "Microsoft.PowerShell_profile.ps1"
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination $destinationDirectory -Force
            if (Get-Command Write-Success -ErrorAction SilentlyContinue) {
                Write-Success "Profile updated from $sourceDirectory"
            } else {
                Write-Host "PowerShell profile updated successfully (Copied from $sourceDirectory)" -ForegroundColor Green
            }
        }
    }
    catch {
        if (Get-Command Write-TaskError -ErrorAction SilentlyContinue) {
            Write-TaskError "Error updating profile: $_"
        } else {
            Write-Host "Error updating PowerShell profile: $_" -ForegroundColor Red
        }
    }
}
