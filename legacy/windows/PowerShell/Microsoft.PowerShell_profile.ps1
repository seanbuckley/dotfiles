# dotfiles-windows PowerShell Profile
# Machine-agnostic profile for PowerShell
#
# ==============================================================================
# What:     The main profile. Every PowerShell window runs it, via a one-line
#           "thin loader" in $PROFILE that Install-Dotfiles.ps1 writes.
# Layout:   1. repo root + timers          5. personal scripts (eager + lazy)
#           2. UI helpers                  6. prompt (oh-my-posh, cached init)
#           3. loader helpers (below)      7. gsudo
#           4. modules (some deferred)     8. vite-plus, 9. local override file
# Speed:    Startup is kept fast in three ways (DECISIONS.md 13-15):
#           - "deferred" steps run one per prompt *after* the first prompt;
#           - rarely used scripts are "lazy": a tiny wrapper loads them on first use;
#           - tool init code (zoxide, oh-my-posh) is cached under
#             %LOCALAPPDATA%\dotfiles-windows\profile-cache.
# Overrides: DOTFILES_PROFILE_ENABLE_<FEATURE>=0/1 turns optional features off/on;
#           Microsoft.PowerShell_profile.local.ps1 (next to this file, untracked)
#           runs last for machine-only tweaks.
# Platform: Windows. PowerShell 7 and 5.1 (5.1 lacks a few features; see below).
# Fate:     port to ~/.config/powershell/ in the chezmoi repo (P4.01).
# ==============================================================================

# Prevent duplicate startup work if this profile is sourced more than once
# by a thin loader, a manual dot-source, or another host-specific hook.
if ($global:DotfilesWindowsProfileLoaded) {
    return
}

# Mark the session as initialized before loading modules and scripts so
# any later attempt to source this file exits immediately.
$global:DotfilesWindowsProfileLoaded = $true

# 1. Establish the Root of the dotfiles repository
# Derived from the location of this script to ensure portability.
$profileDir = Split-Path -Parent $PSCommandPath
$Global:DotfilesRoot = Split-Path -Parent $profileDir
$isInteractiveConsole = -not ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected)
$scriptDirectory = Join-Path $profileDir "Scripts"
$profileCacheRoot = Join-Path ([System.Environment]::GetFolderPath("LocalApplicationData")) "dotfiles-windows\profile-cache"
$profileStartupTimer = [System.Diagnostics.Stopwatch]::StartNew()
$profileStepTimings = [System.Collections.Generic.List[object]]::new()
$profileDeferredStepNames = [System.Collections.Generic.List[string]]::new()
$profileDeferredSteps = [System.Collections.Generic.Queue[object]]::new()
$profileDeferredStepTimings = [System.Collections.Generic.List[object]]::new()
$profileDeferredStepErrors = [System.Collections.Generic.List[string]]::new()
$profileStartupWarnings = [System.Collections.Generic.List[string]]::new()

# 2. Load UI Helpers
$uiHelpers = Join-Path $profileDir "Scripts\UI-Helpers.ps1"
if (Test-Path $uiHelpers) {
    . $uiHelpers
}
else {
    function Write-Header { param($t) Write-Host "--- $t ---" }
    function Write-TaskStart { param($d) Write-Host -NoNewline "Loading $d... " }
    function Write-TaskComplete { Write-Host "Done" }
}

Write-Header "Welcome $($Env:UserName)"
Write-Info "PowerShell $($PSVersionTable.PSVersion)"
Write-Info "Computer: $($Env:ComputerName)"

