# Backup-Scoop.ps1
# Refactored for robust multi-root backup discovery and UI standardization
#
# What:     Exports the Scoop app list to every backup folder (Get-BackupRoots).
# Loaded:   eagerly by the profile; called by `upgrade`.
# Fate:     review in Phase 4 (only needed while Scoop stays).

function Backup-Scoop {
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $fileName = "$currentDate-$env:COMPUTERNAME-Scoop-Export.json"
    
    # Dynamically find all backup roots (OneDrive, Dropbox, fallback Documents)
    $targetRoots = @(Get-BackupRoots)
    $primaryExportPath = $null
    $savedTargetCount = 0

    foreach ($root in ($targetRoots | Select-Object -Unique)) {
        $exportDir = Join-Path $root "Backup/Scoop"
        $exportFullPath = Join-Path $exportDir $fileName

        try {
            New-Item -Path $exportDir -ItemType Directory -Force -ErrorAction Stop | Out-Null

            if ($null -eq $primaryExportPath) {
                # Export once with Scoop, then copy that artifact to the remaining
                # backup roots so every destination gets the same manifest.
                scoop export -c > $exportFullPath

                if ($LASTEXITCODE -eq 0 -and (Test-Path $exportFullPath)) {
                    $primaryExportPath = $exportFullPath
                } else {
                    throw "Scoop export failed."
                }
            } else {
                Copy-Item -Path $primaryExportPath -Destination $exportFullPath -Force -ErrorAction Stop
            }

            if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
                Write-Info "Saved Scoop backup to: $exportFullPath"
            } else {
                Write-Output "Saved Scoop backup to: $exportFullPath"
            }
            $savedTargetCount++
        } catch {
            if ($null -eq $primaryExportPath) {
                if (Get-Command Write-TaskError -ErrorAction SilentlyContinue) {
                    Write-TaskError "Scoop export failed."
                } else {
                    Write-Error "Scoop export failed. Please verify Scoop is installed."
                }
            } else {
                Write-TaskError "Failed to save Scoop backup to '$exportFullPath': $_"
            }
            return $false
        }
    }

    return ($savedTargetCount -eq $targetRoots.Count)
}

Set-Alias -Name backupScoop -Value Backup-Scoop
