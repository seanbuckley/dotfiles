# Test-Dotfiles.ps1
# Health Report & Portability Audit for dotfiles-windows.
#
# This script is intentionally kept at the repo root because it is an operator-facing
# entrypoint: humans and automation should be able to run a single predictable command
# from the repository root after cloning or updating the dotfiles checkout.
#
# The report favors "is this repo wired in correctly on this host?" over "does every
# individual script behave perfectly?" That means most checks look for durable signals
# such as loader references, include directives, or repo-managed Windows Terminal markers.
#
# Run:      pwsh -NoProfile -File .\Test-Dotfiles.ps1
# Checks:   no user-specific paths in tracked files, both $PROFILE loaders,
#           the .gitconfig include/link, the Windows Terminal merge markers,
#           and backup-root (OneDrive etc.) discovery.
# Platform: Windows.
# Fate:     useful checks move into CI and `chezmoi verify` (docs/testing.md).

$ErrorActionPreference = "Continue"

# 1. Load Dependencies
$repoRoot = $PSScriptRoot
$uiHelpers = Join-Path $repoRoot "PowerShell/Scripts/UI-Helpers.ps1"
$utilities = Join-Path $repoRoot "PowerShell/Scripts/Utilities.ps1"

if (Test-Path $uiHelpers) { . $uiHelpers }
if (Test-Path $utilities) { . $utilities }

# Fallback functions if dependencies aren't loaded
if (-not (Get-Command Write-Header -ErrorAction SilentlyContinue)) {
    function Write-Header { param($Title) Write-Host "`n=== $Title ===`n" -ForegroundColor Cyan }
}
if (-not (Get-Command Write-Section -ErrorAction SilentlyContinue)) {
    function Write-Section { param($Title) Write-Host "`n--- $Title ---" -ForegroundColor Blue }
}
if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
    function Write-Info { param($Msg) Write-Host "i $Msg" -ForegroundColor Cyan }
}

function Write-VerifyStatus {
    param([string]$Label, [bool]$Success, [string]$Detail)
    $icon = if ($Success) { "[OK]" } else { "[!!]" }
    $color = if ($Success) { "Green" } else { "Red" }
    Write-Host -NoNewline "$icon $($Label.PadRight(30))" -ForegroundColor $color
    Write-Host ": $Detail"
}

# Return the two profile locations this repo actively manages. Keeping this as a helper
# avoids drifting between the installer and verifier when the profile policy changes.
function Get-ProfileTargets {
    $documentsDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
    @(
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

function ConvertFrom-JsonCompat {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Json
    )

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        return $Json | ConvertFrom-Json -Depth 100
    }

    return $Json | ConvertFrom-Json
}