# 3. Enhanced Loading Function
function Invoke-Step([string] $Description, [ScriptBlock]$script) {
    Write-TaskStart $Description
    $stepTimer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $script
        $stepTimer.Stop()
        $profileStepTimings.Add([pscustomobject]@{
                Name         = $Description
                Milliseconds = [math]::Round($stepTimer.Elapsed.TotalMilliseconds, 1)
                Status       = "OK"
            })
        Write-TaskComplete
    }
    catch {
        $stepTimer.Stop()
        $profileStepTimings.Add([pscustomobject]@{
                Name         = $Description
                Milliseconds = [math]::Round($stepTimer.Elapsed.TotalMilliseconds, 1)
                Status       = "ERR"
            })
        Write-TaskError $_.Exception.Message
    }
}

# Build a simple file signature from path, size, and modified time. We use this to
# decide when cached init scripts like zoxide/oh-my-posh need to be regenerated.
function Get-ProfileDependencySignature {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return "missing:$Path"
    }

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    return "{0}|{1}|{2}" -f $item.FullName, $item.Length, $item.LastWriteTimeUtc.Ticks
}

# Some profile features are helpful but expensive. This helper lets us keep a sane
# default while still allowing a local override through environment variables such as
# DOTFILES_PROFILE_ENABLE_TERMINAL_ICONS=1.
function Test-ProfileFeatureEnabled {
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName,

        [Parameter(Mandatory)]
        [bool]$Default
    )

    $normalizedName = ($FeatureName -replace '[^A-Za-z0-9]', '_').ToUpperInvariant()
    $envVarName = "DOTFILES_PROFILE_ENABLE_{0}" -f $normalizedName
    $envValue = [System.Environment]::GetEnvironmentVariable($envVarName)

    if ([string]::IsNullOrWhiteSpace($envValue)) {
        return $Default
    }

    switch -Regex ($envValue.Trim()) {
        '^(1|true|yes|on)$' { return $true }
        '^(0|false|no|off)$' { return $false }
        default { return $Default }
    }
}

# Deferred steps are profile tasks we want to keep, but not block the first prompt on.
# We queue them during startup and then run one per prompt after the shell is usable.
function Register-DeferredProfileStep {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ScriptBlock]$Action
    )

    $profileDeferredStepNames.Add($Name)
    $profileDeferredSteps.Enqueue([pscustomobject]@{
            Name   = $Name
            Action = $Action
        })
}

# Run a single deferred step and record how long it actually took once it warmed in.
#
# This runs from inside the prompt function while PSReadLine is mid-render, so it must
# stay silent. Module import progress bars, warnings, or any other host writes move the
# cursor underneath PSReadLine and corrupt its redraw bookkeeping, which shows up as
# duplicated prompt or prediction rows as you type. Failures are stashed and surfaced
# later by Show-ProfileWarmupStatus instead of being written here.
function Invoke-DeferredProfileStep {
    if ($profileDeferredSteps.Count -eq 0) {
        return $false
    }

    $step = $profileDeferredSteps.Dequeue()
    $stepTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "OK"

    $previousProgressPreference = $ProgressPreference
    $previousWarningPreference = $WarningPreference
    $previousInformationPreference = $InformationPreference

    try {
        $ProgressPreference = "SilentlyContinue"
        $WarningPreference = "SilentlyContinue"
        $InformationPreference = "SilentlyContinue"

        & $step.Action | Out-Null
    }
    catch {
        $status = "ERR"
        $profileDeferredStepErrors.Add(("Deferred step '{0}' failed: {1}" -f $step.Name, $_.Exception.Message))
    }
    finally {
        $ProgressPreference = $previousProgressPreference
        $WarningPreference = $previousWarningPreference
        $InformationPreference = $previousInformationPreference
    }

    $stepTimer.Stop()
    $profileDeferredStepTimings.Add([pscustomobject]@{
            Name         = $step.Name
            Milliseconds = [math]::Round($stepTimer.Elapsed.TotalMilliseconds, 1)
            Status       = $status
        })

    return $true
}

