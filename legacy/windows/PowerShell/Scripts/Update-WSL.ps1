# Update-WSL.ps1
#
# What:     The `upgradeWSL` command: updates the WSL kernel (wsl --update), then
#           runs apt update/upgrade/autoremove (and nvm, if present) inside the
#           default distro with sudo.
# Loaded:   lazily, on first use of Update-WSL / upgradeWSL.
# Gotchas:  `wsl -l` prints UTF-16 text with blank lines, hence the Trim filter
#           below. Utilities.ps1 has older copies of two helpers from this file
#           (dotfiles-windows#54).
# Fate:     replaced by `upgrade -IncludeWSL`, which runs the Linux `upgrade`
#           inside WSL (docs/upgrades.md).

function Test-WSLCommandAvailable {
    return [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)
}

function Test-WSLDefaultDistroAvailable {
    if (-not (Test-WSLCommandAvailable)) {
        return $false
    }

    # wsl.exe prints UTF-16 text; PowerShell sees blank or NUL-padded lines too,
    # so keep only lines with real content.
    $distros = & wsl.exe -l -q 2>$null | Where-Object { $_.Trim() }
    return [bool]($distros | Select-Object -First 1)
}

function Get-WSLUpgradeScript {
    @'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

step() { printf '\n\033[36mℹ️  %s\033[0m\n' "$1"; }

step "Refreshing package lists (apt-get update)"
apt-get update

step "Packages with updates available"
# stderr carries only apt's "unstable CLI" warning here; drop it for clean output.
upgradable=$(apt list --upgradable 2>/dev/null | grep -v '^Listing' || true)
if [ -n "$upgradable" ]; then
  printf '%s\n' "$upgradable"
else
  printf 'Everything is already up to date.\n'
fi

step "Upgrading installed packages (apt-get upgrade)"
apt-get -y upgrade

step "Removing unused packages (apt-get autoremove)"
apt-get -y autoremove

if [ -s "$HOME/.nvm/nvm.sh" ]; then
  step "Updating Node via nvm"
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  . "$HOME/.nvm/nvm.sh"
  nvm install node
  nvm use node
  npm update -g
else
  step "Skipping Node update (nvm not found)"
fi

step "WSL distro update complete"
'@
}

function Get-WSLScriptRunnerCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Script
    )

    $normalizedScript = $Script -replace "`r`n", "`n"
    $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($normalizedScript))
    return "printf '%s' '$encodedScript' | base64 -d | bash"
}

function Invoke-WSLCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    & wsl.exe -- bash -lc $Command
    return ($LASTEXITCODE -eq 0)
}

function Invoke-WSLSudoCommandWithPassword {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [securestring]$SudoPassword
    )

    $plainPassword = [System.Net.NetworkCredential]::new("", $SudoPassword).Password
    try {
        ($plainPassword + "`n") | & wsl.exe -- bash -lc "sudo -S -p '' bash -lc ""$Command"""
        return ($LASTEXITCODE -eq 0)
    } finally {
        $plainPassword = $null
    }
}

function Test-WSLSudoWithoutPrompt {
    if (-not (Test-WSLDefaultDistroAvailable)) {
        return $false
    }

    & wsl.exe -- bash -lc "sudo -n true"
    return ($LASTEXITCODE -eq 0)
}

function Test-WSLSudoPassword {
    param(
        [Parameter(Mandatory)]
        [securestring]$SudoPassword
    )

    if (-not (Test-WSLDefaultDistroAvailable)) {
        return $false
    }

    $plainPassword = [System.Net.NetworkCredential]::new("", $SudoPassword).Password
    try {
        ($plainPassword + "`n") | & wsl.exe -- bash -lc "sudo -k; sudo -S -p '' -v"
        return ($LASTEXITCODE -eq 0)
    } finally {
        $plainPassword = $null
    }
}

function Update-WSL {
    [CmdletBinding()]
    param(
        [securestring]$SudoPassword,

        [switch]$SkipKernelUpdate,

        [switch]$SkipDistroUpdate
    )

    # Load shared UI helpers so styling matches Update-System (upgrade).
    if (-not (Get-Command Write-Section -ErrorAction SilentlyContinue)) {
        $scriptRoot = Split-Path -Parent $PSCommandPath
        if ($scriptRoot) {
            $uiHelpersPath = Join-Path $scriptRoot "UI-Helpers.ps1"
            if (Test-Path $uiHelpersPath) { . $uiHelpersPath }
        }
    }

    if (Get-Command Write-Header -ErrorAction SilentlyContinue) {
        Write-Header "WSL Maintenance & Updates"
    }
    else {
        Write-Host "`n--- WSL Maintenance & Updates ---`n" -ForegroundColor Blue
    }

    if (-not (Test-WSLCommandAvailable)) {
        throw "wsl.exe is not available on this host."
    }

    if (-not $SkipKernelUpdate) {
        Write-Section "Kernel"
        Write-Info "Updating WSL kernel (wsl.exe --update)..."
        & wsl.exe --update
        if ($LASTEXITCODE -ne 0) {
            throw "WSL kernel update failed. wsl.exe --update exited with code $LASTEXITCODE."
        }
        Write-Success "WSL kernel is up to date."
    }

    if ($SkipDistroUpdate) {
        Write-Section "Distro"
        Write-WarningMessage "Skipping distro update (-SkipDistroUpdate)."
        Write-Host ""
        Write-Success "WSL update complete (kernel only)."
        Write-Host ""
        return
    }

    if (-not (Test-WSLDefaultDistroAvailable)) {
        throw "No default WSL distro is available for internal updates."
    }

    Write-Section "Distro"
    Write-Info "Updating the default WSL distro..."

    $runner = Get-WSLScriptRunnerCommand -Script (Get-WSLUpgradeScript)

    if ($PSBoundParameters.ContainsKey("SudoPassword") -and $null -ne $SudoPassword) {
        if (-not (Invoke-WSLSudoCommandWithPassword -Command $runner -SudoPassword $SudoPassword)) {
            throw "WSL internal updates failed while running with the supplied sudo password."
        }

        Write-Host ""
        Write-Success "WSL update complete."
        Write-Host ""
        return
    }

    if (-not (Test-WSLSudoWithoutPrompt)) {
        $SudoPassword = Read-Host -Prompt "Enter WSL sudo password (leave blank to skip distro updates)" -AsSecureString
        if ($SudoPassword.Length -eq 0) {
            throw "WSL internal updates require sudo access."
        }

        if (-not (Test-WSLSudoPassword -SudoPassword $SudoPassword)) {
            throw "The supplied WSL sudo password was rejected."
        }

        if (-not (Invoke-WSLSudoCommandWithPassword -Command $runner -SudoPassword $SudoPassword)) {
            throw "WSL internal updates failed while running with the supplied sudo password."
        }

        Write-Host ""
        Write-Success "WSL update complete."
        Write-Host ""
        return
    }

    if (-not (Invoke-WSLCommand -Command "sudo bash -lc ""$runner""")) {
        throw "WSL internal updates failed while running with cached/passwordless sudo."
    }

    Write-Host ""
    Write-Success "WSL update complete."
    Write-Host ""
}

Set-Alias -Name upgradeWSL -Value Update-WSL
