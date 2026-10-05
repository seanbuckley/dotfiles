### PowerShell Utilities
###
### References
### https://gist.github.com/timsneath/19867b12eee7fd5af2ba
#
# What:     Elevation helpers (admin/sudo, red console when elevated), a plain
#           fallback prompt, WSL checks, and discovery of backup folders
#           (OneDrive, Dropbox, Google Drive, Synology Drive) and of Windows
#           Terminal's settings.json.
# Loaded:   eagerly by the profile; also by Install/Test-Dotfiles and the backup
#           scripts.
# Gotchas:  the WSL helpers here duplicate (and differ from) the ones in
#           Update-WSL.ps1 (dotfiles-windows#54). The `prompt` below is replaced
#           by oh-my-posh when that is installed. `sudo` shadows Windows 11's
#           built-in sudo.
# Fate:     port; keep the discovery functions, drop the duplicates (P4).

# Find out if the current user identity is elevated (has admin rights)
# $isAdmin stays defined for the rest of the session; the prompt below uses it.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If so and the current host is a command line, then change to red color
# as warning to user that they are operating in an elevated context
if (($host.Name -match "ConsoleHost") -and ($isAdmin)) {
    $host.UI.RawUI.BackgroundColor = "DarkRed"
    $host.PrivateData.ErrorBackgroundColor = "White"
    $host.PrivateData.ErrorForegroundColor = "DarkRed"
    Clear-Host
}

# Set up command prompt and window title. Use UNIX-style convention for identifying
# whether user is elevated (root) or not. Window title shows current version of PowerShell
# and appends [ADMIN] if appropriate for easy taskbar identification
function prompt {
    if ($isAdmin) {
        "[" + (Get-Location) + "] # "
    }
    else {
        "[" + (Get-Location) + "] $ "
    }
}

$Host.UI.RawUI.WindowTitle = "PowerShell {0}" -f $PSVersionTable.PSVersion.ToString()
if ($isAdmin) {
    $Host.UI.RawUI.WindowTitle += " [ADMIN]"
}

# Simple function to start a new elevated process. If arguments are supplied then
# a single command is started with admin rights; if not then a new admin instance
# of PowerShell is started.
function admin {
    if ($args.Count -gt 0) {
        $argList = "& '" + $args + "'"
        Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $argList
    }
    else {
        Start-Process "$psHome\powershell.exe" -Verb runAs
    }
}
# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights.
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

# Test is current user is an administrator
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Check if a default WSL distribution is installed and available.
function Test-WSLDefaultDistroAvailable {
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) { return $false }
    # wsl --list --quiet returns the names of installed distros.
    $distros = wsl --list --quiet 2>$null
    return $null -ne $distros -and $distros.Count -gt 0
}

# Check if sudo can be run in the default WSL distro without an interactive password prompt.
function Test-WSLSudoWithoutPrompt {
    if (-not (Test-WSLDefaultDistroAvailable)) { return $false }
    # Try to run sudo non-interactively (-n). If it succeeds, passwordless sudo is configured or cached.
    # Use 'true' as a no-op command to test permission.
    wsl sudo -n true 2>$null
    return $LASTEXITCODE -eq 0
}

# Discover all available OneDrive roots (Personal, Business, etc.)
function Get-OneDrivePaths {
    $paths = @()

    # 1. Environment Variables (Fastest)
    if ($env:OneDrive) { $paths += $env:OneDrive }
    if ($env:OneDriveConsumer) { $paths += $env:OneDriveConsumer }
    if ($env:OneDriveCommercial) { $paths += $env:OneDriveCommercial }

    # 2. Registry (Most reliable for multiple business accounts)
    $registryPath = "HKCU:\Software\Microsoft\OneDrive\Accounts"
    if (Test-Path $registryPath) {
        $accounts = Get-ChildItem -Path $registryPath
        foreach ($account in $accounts) {
            $folder = Get-ItemProperty -Path $account.PSPath -Name "UserFolder" -ErrorAction SilentlyContinue
            if ($folder.UserFolder) { $paths += $folder.UserFolder }
        }
    }

    # 3. Filter unique, existing paths
    $validPaths = $paths | Select-Object -Unique | Where-Object { Test-Path $_ }

    # 4. Fallback if none found
    if ($validPaths.Count -eq 0) {
        $validPaths = @(Join-Path $HOME "Documents")
    }

    return $validPaths
}

# Discover Dropbox roots from Dropbox metadata or well-known profile folders.
function Get-DropboxPaths {
    $paths = @()

    $infoPath = Join-Path $env:APPDATA "Dropbox\info.json"
    if (Test-Path $infoPath) {
        try {
            $info = Get-Content $infoPath -Raw | ConvertFrom-Json
            if ($info.personal.path) { $paths += $info.personal.path }
            if ($info.business.path) { $paths += $info.business.path }
        }
        catch {
            # Ignore malformed Dropbox metadata and continue with folder discovery.
        }
    }

    $paths += Get-ChildItem -Path $HOME -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "Dropbox*" } |
    ForEach-Object { $_.FullName }

    return @($paths | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) })
}