# Replace the prompt with a thin wrapper that leaves the first prompt fast, then
# warms one deferred feature per later prompt. This keeps startup responsive while
# still making the full shell experience appear shortly after launch.
function Enable-DeferredProfileWarmup {
    if (-not $isInteractiveConsole) {
        return
    }

    if ($profileDeferredSteps.Count -eq 0) {
        return
    }

    $existingPromptCommand = Get-Command prompt -CommandType Function -ErrorAction Stop
    $existingPrompt = $existingPromptCommand.ScriptBlock

    $script:firstPromptRendered = $false
    $script:profileWarmupPrompt = {
        # Warm up before building the prompt string, not after. The prompt function's
        # return value is what PSReadLine measures and redraws around, so anything that
        # touches the console has to happen before that string is produced.
        if (-not $script:firstPromptRendered) {
            $script:firstPromptRendered = $true
        }
        elseif ($profileDeferredSteps.Count -gt 0) {
            Invoke-DeferredProfileStep | Out-Null
        }

        return (& $existingPrompt)
    }.GetNewClosure()

    Set-Item -LiteralPath Function:\global:prompt -Value $script:profileWarmupPrompt
}

function Show-ProfileWarmupStatus {
    $loadedNames = @($profileDeferredStepTimings | ForEach-Object { $_.Name })
    $pendingNames = @($profileDeferredStepNames | Where-Object { $_ -notin $loadedNames })

    Write-Section "Warmup Status"

    if ($profileDeferredStepTimings.Count -gt 0) {
        foreach ($timing in ($profileDeferredStepTimings | Sort-Object Milliseconds -Descending)) {
            $status = if ($timing.Status -eq "OK") { "[OK]" } else { "[ERR]" }
            Write-Host ("{0} {1}" -f ("{0,7}ms" -f [int][math]::Round($timing.Milliseconds, 0)), $timing.Name.PadRight(32)) -NoNewline
            if ($timing.Status -eq "OK") {
                Write-Host $status -ForegroundColor Green
            }
            else {
                Write-Host $status -ForegroundColor Red
            }
        }
    }
    else {
        Write-Info "No deferred steps have finished yet."
    }

    if ($pendingNames.Count -gt 0) {
        Write-Info ("Still queued: {0}" -f ($pendingNames -join ", "))
    }
    else {
        Write-Success "All deferred profile steps have completed."
    }

    foreach ($message in $profileDeferredStepErrors) {
        Write-WarningMessage $message
    }
}

# Some tools emit PowerShell code at startup. Generating that code repeatedly is
# wasteful, so we cache it under LocalAppData and refresh it only when dependencies
# like the executable path or theme file change.
function Invoke-CachedProfileInit {
    param(
        [Parameter(Mandatory)]
        [string]$CacheName,

        [Parameter(Mandatory)]
        [string[]]$DependencyPaths,

        [Parameter(Mandatory)]
        [ScriptBlock]$Generator
    )

    New-Item -ItemType Directory -Path $profileCacheRoot -Force -ErrorAction SilentlyContinue | Out-Null

    $cachePath = Join-Path $profileCacheRoot "$CacheName.ps1"
    $signaturePath = Join-Path $profileCacheRoot "$CacheName.signature"
    $currentSignature = ($DependencyPaths | ForEach-Object { Get-ProfileDependencySignature -Path $_ }) -join [Environment]::NewLine
    $cachedSignature = if (Test-Path -LiteralPath $signaturePath) {
        Get-Content -LiteralPath $signaturePath -Raw -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path -LiteralPath $cachePath) -or $cachedSignature -ne $currentSignature) {
        $generatedScript = & $Generator
        if (-not [string]::IsNullOrWhiteSpace($generatedScript)) {
            # utf8NoBOM exists only in PowerShell 7. In 5.1 these two lines throw,
            # Invoke-Step catches it, and the tool simply loads uncached.
            Set-Content -LiteralPath $cachePath -Value $generatedScript -Encoding utf8NoBOM
            Set-Content -LiteralPath $signaturePath -Value $currentSignature -Encoding utf8NoBOM
        }
    }

    if (Test-Path -LiteralPath $cachePath) {
        . $cachePath
    }
}

