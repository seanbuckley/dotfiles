# Backup-PackageManagers.ps1
#
# What:     Runs the Chocolatey, Scoop and winget backups in one go and reports
#           whether all of them succeeded.
# Loaded:   eagerly by the profile.
# Fate:     review in Phase 4.

function Backup-PackageManagers {
    $allSucceeded = $true

    if (Get-Command Backup-Chocolatey -ErrorAction SilentlyContinue) {
        Write-TaskStart "Chocolatey backup"
        Write-Host ""
        if (Backup-Chocolatey) {
            Write-TaskComplete
        } else {
            Write-TaskError "Chocolatey backup failed."
            $allSucceeded = $false
        }
    }

    if (Get-Command Backup-Winget -ErrorAction SilentlyContinue) {
        Write-TaskStart "Winget backup"
        Write-Host ""
        if (Backup-Winget) {
            Write-TaskComplete
        } else {
            Write-TaskError "Winget backup failed."
            $allSucceeded = $false
        }
    }

    if (Get-Command Backup-Scoop -ErrorAction SilentlyContinue) {
        Write-TaskStart "Scoop backup"
        Write-Host ""
        if (Backup-Scoop) {
            Write-TaskComplete
        } else {
            Write-TaskError "Scoop backup failed."
            $allSucceeded = $false
        }
    }

    return $allSucceeded
}

Set-Alias -Name backupAll -Value Backup-PackageManagers
