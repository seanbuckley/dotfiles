# dotfiles-windows System Update Script
# Automated updates for system tools and packages
#
# What:     The `upgrade` command: Chocolatey, winget, Microsoft Store, Scoop,
#           Node/npm and Windows Update in one run, with a summary, a log and a
#           single UAC prompt (gsudo cache). See Get-Help Update-System.
# Loaded:   lazily; the profile defines `upgrade`/`Update-System` as wrappers
#           that load this file on first use.
# Local settings: DotfilesUpgradeSettings (skip lists, blocked winget ids).
# Logs:     %LOCALAPPDATA%\dotfiles-windows\upgrade-logs (last 20 runs).
# Fate:     port and extend: add vite-plus, PowerShell modules, chezmoi, an
#           optional WSL step; drop nvm (docs/upgrades.md, P4.05).

function Update-System {
    <#
    .SYNOPSIS
    Updates package managers, runtimes, and Windows in one run.

    .DESCRIPTION
    Runs every available step by default. Use -Only or -Skip to pick steps, and -Help to print
    a short usage summary. Step names: Profile, Chocolatey, Winget, Store, Scoop, Node, Npm,
    WindowsUpdate.

    .EXAMPLE
    upgrade -Only Winget,Store

    .EXAMPLE
    upgrade -Skip WindowsUpdate
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Profile", "Chocolatey", "Winget", "Store", "Scoop", "Node", "Npm", "WindowsUpdate")]
        [string[]]$Only,

        [ValidateSet("Profile", "Chocolatey", "Winget", "Store", "Scoop", "Node", "Npm", "WindowsUpdate")]
        [string[]]$Skip,

        [switch]$Help
    )

    $upgradeStepNames = @("Profile", "Chocolatey", "Winget", "Store", "Scoop", "Node", "Npm", "WindowsUpdate")

    if ($Help) {
        Write-Host ""
        Write-Host "upgrade [-Only <steps>] [-Skip <steps>] [-Help]" -ForegroundColor White
        Write-Host ""
        Write-Host "  Steps:   $($upgradeStepNames -join ', ')" -ForegroundColor Gray
        Write-Host "  Examples:" -ForegroundColor Gray
        Write-Host "    upgrade                        # everything" -ForegroundColor DarkGray
        Write-Host "    upgrade -Only Winget,Store     # just Winget and Microsoft Store" -ForegroundColor DarkGray
        Write-Host "    upgrade -Skip WindowsUpdate    # everything except Windows Update" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Local settings (DotfilesUpgradeSettings): WingetBlockedIds, WingetNoElevationIds," -ForegroundColor Gray
        Write-Host "  ChocolateyExcludedPackages" -ForegroundColor Gray
        Write-Host ""
        return
    }

    # Ensure shared utilities are loaded for Admin checks
    $scriptRoot = Split-Path -Parent $PSCommandPath
    if ($scriptRoot) {
        $utilitiesPath = Join-Path $scriptRoot "Utilities.ps1"
        if (Test-Path $utilitiesPath) { . $utilitiesPath }

        # Ensure UI helpers are loaded so functions like Write-Success and Write-TaskStart are available.
        if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
            $uiHelpersPath = Join-Path $scriptRoot "UI-Helpers.ps1"
            if (Test-Path $uiHelpersPath) { . $uiHelpersPath }
        }
    }

    function Test-CanRunElevated {
        if (Get-Command Test-Administrator -ErrorAction SilentlyContinue) {
            return (Test-Administrator)
        }

        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-UpgradeStepSelected {
        param(
            [string]$Name
        )

        if ($Only -and $Name -notin $Only) { return $false }
        if ($Skip -and $Name -in $Skip) { return $false }
        return $true
    }

    function Add-UpgradeResult {
        param(
            [string]$Step,
            [string]$Status,
            [string]$Detail
        )

        $script:upgradeResults.Add([pscustomobject]@{
                Step   = $Step
                Status = $Status
                Detail = $Detail
            })
    }

    function Complete-UpgradeStep {
        param(
            [string]$Step,
            [string]$Detail = "Completed."
        )

        if (Get-Command Write-Success -ErrorAction SilentlyContinue) {
            Write-Success "$Step completed"
        }
        else {
            Write-Host "✅ $Step completed" -ForegroundColor Green
        }
        Add-UpgradeResult -Step $Step -Status "OK" -Detail $Detail
    }

    function Fail-UpgradeStep {
        param(
            [string]$Step,
            [string]$Detail
        )

        Write-Host ""
        Write-TaskError $Detail
        Add-UpgradeResult -Step $Step -Status "ERR" -Detail $Detail
    }

    function Note-UpgradeStep {
        param(
            [string]$Step,
            [string]$Detail
        )

        Write-Host ""
        Write-WarningMessage $Detail
        Add-UpgradeResult -Step $Step -Status "NOTE" -Detail $Detail
    }

    function Skip-UpgradeStep {
        param(
            [string]$Step,
            [string]$Detail
        )

        Write-Host ""
        Write-WarningMessage $Detail
        Add-UpgradeResult -Step $Step -Status "SKIP" -Detail $Detail
    }

    function Write-UpgradeSummary {
        Write-Section "Upgrade Summary"
        foreach ($result in $script:upgradeResults) {
            $statusColor = switch ($result.Status) {
                "OK" { "Green" }
                "ERR" { "Red" }
                "SKIP" { "Yellow" }
                "NOTE" { "Cyan" }
                Default { "White" }
            }

            Write-Host ("[{0}]" -f $result.Status).PadRight(9) -ForegroundColor $statusColor -NoNewline
            Write-Host $result.Step -ForegroundColor White

            if ($result.Detail) {
                Write-Host ("       {0}" -f $result.Detail) -ForegroundColor DarkGray
            }
        }
    }

    function Write-UpgradeFollowUp {
        $manualItems = @(
            $script:upgradeResults | Where-Object {
                $_.Status -in @("ERR", "SKIP") -and (
                    $_.Step -like "Winget:*" -or
                    $_.Step -like "Chocolatey*" -or
                    $_.Step -eq "Winget upgrades"
                )
            }
        )

        if ($manualItems.Count -eq 0) {
            return
        }

        Write-Section "Needs Manual Follow-Up"
        foreach ($item in $manualItems) {
            $label = if ($item.Status -eq "ERR") { "[ERR]" } else { "[SKIP]" }
            Write-Host ("{0} {1}" -f $label.PadRight(8), $item.Step) -ForegroundColor Yellow
            if ($item.Detail) {
                Write-Host ("       {0}" -f $item.Detail) -ForegroundColor DarkGray
            }
        }
    }

    function Get-UpgradeSettingList {
        param(
            [string]$Name
        )

        if ($Global:DotfilesUpgradeSettings -is [System.Collections.IDictionary] -and $Global:DotfilesUpgradeSettings.Contains($Name)) {
            return @($Global:DotfilesUpgradeSettings[$Name]) | Where-Object { $_ }
        }

        return @()
    }

    function Format-UpgradeDuration {
        param(
            [TimeSpan]$Duration
        )

        if ($Duration.TotalHours -ge 1) {
            return "{0}h {1:00}m" -f [int][math]::Floor($Duration.TotalHours), $Duration.Minutes
        }
        if ($Duration.TotalMinutes -ge 1) {
            return "{0}m {1:00}s" -f $Duration.Minutes, $Duration.Seconds
        }
        return "{0}s" -f [int][math]::Round($Duration.TotalSeconds)
    }

    function Set-UpgradeWindowTitle {
        param(
            [string]$Title
        )

        # Best-effort: the tab title keeps progress visible while the window is in the background.
        try { $Host.UI.RawUI.WindowTitle = $Title } catch { }
    }

    function Start-UpgradeLog {
        # Keep a timestamped transcript under LOCALAPPDATA so a long unattended run can be reviewed later.
        $logRoot = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [System.IO.Path]::GetTempPath() }
        $logDirectory = Join-Path $logRoot "dotfiles-windows\upgrade-logs"

        try {
            New-Item -ItemType Directory -Path $logDirectory -Force -ErrorAction Stop | Out-Null
            Get-ChildItem -Path $logDirectory -Filter "upgrade-*.log" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -Skip 20 |
            Remove-Item -Force -ErrorAction SilentlyContinue

            $logPath = Join-Path $logDirectory ("upgrade-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
            Start-Transcript -Path $logPath -ErrorAction Stop | Out-Null
            return $logPath
        }
        catch {
            Write-WarningMessage "Could not start the upgrade log: $($_.Exception.Message)"
            return $null
        }
    }

    function Test-UpgradeRebootPending {
        $rebootKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        )

        foreach ($key in $rebootKeys) {
            if (Test-Path -LiteralPath $key -ErrorAction SilentlyContinue) {
                return $true
            }
        }

        return $script:upgradeRebootRequested
    }

    function Send-UpgradeFinishedNotice {
        param(
            [string]$Message
        )

        # Silent toast when the optional BurntToast module is installed; the tab title covers the rest.
        if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
            try {
                Import-Module BurntToast -ErrorAction Stop
                New-BurntToastNotification -Text "Upgrade finished", $Message -Silent -ErrorAction Stop
            }
            catch { }
        }
    }

    function Get-WingetUpgradeCandidates {
        # Redirect stderr to null to suppress non-fatal warnings like metadata mismatches during enumeration
        $lines = & winget upgrade --accept-source-agreements --disable-interactivity 2>$null
        $exitCode = $LASTEXITCODE
        # 0x8A150004 (-1978335212) is a metadata mismatch, which is non-fatal for checking updates.
        if ($exitCode -ne 0 -and $exitCode -ne -1978335212) {
            throw "Unable to enumerate Winget upgrades. winget exited with code $exitCode."
        }

        $candidates = @()
        foreach ($line in $lines) {
            # Packages listed after these notices are pinned or need explicit targeting, so a plain
            # `winget upgrade --id` would fail on them. Stop before they are treated as upgradable.
            if ($line -match 'explicit targeting' -or $line -match 'pins? that prevent') {
                break
            }

            if ($line -match '^\s*$' -or $line -match '^\s*Name\s{2,}' -or $line -match '^-{3,}' -or $line -match 'upgrades? available\.$') {
                continue
            }

            # winget prints a text table, not data. Columns are split on runs of two or
            # more spaces, which breaks if winget shortens a long name or a name itself
            # contains two spaces. Such a row is dropped (fewer than 4 columns) or gets
            # the wrong Id, in which case its `winget upgrade --id` call just fails.
            $columns = ($line -split '\s{2,}') | Where-Object { $_ }
            if ($columns.Count -ge 4) {
                $candidates += [pscustomobject]@{
                    Name      = $columns[0].Trim()
                    Id        = $columns[1].Trim()
                    Version   = $columns[2].Trim()
                    Available = $columns[3].Trim()
                }
            }
        }

        return $candidates
    }

    if (Get-Command Write-Header -ErrorAction SilentlyContinue) {
        Write-Header "System Maintenance & Updates"
    }
    else {
        Write-Host "`n--- System Maintenance & Updates ---`n" -ForegroundColor Blue
    }

    if (-not $Only -and -not $Skip) {
        Write-Host "Tip: upgrade -Only Winget,Store | upgrade -Skip WindowsUpdate | upgrade -Help" -ForegroundColor DarkGray
    }
    else {
        $selectedSteps = @($upgradeStepNames | Where-Object { Test-UpgradeStepSelected $_ })
        Write-Info "Selected steps: $($selectedSteps -join ', ')"
    }

    $script:upgradeResults = [System.Collections.Generic.List[object]]::new()
    $script:upgradeRebootRequested = $false
    $gsudoCommand = Get-Command gsudo -ErrorAction SilentlyContinue
    $isAdmin = Test-CanRunElevated
    $canRunElevatedSteps = $isAdmin
    $needsElevation = (Test-UpgradeStepSelected "Chocolatey") -or (Test-UpgradeStepSelected "Winget") -or (Test-UpgradeStepSelected "WindowsUpdate")
    $useGsudoCache = $gsudoCommand -and $needsElevation
    $wingetBlockedIds = Get-UpgradeSettingList -Name "WingetBlockedIds"
    $wingetNoElevationIds = Get-UpgradeSettingList -Name "WingetNoElevationIds"
    $chocoExcludedPackages = Get-UpgradeSettingList -Name "ChocolateyExcludedPackages"
    $originalWindowTitle = $null
    try { $originalWindowTitle = $Host.UI.RawUI.WindowTitle } catch { }
    $runTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $logPath = Start-UpgradeLog

    Write-Section "Preflight"

    if ($useGsudoCache) {
        Write-TaskStart "Priming Windows elevation"
        Write-Host ""
        # Keep the cache open until the finally block turns it off. gsudo's default 5-minute idle
        # timeout expires during long non-elevated stretches and causes a second UAC prompt.
        gsudo cache on --duration -1
        if ($LASTEXITCODE -ne 0) {
            # Older gsudo builds may reject the duration switch; fall back to the default cache.
            gsudo cache on
        }
        if ($LASTEXITCODE -eq 0) {
            $canRunElevatedSteps = $true
            Complete-UpgradeStep -Step "Windows elevation cache" -Detail "Elevation approved at the start of the run."
        }
        else {
            $canRunElevatedSteps = $false
            Fail-UpgradeStep -Step "Windows elevation cache" -Detail "gsudo cache on exited with code $LASTEXITCODE."
        }
    }
    elseif (-not $needsElevation) {
        Write-Info "No selected step needs elevation."
    }
    elseif ($isAdmin) {
        Add-UpgradeResult -Step "Windows elevation cache" -Status "OK" -Detail "Already running in an elevated shell."
        Write-Success "Using the current elevated shell for admin-required steps."
    }
    else {
        Add-UpgradeResult -Step "Windows elevation cache" -Status "SKIP" -Detail "gsudo is unavailable and the shell is not elevated."
        Write-WarningMessage "Admin-required Windows steps may be skipped because gsudo is unavailable and the shell is not elevated."
    }

    try {
        if ((Test-UpgradeStepSelected "Profile") -and (Get-Command Backup-Profile -ErrorAction SilentlyContinue)) {
            Write-Section "Profile Maintenance"
            Write-TaskStart "Backing up profile"
            Write-Host ""
            try {
                Backup-Profile
                Complete-UpgradeStep -Step "Profile backup"
            }
            catch {
                Fail-UpgradeStep -Step "Profile backup" -Detail $_.Exception.Message
            }
        }

        Write-Section "Package Updates"

        if ((Test-UpgradeStepSelected "Chocolatey") -and (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Info "Updating via Chocolatey..."

            Write-TaskStart "Chocolatey upgrades"
            Write-Host ""
            $chocoArgs = @("upgrade", "all", "-y", "--no-progress")
            if ($chocoExcludedPackages.Count -gt 0) {
                $chocoArgs += "--except=$($chocoExcludedPackages -join ",")"
            }

            if ($gsudoCommand -and $canRunElevatedSteps) {
                gsudo choco @chocoArgs
                if ($LASTEXITCODE -eq 0) {
                    $detail = if ($chocoExcludedPackages.Count -gt 0) { "Excluded packages: $($chocoExcludedPackages -join ", ")" } else { "Completed." }
                    Complete-UpgradeStep -Step "Chocolatey upgrades" -Detail $detail
                }
                else {
                    Fail-UpgradeStep -Step "Chocolatey upgrades" -Detail "Chocolatey exited with code $LASTEXITCODE."
                }
            }
            elseif ($isAdmin) {
                choco @chocoArgs
                if ($LASTEXITCODE -eq 0) {
                    $detail = if ($chocoExcludedPackages.Count -gt 0) { "Excluded packages: $($chocoExcludedPackages -join ", ")" } else { "Completed." }
                    Complete-UpgradeStep -Step "Chocolatey upgrades" -Detail $detail
                }
                else {
                    Fail-UpgradeStep -Step "Chocolatey upgrades" -Detail "Chocolatey exited with code $LASTEXITCODE."
                }
            }
            else {
                Skip-UpgradeStep -Step "Chocolatey upgrades" -Detail "Admin rights or gsudo are unavailable."
            }

            if (Get-Command Backup-Chocolatey -ErrorAction SilentlyContinue) {
                Write-TaskStart "Backing up Chocolatey package list"
                Write-Host ""
                if (Backup-Chocolatey) {
                    Complete-UpgradeStep -Step "Chocolatey package list backup"
                }
                else {
                    Fail-UpgradeStep -Step "Chocolatey package list backup" -Detail "Chocolatey package list backup did not complete."
                }
            }
        }

        $runWinget = Test-UpgradeStepSelected "Winget"
        $runStore = Test-UpgradeStepSelected "Store"
        if (($runWinget -or $runStore) -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Info "Updating via Winget..."

            if ($runWinget) {
                Write-TaskStart "Winget source update"
                Write-Host ""
                & winget source update --disable-interactivity
                $wingetSourceExitCode = $LASTEXITCODE
                if ($wingetSourceExitCode -eq 0) {
                    Complete-UpgradeStep -Step "Winget source update"
                }
                else {
                    Fail-UpgradeStep -Step "Winget source update" -Detail "Winget source update exited with code $wingetSourceExitCode."
                }

                $wingetEnumerationFailed = $false
                try {
                    $wingetCandidates = @(Get-WingetUpgradeCandidates)
                }
                catch {
                    Write-TaskStart "Winget upgrades"
                    Fail-UpgradeStep -Step "Winget upgrades" -Detail $_.Exception.Message
                    $wingetEnumerationFailed = $true
                    $wingetCandidates = @()
                }

                if (-not $wingetEnumerationFailed -and $wingetCandidates.Count -eq 0) {
                    Add-UpgradeResult -Step "Winget upgrades" -Status "OK" -Detail "No Winget upgrades are pending."
                }
                else {
                    foreach ($blocked in ($wingetCandidates | Where-Object { $_.Id -in $wingetBlockedIds })) {
                        Add-UpgradeResult -Step "Winget: $($blocked.Id)" -Status "SKIP" -Detail "Blocked by DotfilesUpgradeSettings."
                        Write-WarningMessage "Skipping Winget package '$($blocked.Id)' because it is blocked in DotfilesUpgradeSettings."
                    }

                    $wingetQueue = @($wingetCandidates | Where-Object { $_.Id -notin $wingetBlockedIds })
                    $wingetTotal = $wingetQueue.Count
                    # Run winget itself elevated so each installer inherits the cached token instead of
                    # raising its own UAC prompt. An already-elevated shell needs no wrapper.
                    $elevateWinget = $gsudoCommand -and $canRunElevatedSteps -and -not $isAdmin

                    # Installer results that need attention but are not failures of the run itself.
                    $wingetNoticeCodes = @{
                        ([int]0x8A15002B) = "No applicable update for this system. The app may need a manual upgrade."
                        ([int]0x8A15010D) = "Already installed at this version."
                        ([int]0x8A150101) = "The app is running. Close it and run 'upgrade -Only Winget' again."
                        ([int]0x8A150103) = "A file is in use. Close the app and run 'upgrade -Only Winget' again."
                        ([int]0x8A150109) = "Installed; a restart is required to finish."
                    }

                    if ($wingetTotal -gt 0) {
                        Write-Info "$wingetTotal Winget upgrade(s) queued:"
                        for ($i = 0; $i -lt $wingetTotal; $i++) {
                            $queued = $wingetQueue[$i]
                            Write-Host ("  {0,3}. {1}  {2} -> {3}" -f ($i + 1), $queued.Name, $queued.Version, $queued.Available) -ForegroundColor DarkGray
                        }
                    }

                    $wingetTimer = [System.Diagnostics.Stopwatch]::StartNew()
                    for ($i = 0; $i -lt $wingetTotal; $i++) {
                        $package = $wingetQueue[$i]
                        $position = $i + 1
                        $eta = if ($i -gt 0) {
                            $remaining = [TimeSpan]::FromSeconds(($wingetTimer.Elapsed.TotalSeconds / $i) * ($wingetTotal - $i))
                            "~$(Format-UpgradeDuration $remaining) left"
                        }
                        else {
                            "estimating time left"
                        }

                        Set-UpgradeWindowTitle "Upgrade: Winget $position/$wingetTotal - $($package.Name)"
                        Write-Host ""
                        Write-TaskStart "[$position/$wingetTotal] Winget: $($package.Id)"
                        Write-Host ("{0} elapsed, {1}" -f (Format-UpgradeDuration $wingetTimer.Elapsed), $eta) -ForegroundColor DarkGray

                        $wingetArgs = @("upgrade", "--id", $package.Id, "--exact", "--silent", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity")
                        $packageTimer = [System.Diagnostics.Stopwatch]::StartNew()
                        if ($elevateWinget -and $package.Id -notin $wingetNoElevationIds) {
                            gsudo winget @wingetArgs
                        }
                        else {
                            & winget @wingetArgs
                        }
                        $exitCode = $LASTEXITCODE
                        $packageDuration = Format-UpgradeDuration $packageTimer.Elapsed

                        if ($exitCode -eq 0) {
                            Complete-UpgradeStep -Step "Winget: $($package.Id)" -Detail "$($package.Version) -> $($package.Available) ($packageDuration)"
                        }
                        elseif ($exitCode -eq -1978335212) {
                            Note-UpgradeStep -Step "Winget: $($package.Id)" -Detail "Metadata mismatch (0x8A150004). The app may already be current or handled by another process."
                        }
                        elseif ($wingetNoticeCodes.ContainsKey([int]$exitCode)) {
                            if ($exitCode -eq [int]0x8A150109) { $script:upgradeRebootRequested = $true }
                            Note-UpgradeStep -Step "Winget: $($package.Id)" -Detail $wingetNoticeCodes[[int]$exitCode]
                        }
                        else {
                            Fail-UpgradeStep -Step "Winget: $($package.Id)" -Detail ("Winget exited with code {0} (0x{0:X8})." -f $exitCode)
                        }
                    }

                    if ($wingetTotal -gt 0) {
                        Write-Host ""
                        Write-Info "Winget upgrades finished in $(Format-UpgradeDuration $wingetTimer.Elapsed)."
                    }
                    if ($null -ne $originalWindowTitle) {
                        Set-UpgradeWindowTitle $originalWindowTitle
                    }
                }
            }

            if ($runStore) {
                Write-TaskStart "Microsoft Store updates"
                Write-Host ""
                & winget upgrade --all --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity
                $storeExitCode = $LASTEXITCODE
                if ($storeExitCode -eq 0) {
                    Complete-UpgradeStep -Step "Microsoft Store updates"
                }
                elseif ($storeExitCode -eq -1978335186) {
                    Note-UpgradeStep -Step "Microsoft Store updates" -Detail "Store version mismatch (0x8A15001E). Some apps may have been removed or updated via the Store app already."
                }
                elseif ($storeExitCode -eq -1978335212) {
                    Note-UpgradeStep -Step "Microsoft Store updates" -Detail "Metadata mismatch (0x8A150004)."
                }
                else {
                    Fail-UpgradeStep -Step "Microsoft Store updates" -Detail "Winget (msstore) exited with code $storeExitCode."
                }
            }

            if (Get-Command Backup-Winget -ErrorAction SilentlyContinue) {
                Write-TaskStart "Exporting Winget backup"
                Write-Host ""
                if (Backup-Winget) {
                    Complete-UpgradeStep -Step "Winget backup export"
                }
                else {
                    Fail-UpgradeStep -Step "Winget backup export" -Detail "Winget export failed."
                }
            }
        }

        if ((Test-UpgradeStepSelected "Scoop") -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
            Write-Info "Updating via Scoop..."
            Write-TaskStart "Scoop upgrades"
            Write-Host ""
            # Check each command; only the last exit code survives otherwise.
            $scoopFailures = @()
            scoop update
            if ($LASTEXITCODE -ne 0) { $scoopFailures += "scoop update ($LASTEXITCODE)" }
            scoop update *
            if ($LASTEXITCODE -ne 0) { $scoopFailures += "scoop update * ($LASTEXITCODE)" }
            scoop cleanup *
            if ($LASTEXITCODE -ne 0) { $scoopFailures += "scoop cleanup * ($LASTEXITCODE)" }
            if ($scoopFailures.Count -eq 0) {
                Complete-UpgradeStep -Step "Scoop upgrades"
            }
            else {
                Fail-UpgradeStep -Step "Scoop upgrades" -Detail "Failed: $($scoopFailures -join ', ')."
            }
            if (Get-Command Backup-Scoop -ErrorAction SilentlyContinue) {
                Write-TaskStart "Backing up Scoop state"
                Write-Host ""
                if (Backup-Scoop) {
                    Complete-UpgradeStep -Step "Scoop backup export"
                }
                else {
                    Fail-UpgradeStep -Step "Scoop backup export" -Detail "Scoop export failed."
                }
            }
        }

        Write-Section "Environment Updates"

        if ((Test-UpgradeStepSelected "Node") -and (Get-Command nvm -ErrorAction SilentlyContinue)) {
            Write-TaskStart "Updating Node.js (latest)"
            Write-Host ""
            nvm install latest
            if ($LASTEXITCODE -eq 0) {
                Complete-UpgradeStep -Step "Node.js install" -Detail "Latest release installed. Switch with 'nvm use latest' if needed."
            }
            else {
                Fail-UpgradeStep -Step "Node.js install" -Detail "nvm exited with code $LASTEXITCODE."
            }
        }

        if ((Test-UpgradeStepSelected "Npm") -and (Get-Command npm -ErrorAction SilentlyContinue)) {
            Write-TaskStart "Updating global NPM packages"
            Write-Host ""
            npm update -g
            if ($LASTEXITCODE -eq 0) {
                Complete-UpgradeStep -Step "Global NPM update"
            }
            else {
                Fail-UpgradeStep -Step "Global NPM update" -Detail "npm exited with code $LASTEXITCODE."
            }
        }

        if ((Test-UpgradeStepSelected "WindowsUpdate") -and (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
            Write-Section "OS Updates"
            Write-Info "Checking for Windows Updates..."
            Write-TaskStart "Windows Updates"
            Write-Host ""
            # -IgnoreReboot stops PSWindowsUpdate from pausing the run with a reboot prompt;
            # a pending restart is reported at the end instead.
            if ($gsudoCommand -and $canRunElevatedSteps) {
                gsudo Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
                if ($LASTEXITCODE -eq 0) {
                    Complete-UpgradeStep -Step "Windows Updates"
                }
                else {
                    Fail-UpgradeStep -Step "Windows Updates" -Detail "Get-WindowsUpdate exited with code $LASTEXITCODE."
                }
            }
            elseif ($isAdmin) {
                try {
                    Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -ErrorAction Stop
                    Complete-UpgradeStep -Step "Windows Updates"
                }
                catch {
                    Fail-UpgradeStep -Step "Windows Updates" -Detail $_.Exception.Message
                }
            }
            else {
                Skip-UpgradeStep -Step "Windows Updates" -Detail "Admin rights or gsudo are unavailable."
            }
        }
    }
    finally {
        if ($useGsudoCache) {
            Write-TaskStart "Disabling gsudo elevation cache"
            gsudo cache off
            if ($LASTEXITCODE -eq 0) {
                Complete-UpgradeStep -Step "Windows elevation cache cleanup"
            }
            else {
                Fail-UpgradeStep -Step "Windows elevation cache cleanup" -Detail "gsudo cache off exited with code $LASTEXITCODE."
            }
        }

        Write-UpgradeSummary
        Write-UpgradeFollowUp

        $errorCount = @($script:upgradeResults | Where-Object { $_.Status -eq "ERR" }).Count
        $skipCount = @($script:upgradeResults | Where-Object { $_.Status -eq "SKIP" }).Count
        $noteCount = @($script:upgradeResults | Where-Object { $_.Status -eq "NOTE" }).Count
        $totalTime = Format-UpgradeDuration $runTimer.Elapsed

        Write-Host ""
        if (Test-UpgradeRebootPending) {
            Write-WarningMessage "A restart is pending to finish installing updates."
        }

        if ($errorCount -eq 0 -and $skipCount -eq 0) {
            $finishMessage = "All updates complete in $totalTime."
            if ($noteCount -gt 0) { $finishMessage = "All updates complete in $totalTime ($noteCount note(s) above)." }
            Write-Success $finishMessage
        }
        else {
            $finishMessage = "Finished in $totalTime with $errorCount error(s) and $skipCount skipped step(s). See the summary above."
            if ($errorCount -gt 0) { Write-TaskError $finishMessage } else { Write-WarningMessage $finishMessage }
        }

        if ($logPath) {
            Write-Host "Log: $logPath" -ForegroundColor DarkGray
            try { Stop-Transcript | Out-Null } catch { }
        }
        Write-Host ""

        $titleStatus = if ($errorCount -gt 0) { "$errorCount error(s)" } else { "done" }
        Set-UpgradeWindowTitle "Upgrade finished - $titleStatus"
        Send-UpgradeFinishedNotice -Message $finishMessage
    }
}

Set-Alias -Name upgrade -Value Update-System