# A few rarely used repo scripts stay lazy. We create a tiny wrapper command up front,
# then dot-source the real script only when the command is actually invoked.
function Register-LazyProfileCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [string]$ScriptFile
    )

    $aliasPath = "Alias:\{0}" -f $CommandName
    $functionPath = "Function:\{0}" -f $CommandName

    if ((Test-Path -LiteralPath $aliasPath) -or (Test-Path -LiteralPath $functionPath)) {
        return
    }

    $wrapperName = "Invoke-LazyProfileCommand_{0}" -f ($CommandName -replace '[^A-Za-z0-9_]', '_')
    # No param block: splatting the automatic $args keeps named parameters (e.g. -Only Winget)
    # bound by name, where a ValueFromRemainingArguments list would pass them positionally.
    $wrapper = {
        $scriptPath = Join-Path $scriptDirectory $ScriptFile
        if (-not (Test-Path -LiteralPath $scriptPath)) {
            throw "Profile script '$ScriptFile' was not found under '$scriptDirectory'."
        }

        . $scriptPath

        $resolvedCommand = Get-Command $CommandName -All -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -ne $wrapperName -and
            ($_.CommandType -ne 'Alias' -or $_.Definition -ne $wrapperName)
        } |
        Select-Object -First 1

        if ($null -eq $resolvedCommand) {
            throw "Lazy profile command '$CommandName' could not be resolved after loading '$ScriptFile'."
        }

        & $resolvedCommand @args
    }.GetNewClosure()

    Set-Item -LiteralPath ("Function:\global:" + $wrapperName) -Value $wrapper
    Set-Alias -Name $CommandName -Value $wrapperName -Scope Global
}

# oh-my-posh publishes POSH_THEMES_PATH from its installer, but that variable is
# removed by an uninstall and only comes back in new sessions - and some install
# methods never set it at all. Probe the locations the themes actually ship in so a
# reinstall or version upgrade cannot leave the prompt unconfigured.
function Get-PoshThemesPath {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ExecutablePath,

        # Running oh-my-posh costs a process launch on every shell start, so callers
        # only ask for this once the cheap disk probes and the vendored theme fail.
        [switch]$ProbeCachePath
    )

    $candidates = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($env:POSH_THEMES_PATH)) {
        $candidates.Add($env:POSH_THEMES_PATH)
    }

    if (-not [string]::IsNullOrWhiteSpace($ExecutablePath)) {
        $installDir = Split-Path -Parent $ExecutablePath
        if (-not [string]::IsNullOrWhiteSpace($installDir)) {
            $candidates.Add((Join-Path $installDir "themes"))

            $parentDir = Split-Path -Parent $installDir
            if (-not [string]::IsNullOrWhiteSpace($parentDir)) {
                # winget/manual layout (bin\oh-my-posh.exe next to themes\)
                $candidates.Add((Join-Path $parentDir "themes"))
                # scoop layout (shims\oh-my-posh.exe -> apps\oh-my-posh\current\themes)
                $candidates.Add((Join-Path $parentDir "apps\oh-my-posh\current\themes"))
            }
        }
    }

    foreach ($root in @(
            $env:LOCALAPPDATA,
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)}
        )) {
        if (-not [string]::IsNullOrWhiteSpace($root)) {
            $candidates.Add((Join-Path $root "Programs\oh-my-posh\themes"))
            $candidates.Add((Join-Path $root "oh-my-posh\themes"))
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ChocolateyInstall)) {
        $candidates.Add((Join-Path $env:ChocolateyInstall "lib\oh-my-posh\themes"))
        $candidates.Add((Join-Path $env:ChocolateyInstall "lib\oh-my-posh\tools\themes"))
    }

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    # Nothing on disk matched. Packaged (MSIX/Store) installs keep their data in a
    # sandboxed cache directory, so ask oh-my-posh where that is as a last resort.
    if ($ProbeCachePath -and -not [string]::IsNullOrWhiteSpace($ExecutablePath)) {
        try {
            $cachePath = & $ExecutablePath cache path 2>$null | Select-Object -First 1
            if (-not [string]::IsNullOrWhiteSpace($cachePath)) {
                $cacheThemes = Join-Path $cachePath.Trim() "themes"
                if (Test-Path -LiteralPath $cacheThemes) {
                    return (Resolve-Path -LiteralPath $cacheThemes).Path
                }
            }
        }
        catch {
            # An older oh-my-posh without the `cache` command just means no extra candidate.
        }
    }

    return $null
}

