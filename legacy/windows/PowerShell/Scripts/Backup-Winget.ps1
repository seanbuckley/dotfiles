# Backup-Winget.ps1
# Refactored for robust multi-root backup discovery and UI standardization
#
# What:     Exports the winget package list to every backup folder
#           (Get-BackupRoots). Restore with Restore-Winget.
# Loaded:   eagerly by the profile; called by `upgrade`.
# Fate:     port (P4).

function Backup-Winget {
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $fileName = "$currentDate-$env:COMPUTERNAME-Winget-Export.json"
    
    # Dynamically find all backup roots (OneDrive, Dropbox, fallback Documents)
    $targetRoots = @(Get-BackupRoots)
    $primaryExportPath = $null
    $savedTargetCount = 0

    foreach ($root in ($targetRoots | Select-Object -Unique)) {
        $exportDir = Join-Path $root "Backup/Winget"
        $exportFullPath = Join-Path $exportDir $fileName

        try {
            New-Item -Path $exportDir -ItemType Directory -Force -ErrorAction Stop | Out-Null

            if ($null -eq $primaryExportPath) {
                # Export once with Winget, then copy that artifact to the remaining
                # backup roots so every destination gets the same manifest.
                winget export --output $exportFullPath --nowarn 2>$null

                if ($LASTEXITCODE -eq 0 -and (Test-Path $exportFullPath)) {
                    $primaryExportPath = $exportFullPath
                } else {
                    throw "Winget export failed."
                }
            } else {
                Copy-Item -Path $primaryExportPath -Destination $exportFullPath -Force -ErrorAction Stop
            }

            if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
                Write-Info "Saved Winget backup to: $exportFullPath"
            } else {
                Write-Output "Saved Winget backup to: $exportFullPath"
            }
            $savedTargetCount++
        } catch {
            if ($null -eq $primaryExportPath) {
                if (Get-Command Write-TaskError -ErrorAction SilentlyContinue) {
                    Write-TaskError "Winget export failed."
                } else {
                    Write-Error "Winget export failed. Please verify Winget is installed."
                }
            } else {
                Write-TaskError "Failed to save Winget backup to '$exportFullPath': $_"
            }
            return $false
        }
    }

    return ($savedTargetCount -eq $targetRoots.Count)
}

Set-Alias -Name backupWinget -Value Backup-Winget