# Discover Google Drive roots from Drive for desktop metadata or well-known profile folders.
function Get-GoogleDrivePaths {
    $paths = @()

    $driveFsRoot = Join-Path $env:LOCALAPPDATA "Google\DriveFS"
    if (Test-Path $driveFsRoot) {
        $syncRoots = Get-ChildItem -Path $driveFsRoot -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName "root" } |
        Where-Object { Test-Path $_ }
        $paths += $syncRoots
    }

    $paths += Get-ChildItem -Path $HOME -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @("Google Drive", "My Drive", "GoogleDrive") } |
    ForEach-Object { $_.FullName }

    return @($paths | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) })
}

# Discover Synology Drive roots from common local folders.
function Get-SynologyDrivePaths {
    $paths = @()

    $paths += Get-ChildItem -Path $HOME -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "SynologyDrive*" -or $_.Name -like "Synology Drive*" } |
    ForEach-Object { $_.FullName }

    $paths += Get-ChildItem -Path (Join-Path $HOME "Drive") -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { $_.FullName }

    return @($paths | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) })
}

# Discover the user-owned cloud/local roots that should receive backup copies.
function Get-BackupRoots {
    $paths = @()
    $paths += @(Get-OneDrivePaths)
    $paths += @(Get-DropboxPaths)
    $paths += @(Get-GoogleDrivePaths)
    $paths += @(Get-SynologyDrivePaths)

    $validPaths = @($paths | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) })
    if ($validPaths.Count -eq 0) {
        return @(Join-Path $HOME "Documents")
    }

    return $validPaths
}

# Build a conservative list of Windows Terminal settings locations without hardcoding a
# single installation style. Store, preview, and unpackaged installs can land in
# different folders, so the installer and verifier should resolve from the same list.
function Get-WindowsTerminalSettingsCandidates {
    $candidates = @()
    $localAppData = $env:LOCALAPPDATA

    if (-not $localAppData) {
        return @()
    }

    $knownPackageFamilies = @(
        "Microsoft.WindowsTerminal_8wekyb3d8bbwe",
        "Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe"
    )

    foreach ($packageFamily in $knownPackageFamilies) {
        $candidates += Join-Path $localAppData ("Packages\{0}\LocalState\settings.json" -f $packageFamily)
    }

    # Some hosts install Terminal without the Store package layout.
    $candidates += @(
        (Join-Path $localAppData "Microsoft\Windows Terminal\settings.json"),
        (Join-Path $localAppData "Microsoft\Windows Terminal Preview\settings.json")
    )

    # When package enumeration is allowed, include any matching package families so future
    # naming changes do not require touching every script again.
    $packagesRoot = Join-Path $localAppData "Packages"
    try {
        if (Test-Path $packagesRoot) {
            $packageCandidates = Get-ChildItem -LiteralPath $packagesRoot -Directory -ErrorAction Stop |
            Where-Object { $_.Name -like "Microsoft.WindowsTerminal*" } |
            ForEach-Object { Join-Path $_.FullName "LocalState\settings.json" }
            $candidates += $packageCandidates
        }
    }
    catch {
        # Access to Packages is inconsistent across hosts and sandboxes. Fall back to the
        # stable well-known paths above when enumeration is blocked.
    }

    return @($candidates | Where-Object { $_ } | Select-Object -Unique)
}

# Resolve the first usable Windows Terminal settings file and preserve discovery state so
# callers can distinguish "missing", "inaccessible", and "found" without duplicating path
# probing logic.
function Resolve-WindowsTerminalSettingsPath {
    $candidates = @(Get-WindowsTerminalSettingsCandidates)

    foreach ($candidate in $candidates) {
        try {
            $item = Get-Item -LiteralPath $candidate -ErrorAction Stop
            if (-not $item.PSIsContainer) {
                return [pscustomobject]@{
                    Found      = $true
                    Accessible = $true
                    Path       = $item.FullName
                    Detail     = $item.FullName
                    Candidates = $candidates
                }
            }
        }
        catch [System.UnauthorizedAccessException] {
            return [pscustomobject]@{
                Found      = $true
                Accessible = $false
                Path       = $candidate
                Detail     = $_.Exception.Message
                Candidates = $candidates
            }
        }
        catch {
            # Ignore missing/invalid candidates and continue until a usable file is found.
        }
    }

    return [pscustomobject]@{
        Found      = $false
        Accessible = $false
        Path       = $null
        Detail     = "Checked: $($candidates -join ', ')"
        Candidates = $candidates
    }
}

# We don't need these any more; they were just temporary variables to get to $isAdmin.
# Delete them to prevent cluttering up the user profile.
Remove-Variable identity
Remove-Variable principal