# 4. Start Loading Components

# Chocolatey profile
# Adds Chocolatey's tab completion. Runs eagerly (~100 ms); it could be deferred
# like the steps below (dotfiles-windows#63).
Invoke-Step "Chocolatey" {
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path $ChocolateyProfile) {
        Import-Module "$ChocolateyProfile"
    }
}

# posh-git
Invoke-Step "posh-git" {
    if (Test-ProfileFeatureEnabled -FeatureName "posh_git" -Default $true) {
        Register-DeferredProfileStep -Name "posh-git" -Action {
            if (Get-Module -ListAvailable posh-git) {
                Import-Module posh-git
                $env:POSH_GIT_ENABLED = $true
            }
        }
    }
}

# git-aliases
Invoke-Step "git-aliases" {
    if (Test-ProfileFeatureEnabled -FeatureName "git_aliases" -Default $true) {
        Register-DeferredProfileStep -Name "git-aliases" -Action {
            if (Get-Module -ListAvailable git-aliases) {
                Import-Module git-aliases -DisableNameChecking
            }
        }
    }
}

# PSReadLine
Invoke-Step "PSReadLine" {
    if ($isInteractiveConsole -and (Get-Module -ListAvailable PSReadLine)) {
        Import-Module PSReadLine
    }
}

# Winget Command Not Found
Invoke-Step "Winget CommandNotFound" {
    if (Test-ProfileFeatureEnabled -FeatureName "winget_command_not_found" -Default $true) {
        Register-DeferredProfileStep -Name "Winget CommandNotFound" -Action {
            if (Get-Module -ListAvailable Microsoft.WinGet.CommandNotFound) {
                Import-Module Microsoft.WinGet.CommandNotFound
            }
        }
    }
}

# Terminal-Icons
Invoke-Step "Terminal-Icons" {
    if ($isInteractiveConsole -and (Test-ProfileFeatureEnabled -FeatureName "terminal_icons" -Default $true)) {
        Register-DeferredProfileStep -Name "Terminal-Icons" -Action {
            if (Get-Module -ListAvailable Terminal-Icons) {
                Import-Module Terminal-Icons -ErrorAction Stop
            }
        }
    }
}

# z / zoxide
Invoke-Step "Z Navigation" {
    if ($isInteractiveConsole -and (Test-ProfileFeatureEnabled -FeatureName "z_navigation" -Default $true)) {
        Register-DeferredProfileStep -Name "Z Navigation" -Action {
            if (Get-Command zoxide -ErrorAction SilentlyContinue) {
                $zoxideCommand = Get-Command zoxide -ErrorAction Stop
                Invoke-CachedProfileInit -CacheName "zoxide-init" -DependencyPaths @($zoxideCommand.Source) -Generator {
                    zoxide init powershell
                }
            }
            elseif (Get-Module -ListAvailable z) {
                Import-Module z
            }
        }
    }
}