function Test-WindowsTerminalManagedCopy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SettingsPath,
        [Parameter(Mandatory = $true)]
        [string]$TemplatePath
    )

    if (-not (Test-Path $TemplatePath -PathType Leaf)) {
        return [pscustomobject]@{
            Success = $false
            Detail  = "Template missing at $TemplatePath"
        }
    }

    try {
        $settingsRaw = Get-Content $SettingsPath -Raw
        $templateRaw = Get-Content $TemplatePath -Raw
        $settings = ConvertFrom-JsonCompat -Json (Get-Content $SettingsPath -Raw)
        $template = ConvertFrom-JsonCompat -Json (Get-Content $TemplatePath -Raw)
    } catch {
        return [pscustomobject]@{
            Success = $false
            Detail  = "Unable to parse settings/template JSON: $($_.Exception.Message)"
        }
    }

    # Check a few stable markers from each managed area instead of diffing the full JSON.
    # The host still owns most of settings.json, so we only assert the repo-managed pieces.
    #
    # Why not compare the parsed objects directly?
    # Windows Terminal often rewrites the saved file after merge, which can reorder members,
    # normalize values, or reshape the JSON without removing the actual repo-managed content.
    # Marker-based verification is much more durable across Terminal updates.
    $missingMarkers = @()

    # Windows Terminal may reformat the saved JSON after merge, so use text-presence checks
    # for the durable repo-managed markers instead of requiring one exact object layout.
    foreach ($action in @($template.actions)) {
        if (-not $action.keys) {
            continue
        }

        if ($settingsRaw -notmatch [regex]::Escape([string]$action.keys)) {
            $missingMarkers += "action:$($action.keys)"
        }
    }

    foreach ($profile in @($template.profiles.additions)) {
        if (-not $profile.guid) {
            continue
        }

        if (
            ($settingsRaw -notmatch [regex]::Escape([string]$profile.guid)) -and
            ($settingsRaw -notmatch [regex]::Escape([string]$profile.name))
        ) {
            $missingMarkers += "profile:$($profile.name)"
        }
    }

    foreach ($scheme in @($template.schemes)) {
        if (-not $scheme.name) {
            continue
        }

        if ($settingsRaw -notmatch [regex]::Escape([string]$scheme.name)) {
            $missingMarkers += "scheme:$($scheme.name)"
        }
    }

    if ($settingsRaw -notmatch [regex]::Escape('"copyOnSelect": true')) {
        $missingMarkers += "setting:copyOnSelect"
    }

    if ($settingsRaw -notmatch [regex]::Escape([string]$template.profiles.defaults.colorScheme)) {
        $missingMarkers += "default:colorScheme"
    }

    if ($settingsRaw -notmatch [regex]::Escape([string]$template.profiles.defaults.font.face)) {
        $missingMarkers += "default:font.face"
    }

    if ($missingMarkers.Count -gt 0) {
        $preview = $missingMarkers | Select-Object -First 3
        return [pscustomobject]@{
            Success = $false
            Detail  = "Regular file missing repo-managed markers: $($preview -join ', ')"
        }
    }

    return [pscustomobject]@{
        Success = $true
        Detail  = "Managed copy includes repo Terminal settings"
    }
}

Write-Header "Dotfiles Health Report"

# --- SECTION 1: Repository Status ---
# Scan tracked content for obvious machine-specific paths. Markdown is excluded because
# docs often describe example paths that are not part of the runnable configuration.
Write-Section "Repository & Paths"
Write-VerifyStatus "Repository Root" $true $repoRoot

$pathPatterns = @(
    "C:\\Users\\[^\\]+\\",
    [regex]::Escape($env:USERPROFILE),
    [regex]::Escape($env:USERNAME)
)

$pathMatches = Get-ChildItem -Path $repoRoot -Recurse -File -Exclude "*.ps1xml", "*.md", ".git", "Test-Dotfiles.ps1" |
    Select-String -Pattern $pathPatterns

$suspiciousMatches = $pathMatches | Where-Object {
    $_.Path -notmatch "\\.git\\" -and $_.Line -match "C:\\Users\\[^\\]+\\" -and
    $_.Path -notmatch "\\Test-Dotfiles\.ps1$"
}

