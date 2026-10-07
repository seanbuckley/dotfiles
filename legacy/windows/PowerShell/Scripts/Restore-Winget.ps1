# Restore-Winget.ps1
# Installs the shared winget list, then the latest Winget backup for the current host.
#
# What:     Runs `winget import` on Packages/winget-shared.json (apps every machine
#           gets), then on the newest winget backup for this computer, if one exists.
#           A new machine has no backup yet, so it gets the shared list only.
#           Chocolatey is restored separately, from Backup/Chocolatey.
# Loaded:   lazily (Restore-Winget / restoreWinget / winget-restore).
# Fate:     port (P4; the shared list becomes packages.yaml in P4.04).

# Ensure we have access to UI helpers and utilities if run standalone.
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot -and $PSCommandPath) { $scriptRoot = Split-Path -Parent $PSCommandPath }

if ($scriptRoot) {
    if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
        $uiHelpersPath = Join-Path $scriptRoot "UI-Helpers.ps1"
        if (Test-Path $uiHelpersPath) { . $uiHelpersPath }
    }

    if (-not (Get-Command Get-BackupRoots -ErrorAction SilentlyContinue)) {
        $utilitiesPath = Join-Path $scriptRoot "Utilities.ps1"
        if (Test-Path $utilitiesPath) { . $utilitiesPath }
    }
}

# Runs one `winget import` and reports whether it succeeded. Out-Host keeps winget's
# progress on screen; without it that text becomes part of the function's return value.
function Invoke-WingetImport {
    param([Parameter(Mandatory)][string]$File)

    Write-Info "Importing $(Split-Path -Leaf $File). This may take several minutes..."
    winget import --import-file $File --accept-package-agreements --accept-source-agreements --ignore-versions --ignore-unavailable | Out-Host

    if ($LASTEXITCODE -ne 0) {
        Write-TaskError "Winget import exited with code $LASTEXITCODE."
        return $false
    }
    return $true
}

function Restore-Winget {
    [CmdletBinding(DefaultParameterSetName = "Discovery")]
    param(
        # Import just this one file instead of the shared list + host backup.
        [Parameter(ParameterSetName = "Manual", Mandatory = $true)]
        [string]$Path
    )

    # If UI helpers failed to load, define minimal fallbacks to prevent script failure
    if (-not (Get-Command Write-Header -ErrorAction SilentlyContinue)) {
        function Write-Header { param($t) Write-Host "`n=== $t ===`n" -ForegroundColor Cyan }
        function Write-TaskStart { param($d) Write-Host -NoNewline "[....] $d " }
        function Write-TaskComplete { Write-Host "✅" -ForegroundColor Green }
        function Write-TaskError { param($m) Write-Host "❌ $m" -ForegroundColor Red }
        function Write-Info { param($m) Write-Host "ℹ️  $m" -ForegroundColor Cyan }
        function Write-Section { param($t) Write-Host "`n--- $t ---" -ForegroundColor Blue }
        function Write-Success { param($m) Write-Host "✅ $m" -ForegroundColor Green }
        function Write-WarningMessage { param($m) Write-Host "⚠️  $m" -ForegroundColor Yellow }
    }

    Write-Header "Winget Package Restoration"

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-TaskError "Winget is not installed or not in the system PATH."
        return $false
    }

    if (Get-Command Test-Administrator -ErrorAction SilentlyContinue) {
        if (-not (Test-Administrator)) {
            Write-WarningMessage "Not running as Administrator. Some Winget packages may fail to install."
        }
    }

    if ($PSCmdlet.ParameterSetName -eq "Manual") {
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-TaskError "File not found: $Path"
            return $false
        }
        return (Invoke-WingetImport -File $Path)
    }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = $true
    $imported = 0

    # 1. Shared list. This file lives in PowerShell/Scripts, two levels below the repo root.
    #    $PSScriptRoot is used because the lazy loader dot-sources this file into a
    #    throwaway scope, where the $scriptRoot variable above is gone by call time.
    Write-Section "Shared List"
    $sharedList = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Packages/winget-shared.json"
    if (Test-Path -LiteralPath $sharedList) {
        $ok = (Invoke-WingetImport -File $sharedList) -and $ok
        $imported++
    } else {
        Write-WarningMessage "Shared list not found at $sharedList"
    }

    # 2. This host's newest backup, if it has one.
    Write-Section "Host Backup"
    $latestBackup = $null
    if (Get-Command Get-BackupRoots -ErrorAction SilentlyContinue) {
        $computerName = $env:COMPUTERNAME
        # Matches the yyyy-MM-dd-PCNAME-Winget-Export.json name Backup-Winget writes;
        # sorting by name then puts the newest date first.
        $latestBackup = Get-BackupRoots | Select-Object -Unique |
        ForEach-Object { Join-Path $_ "Backup/Winget" } |
        Where-Object { Test-Path $_ } |
        ForEach-Object { Get-ChildItem -Path $_ -File -ErrorAction SilentlyContinue } |
        Where-Object { $_.Name -match "^\d{4}-\d{2}-\d{2}-$([regex]::Escape($computerName))-Winget-Export\.json$" } |
        Sort-Object Name -Descending | Select-Object -First 1
    }

    if ($latestBackup) {
        $ok = (Invoke-WingetImport -File $latestBackup.FullName) -and $ok
        $imported++
    } else {
        Write-Info "No winget backup for $env:COMPUTERNAME; the shared list is all this machine gets."
    }

    $timer.Stop()
    if ($imported -eq 0) {
        Write-TaskError "Nothing to restore: no shared list and no host backup found."
        return $false
    }
    if ($ok) {
        Write-Success "Winget restoration completed in $([int]$timer.Elapsed.TotalSeconds)s."
    }
    Write-Info "Restore Chocolatey packages separately: choco install <Backup/Chocolatey/...-Packages.config>"
    return $ok
}

Set-Alias -Name restoreWinget -Value Restore-Winget
Set-Alias -Name winget-restore -Value Restore-Winget

# If the script is run directly (not dot-sourced), execute the restoration.
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.InvocationName -ne '&') {
    Restore-Winget @args
}