# 5. IMPORT PERSONAL SCRIPTS
Write-Section "Personal Scripts"
if (Test-Path $scriptDirectory) {
    $loadedProfileScripts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($scriptName in @(
            "Aliases.ps1",
            "Utilities.ps1",
            "PSReadLineSettings.ps1",
            "tailscale.ps1",
            "Backup-Chocolatey.ps1",
            "Backup-PackageManagers.ps1",
            "Backup-Scoop.ps1",
            "Backup-Winget.ps1",
            "Edit-Profile.ps1"
        )) {
        Write-TaskStart $scriptName
        $stepTimer = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            if ($scriptName -eq "tailscale.ps1" -and -not ($isInteractiveConsole -and (Get-Command tailscale -ErrorAction SilentlyContinue))) {
                $stepTimer.Stop()
                $profileStepTimings.Add([pscustomobject]@{
                        Name         = $scriptName
                        Milliseconds = [math]::Round($stepTimer.Elapsed.TotalMilliseconds, 1)
                        Status       = "OK"
                    })
                Write-TaskComplete
                continue
            }

            if ($loadedProfileScripts.Add($scriptName)) {
                $scriptPath = Join-Path $scriptDirectory $scriptName
                . $scriptPath
            }

            $stepTimer.Stop()
            $profileStepTimings.Add([pscustomobject]@{
                    Name         = $scriptName
                    Milliseconds = [math]::Round($stepTimer.Elapsed.TotalMilliseconds, 1)
                    Status       = "OK"
                })
            Write-TaskComplete
        }
        catch {
            $stepTimer.Stop()
            $profileStepTimings.Add([pscustomobject]@{
                    Name         = $scriptName
                    Milliseconds = [math]::Round($stepTimer.Elapsed.TotalMilliseconds, 1)
                    Status       = "ERR"
                })
            Write-TaskError $_.Exception.Message
        }
    }

    $lazyProfileScripts = [ordered]@{
        "Install-MyModule.ps1"              = @("Install-My-Module")
        "Invoke-FzfBat.ps1"                 = @("Invoke-FzfBat", "fzfb")
        "Invoke-GitPullAllSubfolders.ps1"   = @("Invoke-GitPullAllSubfolders", "glall")
        "Merge-WindowsTerminalSettings.ps1" = @("Merge-WindowsTerminalSettings")
        "Update-System.ps1"                 = @("Update-System", "upgrade")
        "Restore-Winget.ps1"                = @("Restore-Winget", "restoreWinget", "winget-restore")
        "Update-WSL.ps1"                    = @("Update-WSL", "upgradeWSL")
    }

    foreach ($entry in $lazyProfileScripts.GetEnumerator()) {
        Invoke-Step $entry.Key {
            foreach ($commandName in $entry.Value) {
                Register-LazyProfileCommand -CommandName $commandName -ScriptFile $entry.Key
            }
        }
    }
}

# 6. Prompt & Themes
Invoke-Step "oh-my-posh" {
    if ($isInteractiveConsole -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        $ompCommand = Get-Command oh-my-posh -ErrorAction Stop
        $ompThemesPath = Get-PoshThemesPath -ExecutablePath $ompCommand.Source
        $ompConfig = if ($ompThemesPath) { Join-Path $ompThemesPath "powerlevel10k_rainbow.omp.json" } else { $null }

        if ($ompThemesPath) {
            # Keep the rest of the session (and oh-my-posh itself) in sync with the
            # path we resolved, even when the installer did not export it.
            $env:POSH_THEMES_PATH = $ompThemesPath
        }

        if (-not ($ompConfig -and (Test-Path -LiteralPath $ompConfig))) {
            # Some install methods (notably packaged/Store builds) never lay the themes
            # down on disk at all, so fall back to the copy kept in this repository.
            $vendoredConfig = Join-Path $Global:DotfilesRoot "PowerShell\Themes\powerlevel10k_rainbow.omp.json"
            if (Test-Path -LiteralPath $vendoredConfig) {
                $ompConfig = $vendoredConfig
            }
            else {
                # No vendored copy either, so it is now worth paying for the slower
                # probe that asks oh-my-posh itself where its cache lives.
                $ompThemesPath = Get-PoshThemesPath -ExecutablePath $ompCommand.Source -ProbeCachePath
                if ($ompThemesPath) {
                    $env:POSH_THEMES_PATH = $ompThemesPath
                    $ompConfig = Join-Path $ompThemesPath "powerlevel10k_rainbow.omp.json"
                }
            }
        }

        if ($ompConfig -and (Test-Path -LiteralPath $ompConfig)) {
            Invoke-CachedProfileInit -CacheName "oh-my-posh-init" -DependencyPaths @($ompCommand.Source, $ompConfig) -Generator {
                oh-my-posh init pwsh --config $ompConfig
            }
        }
        else {
            # A missing theme should degrade the prompt, never break startup.
            Invoke-CachedProfileInit -CacheName "oh-my-posh-init-default" -DependencyPaths @($ompCommand.Source) -Generator {
                oh-my-posh init pwsh
            }

            $profileStartupWarnings.Add("No 'powerlevel10k_rainbow.omp.json' was found in the oh-my-posh install or in this repository's PowerShell\Themes folder; using the built-in default theme.")
        }

        if (Get-Command Enable-Poshtooltips -ErrorAction SilentlyContinue) {
            Enable-Poshtooltips
        }
    }
}