$matchPreview = $suspiciousMatches | Select-Object -First 3 | ForEach-Object {
    $relativePath = $_.Path.Replace("$repoRoot\", "")
    "{0}:{1}" -f $relativePath, $_.LineNumber
}

$pathStatus = if ($suspiciousMatches) {
    "Found machine-specific path patterns in: $($matchPreview -join ', ')"
} else {
    "Clean (no machine-specific user profile paths found in tracked scripts/config)"
}
Write-VerifyStatus "Hardcoded Path Check" (-not $suspiciousMatches) $pathStatus

# --- SECTION 2: PowerShell Profile ---
# The installer writes thin loader files into the user profile locations instead of copying
# the whole repo profile there. Verify that those entry files still point back to the repo.
Write-Section "PowerShell Profile"

foreach ($profileTarget in Get-ProfileTargets) {
    if (Test-Path $profileTarget.Path) {
        $profileContent = Get-Content $profileTarget.Path -Raw
        $isLinked = $profileContent -match [regex]::Escape("PowerShell\Microsoft.PowerShell_profile.ps1")
        $linkStatus = if ($isLinked) { "Correctly links to repository" } else { "Does NOT link to repository" }
        Write-VerifyStatus ("{0} Profile" -f $profileTarget.Label) $isLinked $linkStatus
    } else {
        Write-VerifyStatus ("{0} Profile" -f $profileTarget.Label) $false ("Profile file not found at {0}" -f $profileTarget.Path)
    }
}

# --- SECTION 3: Symlinks & Configuration ---
Write-Section "Symlinks & Configuration"

# `.gitconfig` is valid in either supported mode:
# - a direct symlink to the repo copy
# - a normal user file that includes the repo `.gitconfig`
$gitConfigPath = Join-Path $env:USERPROFILE ".gitconfig"
$repoGitConfig = (Join-Path $repoRoot ".gitconfig").Replace('\', '/')
if (Test-Path $gitConfigPath) {
    $item = Get-Item $gitConfigPath
    $isSymlink = $item.Attributes -match "ReparsePoint"
    $gitConfigContent = Get-Content $gitConfigPath -Raw
    $hasInclude = $gitConfigContent -match [regex]::Escape($repoGitConfig)
    $gitConfigured = $isSymlink -or $hasInclude
    $gitStatus = if ($isSymlink) {
        "Active symlink"
    } elseif ($hasInclude) {
        "Regular file with include.path to repo .gitconfig"
    } else {
        "Regular file without repo include.path"
    }
    Write-VerifyStatus ".gitconfig Wiring" $gitConfigured $gitStatus
} else {
    Write-VerifyStatus ".gitconfig" $false "Missing from $env:USERPROFILE"
}

# Windows Terminal is also valid in either supported mode:
# - a direct symlink
# - a host-owned settings file that contains the repo-managed merge markers
#
# Discovery is delegated to Utilities.ps1 so install and verify resolve the same candidate
# paths across Store, Preview, and unpackaged Terminal installs.
$wtTemplatePath = Join-Path $repoRoot "Windows Terminal\settings.merge-template.json"
if (Get-Command Resolve-WindowsTerminalSettingsPath -ErrorAction SilentlyContinue) {
    $resolvedTerminalSettings = Resolve-WindowsTerminalSettingsPath
} else {
    $fallbackPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $resolvedTerminalSettings = [pscustomobject]@{
        Found      = (Test-Path $fallbackPath)
        Accessible = (Test-Path $fallbackPath)
        Path       = $fallbackPath
        Detail     = $fallbackPath
    }
}

if (-not $resolvedTerminalSettings.Found) {
    Write-VerifyStatus "WinTerminal Settings" $false "Not found in known locations. $($resolvedTerminalSettings.Detail)"
} elseif (-not $resolvedTerminalSettings.Accessible) {
    Write-VerifyStatus "WinTerminal Settings" $false "Unable to inspect settings path: $($resolvedTerminalSettings.Detail)"
} else {
    try {
        $item = Get-Item -LiteralPath $resolvedTerminalSettings.Path -ErrorAction Stop
        $isSymlink = $item.Attributes -match "ReparsePoint"
        if ($isSymlink) {
            Write-VerifyStatus "WinTerminal Symlink" $true ("Active symlink at {0}" -f $resolvedTerminalSettings.Path)
        } else {
            $managedCopyStatus = Test-WindowsTerminalManagedCopy -SettingsPath $resolvedTerminalSettings.Path -TemplatePath $wtTemplatePath
            $statusDetail = "{0} ({1})" -f $managedCopyStatus.Detail, $resolvedTerminalSettings.Path
            Write-VerifyStatus "WinTerminal Wiring" $managedCopyStatus.Success $statusDetail
        }
    } catch {
        Write-VerifyStatus "WinTerminal Settings" $false "Unable to inspect settings path: $($_.Exception.Message)"
    }
}

# --- SECTION 4: OneDrive & Backups ---
# This is a light discovery check, not a backup-health audit. Its job is simply to confirm
# that the shared path-discovery helper can still resolve user-owned cloud roots on this host.
Write-Section "OneDrive & Backups"
if (Get-Command Get-OneDrivePaths -ErrorAction SilentlyContinue) {
    $oneDrivePaths = Get-OneDrivePaths
    $oneDriveCount = $oneDrivePaths.Count
    Write-VerifyStatus "OneDrive Discovery" ($oneDriveCount -gt 0) "Found $oneDriveCount path(s): $($oneDrivePaths -join ', ')"
} else {
    Write-VerifyStatus "OneDrive Logic" $false "Get-OneDrivePaths function not found in session"
}

Write-Host "`nReport complete. Run '.\Install-Dotfiles.ps1' to fix 'NOT linked' or 'Missing' items.`n"
