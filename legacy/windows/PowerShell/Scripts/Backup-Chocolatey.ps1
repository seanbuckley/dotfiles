# Backup-Chocolatey.ps1
#
# What:     Saves a list of installed Chocolatey packages (with reinstall
#           metadata) to every backup folder found by Get-BackupRoots.
# Loaded:   eagerly by the profile; called by `upgrade` and Backup-PackageManagers.
#           Can also be run on its own with `pwsh -File`.
# Fate:     review in Phase 4 (only needed while Chocolatey stays).

if ($PSCommandPath) {
    $scriptRoot = Split-Path -Parent $PSCommandPath

    # When this script is run directly with `pwsh -File`, load the shared helpers
    # it normally gets from the profile so it behaves the same in both modes.
    if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
        $uiHelpersPath = Join-Path $scriptRoot "UI-Helpers.ps1"
        if (Test-Path $uiHelpersPath) {
            . $uiHelpersPath
        }
    }

    if (-not (Get-Command Get-OneDrivePaths -ErrorAction SilentlyContinue)) {
        $utilitiesPath = Join-Path $scriptRoot "Utilities.ps1"
        if (Test-Path $utilitiesPath) {
            . $utilitiesPath
        }
    }
}

function Backup-Chocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-WarningMessage "Chocolatey is unavailable, so the package list backup was skipped."
        return $false
    }

    $targetRoots = @(Get-BackupRoots)
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $packageFileName = "$currentDate-$env:COMPUTERNAME-Chocolatey-Packages.config"
    $pinFileName = "$currentDate-$env:COMPUTERNAME-Chocolatey-Pins.txt"
    $programsFileName = "$currentDate-$env:COMPUTERNAME-Programs.txt"

    $ignoredLines = [System.Collections.Generic.List[string]]::new()
    $packageNames = [System.Collections.Generic.List[string]]::new()
    $rawPackageInfo = & choco list -r -y 2>&1
    $chocoExitCode = $LASTEXITCODE

    # Chocolatey can mix warnings/retry noise into the same stream as `name|version`
    # records, so we keep only parseable package rows and report the rest as ignored.
    foreach ($entry in $rawPackageInfo) {
        $line = if ($entry -is [System.Management.Automation.ErrorRecord]) {
            $entry.ToString()
        } else {
            [string]$entry
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $separatorIndex = $line.IndexOf("|")
        if ($separatorIndex -gt 0) {
            $packageName = $line.Substring(0, $separatorIndex).Trim()
            if ($packageName) {
                $packageNames.Add($packageName)
            }
            continue
        }

        $ignoredLines.Add($line.Trim())
    }

    if ($chocoExitCode -ne 0) {
        Write-TaskError "Chocolatey package enumeration exited with code $chocoExitCode."
        return $false
    }

    if ($packageNames.Count -eq 0) {
        Write-TaskError "Chocolatey package enumeration did not return any package records."
        return $false
    }

    if ($ignoredLines.Count -gt 0) {
        Write-WarningMessage ("Ignored {0} non-package line(s) while backing up Chocolatey packages." -f $ignoredLines.Count)
    }

    $packageElements = foreach ($packageName in ($packageNames | Select-Object -Unique | Sort-Object)) {
        '  <package id="{0}" />' -f [System.Security.SecurityElement]::Escape($packageName)
    }

    $packagesConfigContent = @(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<packages>'
        $packageElements
        '</packages>'
    )

    $pinOutput = & choco pin list --limit-output 2>&1
    $pinExitCode = $LASTEXITCODE
    $pinLines = [System.Collections.Generic.List[string]]::new()
    if ($pinExitCode -eq 0) {
        foreach ($entry in $pinOutput) {
            $line = if ($entry -is [System.Management.Automation.ErrorRecord]) {
                $entry.ToString()
            } else {
                [string]$entry
            }

            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            if ($line.Contains("|")) {
                $pinLines.Add($line.Trim())
            }
        }
    } elseif (Get-Command Write-WarningMessage -ErrorAction SilentlyContinue) {
        Write-WarningMessage "Chocolatey pin export failed; continuing without a pins backup."
    }

    $programLines = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Sort-Object DisplayName |
        ForEach-Object {
            if ($_.DisplayVersion) {
                "{0} | {1}" -f $_.DisplayName, $_.DisplayVersion
            } else {
                [string]$_.DisplayName
            }
        }

    $savedTargetCount = 0
    foreach ($targetRoot in ($targetRoots | Select-Object -Unique)) {
        $savePath = Join-Path $targetRoot "Backup\Chocolatey"

        try {
            New-Item -ItemType Directory -Path $savePath -Force -ErrorAction Stop | Out-Null

            $packagesConfigPath = Join-Path $savePath $packageFileName
            $packagesConfigContent | Out-File -FilePath $packagesConfigPath -Encoding ascii -ErrorAction Stop
            Write-Info "Saved Chocolatey package list to: $packagesConfigPath"

            if ($pinLines.Count -gt 0) {
                $pinPath = Join-Path $savePath $pinFileName
                $pinLines | Out-File -FilePath $pinPath -Encoding ascii -ErrorAction Stop
                Write-Info "Saved Chocolatey pin list to: $pinPath"
            }

            $programPath = Join-Path $savePath $programsFileName
            $programLines | Out-File -FilePath $programPath -Encoding utf8 -ErrorAction Stop
            Write-Info "Saved installed programs list to: $programPath"
            $savedTargetCount++
        } catch {
            Write-TaskError "Failed to save Chocolatey backups under '$savePath': $_"
        }
    }

    if ($savedTargetCount -eq 0) {
        return $false
    }

    return ($savedTargetCount -eq $targetRoots.Count)
}

Set-Alias -Name backupChocolatey -Value Backup-Chocolatey
Set-Alias -Name Backup-ChocolateyPackageList -Value Backup-Chocolatey

if ($MyInvocation.InvocationName -ne '.') {
    if (Backup-Chocolatey) {
        exit 0
    }

    exit 1
}