# 7. Elevation Utilities (gsudo)
Invoke-Step "gsudo" {
    if (Get-Command gsudo -ErrorAction SilentlyContinue) {
        # gsudo is in PATH, works natively
    }
    else {
        # Fallback for installs where gsudo is not on PATH: try the default
        # winget/installer location, then the Chocolatey one.
        $gsudoPath = 'C:\Program Files\gsudo\Current\gsudoModule.psd1'
        if (-not (Test-Path $gsudoPath)) { $gsudoPath = 'C:\tools\gsudo\Current\gsudoModule.psd1' }
        if (Test-Path $gsudoPath) { Import-Module $gsudoPath }
    }
}

# 8. Vite Plus environment
# This is vite-plus's older single-folder layout (~/.vite-plus). The Linux
# repo moved to the newer split layout; check which one Windows installs use.
$vitePlusEnv = Join-Path $env:USERPROFILE ".vite-plus\env.ps1"
if (Test-Path $vitePlusEnv) {
    Invoke-Step "Vite Plus" {
        . $vitePlusEnv
    }
}

# 9. LOCAL OVERRIDE
$localProfile = Join-Path $profileDir "Microsoft.PowerShell_profile.local.ps1"
if (Test-Path $localProfile) {
    Invoke-Step "Local Overrides" {
        . $localProfile
    }
}

Write-Host ""
Write-Success "Environment Ready"
Write-Host ""
$profileStartupTimer.Stop()

if ($isInteractiveConsole) {
    Write-Section "Startup Timing"

    foreach ($timing in ($profileStepTimings | Sort-Object Milliseconds -Descending | Select-Object -First 8)) {
        $status = if ($timing.Status -eq "OK") { "[OK]" } else { "[ERR]" }
        Write-Host ("{0} {1}" -f ("{0,7}ms" -f [int][math]::Round($timing.Milliseconds, 0)), $timing.Name.PadRight(32)) -NoNewline
        if ($timing.Status -eq "OK") {
            Write-Host $status -ForegroundColor Green
        }
        else {
            Write-Host $status -ForegroundColor Red
        }
    }

    Write-Info ("Profile load took {0}ms." -f [int][math]::Round($profileStartupTimer.Elapsed.TotalMilliseconds, 0))

    foreach ($warning in $profileStartupWarnings) {
        Write-WarningMessage $warning
    }

    if ($profileDeferredStepNames.Count -gt 0) {
        Write-Section "Deferred Warmup"
        Write-Info ("Queued after first prompt: {0}" -f ($profileDeferredStepNames -join ", "))
    }
}

Enable-DeferredProfileWarmup
