# Merge-WindowsTerminalSettings.ps1
# Safely merges reusable repo preferences into a host-owned Windows Terminal settings.json.
#
# What:     Merges the repo's Windows Terminal preferences
#           (Windows Terminal/settings.merge-template.json) into the Terminal's
#           own settings.json, backing it up first. The Terminal owns that file
#           and rewrites it, so we merge rather than replace (DECISIONS.md 5).
# Loaded:   lazily; also called by Install-Dotfiles.ps1.
# Fate:     port as a chezmoi run_onchange script (P4.03).

# Use a repo-specific function name so an older profile-loaded helper with the generic
# name cannot hijack installer calls in an already-open interactive session.
function Invoke-DotfilesWindowsTerminalMerge {
    [CmdletBinding()]
    param(
        # Optional explicit target for tests or one-off hosts. When omitted we resolve the
        # host-owned settings.json from known Terminal install locations.
        [string]$SettingsPath,
        # Optional explicit template path so callers can pin the repo template even when the
        # function is dot-sourced from another script scope.
        [string]$TemplatePath
    )

    if (-not $TemplatePath) {
        $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
        $TemplatePath = Join-Path $repoRoot "Windows Terminal\settings.merge-template.json"
    }

    if (-not (Test-Path $TemplatePath)) {
        Write-TaskError "Windows Terminal merge template not found."
        return
    }

    if (-not $SettingsPath) {
        if (Get-Command Resolve-WindowsTerminalSettingsPath -ErrorAction SilentlyContinue) {
            $resolvedSettings = Resolve-WindowsTerminalSettingsPath
            if (-not $resolvedSettings.Found) {
                Write-Info "Windows Terminal settings file not found. Skipping Terminal merge. $($resolvedSettings.Detail)"
                return
            }

            if (-not $resolvedSettings.Accessible) {
                Write-Info "Unable to inspect Windows Terminal settings at $($resolvedSettings.Path). Skipping Terminal merge. $($resolvedSettings.Detail)"
                return
            }

            $SettingsPath = $resolvedSettings.Path
        } else {
            $SettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        }
    }

    try {
        $null = Get-Item -LiteralPath $SettingsPath -ErrorAction Stop
    } catch {
        Write-Info "Unable to inspect Windows Terminal settings at $SettingsPath. Skipping Terminal merge. $($_.Exception.Message)"
        return
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

    try {
        Write-Info "Merging Windows Terminal settings at $SettingsPath"
        $settings = ConvertFrom-JsonCompat -Json (Get-Content $SettingsPath -Raw)
        $template = ConvertFrom-JsonCompat -Json (Get-Content $TemplatePath -Raw)
    } catch {
        Write-TaskError "Failed to parse Windows Terminal settings: $($_.Exception.Message)"
        return
    }

    if ($settings.PSObject.Properties.Name -notcontains "actions") {
        $settings | Add-Member -NotePropertyName actions -NotePropertyValue @()
    }

    if ($settings.PSObject.Properties.Name -contains "keybindings" -and $settings.keybindings) {
        $templateKeys = $template.actions | ForEach-Object { $_.keys } | Where-Object { $_ }
        $settings.keybindings = @($settings.keybindings | Where-Object { $_.keys -notin $templateKeys })
    }

    $existingActionsByKey = @{}
    foreach ($action in @($settings.actions)) {
        if ($action.keys) {
            $existingActionsByKey[$action.keys] = $action
        }
    }

    foreach ($action in @($template.actions)) {
        $existingActionsByKey[$action.keys] = $action
    }
    $settings.actions = @($existingActionsByKey.Values)

    foreach ($property in $template.PSObject.Properties) {
        if ($property.Name -in @("actions", "profiles", "schemes")) {
            continue
        }

        $settings | Add-Member -Force -NotePropertyName $property.Name -NotePropertyValue $property.Value
    }

    if ($settings.PSObject.Properties.Name -notcontains "profiles") {
        $settings | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{})
    }
    if ($settings.profiles.PSObject.Properties.Name -notcontains "defaults") {
        $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{})
    }
    if ($settings.profiles.PSObject.Properties.Name -notcontains "list") {
        $settings.profiles | Add-Member -NotePropertyName list -NotePropertyValue @()
    }

    if ($settings.PSObject.Properties.Name -notcontains "schemes") {
        $settings | Add-Member -NotePropertyName schemes -NotePropertyValue @()
    }

    foreach ($property in $template.profiles.defaults.PSObject.Properties) {
        $settings.profiles.defaults | Add-Member -Force -NotePropertyName $property.Name -NotePropertyValue $property.Value
    }

    $pwshExists = [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
    if (-not $pwshExists) {
        Write-Info "pwsh.exe not found in PATH. Skipping PowerShell custom profiles."
    }

    $existingProfiles = @{}
    foreach ($profile in @($settings.profiles.list)) {
        if ($profile.guid) {
            $existingProfiles[$profile.guid] = $profile
        }
    }

    foreach ($profile in @($template.profiles.additions)) {
        if (($profile.name -like "PowerShell*") -and -not $pwshExists) {
            continue
        }

        if ($existingProfiles.ContainsKey($profile.guid)) {
            foreach ($property in $profile.PSObject.Properties) {
                $existingProfiles[$profile.guid] | Add-Member -Force -NotePropertyName $property.Name -NotePropertyValue $property.Value
            }
        } else {
            $settings.profiles.list = @($settings.profiles.list) + @($profile)
        }
    }

    $schemeByName = @{}
    foreach ($scheme in @($settings.schemes)) {
        if ($scheme.name) {
            $schemeByName[$scheme.name] = $scheme
        }
    }
    foreach ($scheme in @($template.schemes)) {
        $schemeByName[$scheme.name] = $scheme
    }
    $settings.schemes = @($schemeByName.Values)

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $fonts = New-Object System.Drawing.Text.InstalledFontCollection
        $fontInstalled = $fonts.Families.Name -contains $template.profiles.defaults.font.face
        if (-not $fontInstalled) {
            Write-Info "Font '$($template.profiles.defaults.font.face)' is not installed. Windows Terminal will fall back to another font."
        }
    } catch {
        Write-Info "Could not verify installed fonts. Windows Terminal will fall back automatically if the preferred font is missing."
    }

    $backupPath = "{0}.{1}.bak" -f $SettingsPath, (Get-Date -Format "yyyyMMdd-HHmmss")
    try {
        Copy-Item -Path $SettingsPath -Destination $backupPath -Force
        $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $SettingsPath
        Write-Success "Merged Windows Terminal settings."
        Write-Info "Backup saved to $backupPath"
    } catch {
        Write-TaskError "Failed to write merged Windows Terminal settings: $($_.Exception.Message)"
    }
}

# Keep the original helper name as a thin compatibility wrapper for callers that still
# reference it directly. The installer uses the repo-specific name above to avoid picking
# up a stale global function definition from the user's current session.
function Merge-WindowsTerminalSettings {
    [CmdletBinding()]
    param(
        [string]$SettingsPath,
        [string]$TemplatePath
    )

    Invoke-DotfilesWindowsTerminalMerge -SettingsPath $SettingsPath -TemplatePath $TemplatePath
}
