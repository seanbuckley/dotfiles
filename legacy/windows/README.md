# dotfiles-windows

Portable Windows dotfiles for PowerShell, Git, Windows Terminal, Tabby, Hyper, and package-manager maintenance.

The main goal is to make a Windows host comfortable again without baking in one machine's username, drive letter, OneDrive tenant, or checkout path. Shared behavior lives in this repo; host-specific values belong in ignored local files.

> [!NOTE]
> This repo is being merged into `seanbuckley/dotfiles` (chezmoi) and will then be
> archived. See `docs/migration-plan.md` in that repo.

## Contents

See [CONTENTS.md](CONTENTS.md) for a file-by-file guide.

- `Install-Dotfiles.ps1` wires a host to this checkout.
- `Test-Dotfiles.ps1` verifies profile wiring, Git config wiring, Windows Terminal merge markers, and path portability.
- `PowerShell/` contains the shared PowerShell profile, aliases, helper scripts, update commands, package backup scripts, and setup notes.
- `Windows Terminal/` contains the repo-managed merge template and legacy/full settings.
- `Tabby/` and `.hyper.js` contain terminal app configuration.
- `.gitconfig` contains shared Git settings and aliases, with `~/.gitconfig_local` reserved for host-specific overrides.
- `DECISIONS.md`, `MASTER_PLAN.md`, and `SESSION_HANDOVER.md` capture design decisions, roadmap notes, and current handoff state.

## Requirements

Minimum setup requires:

- Git, to clone the repo.
- PowerShell. Windows PowerShell can launch the installer; PowerShell 7+ (`pwsh`) is recommended for daily use and validation.
- GitHub authentication. This repo is private, so either authenticate through Git Credential Manager when `git clone` prompts, use GitHub CLI (`gh`), or download an authenticated archive.

Recommended for the intended day-to-day experience:

- Windows Terminal.
- [`FiraCode Nerd Font Mono`](https://www.nerdfonts.com/font-downloads), used by the Windows Terminal template.
- Chocolatey, Winget, and Scoop, if you want this repo's `upgrade` and backup helpers to manage those package managers.
- `gsudo`, if you want non-admin shells to run elevated maintenance steps.

Optional tools and modules are detected when present. The profile does not require all of these to load:

- `oh-my-posh`, `zoxide`, `posh-git`, `git-aliases`, `PSReadLine`, `Terminal-Icons`, and `Microsoft.WinGet.CommandNotFound`
- `fzf`, `bat`, `eza`, `fastfetch`, `code`, `micro`, `nvm`, `npm`, `tailscale`, and `wsl.exe`

Scoop is optional. If installed, this repo can update it and export its state through `upgrade`, `backupScoop`, and `backupAll`.

The prompt uses the `powerlevel10k_rainbow` oh-my-posh theme. The profile prefers the copy shipped by your oh-my-posh install and falls back to `PowerShell/Themes/powerlevel10k_rainbow.omp.json` in this repo when the install does not provide one (some install methods do not set `POSH_THEMES_PATH` or write a themes folder at all).

## Fresh Setup

Clone the repo wherever you keep source checkouts. The installer uses the repo's actual location and does not require a fixed `C:\dev` path.

```powershell
git clone https://github.com/seanbuckley/dotfiles-windows.git
cd dotfiles-windows
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Install-Dotfiles.ps1
.\Test-Dotfiles.ps1
```

With GitHub CLI:

```powershell
gh repo clone seanbuckley/dotfiles-windows
cd dotfiles-windows
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Install-Dotfiles.ps1
.\Test-Dotfiles.ps1
```

`Install-Dotfiles.ps1` defaults to `ManagedCopy` mode and can run in a normal, non-admin terminal.

## Install Modes

`ManagedCopy` is the default and preferred mode:

```powershell
.\Install-Dotfiles.ps1
```

It:

- sets the current user's execution policy to `RemoteSigned`
- creates thin loader profiles for both Windows PowerShell 5.1 and PowerShell 7+
- adds this repo's `.gitconfig` through a user `.gitconfig` `include.path`
- merges repo-managed Windows Terminal actions, defaults, schemes, and custom profiles into the host settings file
- preserves host-generated Windows Terminal profiles and other local settings

`Symlink` mode is opt-in and requires an elevated terminal on this host:

```powershell
.\Install-Dotfiles.ps1 -InstallMode Symlink
```

## Package Managers

Chocolatey is useful on fresh machines, but it is not required before running the default installer. Install it from an elevated shell only if you want Chocolatey-managed packages:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

If Chocolatey is available, the Nerd Font used by Windows Terminal can be installed with:

```powershell
choco install nerd-fonts-FiraCode -y
```

Winget is usually provided by modern Windows through App Installer. Scoop is optional; install it only on hosts where you want Scoop-managed tools.

### Restoring apps on a new or rebuilt machine

Winget is the main installer. Chocolatey stays installed as a fallback and for packages winget lacks or handles badly.

1. Run `restoreWinget` from an elevated shell. It installs:
   - `Packages/winget-shared.json`: the apps every machine gets.
   - Then this host's newest `Backup/Winget/<date>-<COMPUTERNAME>-Winget-Export.json`, if one exists. A new machine has none, so it gets the shared list only.
2. Restore Chocolatey-managed packages from the host's newest `Backup/Chocolatey/<date>-<COMPUTERNAME>-Chocolatey-Packages.config`:

   ```powershell
   choco install <path-to>-Chocolatey-Packages.config -y
   ```

`restoreWinget -Path <file>` imports one export file instead. Re-running is safe: winget skips packages that are already installed.

To change the shared list, edit `Packages/winget-shared.json` (winget import format). Keep it to apps every machine should have; host-specific apps stay in that host's backup.

## Local Overrides

Keep host-specific settings out of tracked files:

- Put machine-local Git settings in `~/.gitconfig_local`.
- Put fragile package-manager exclusions in local `DotfilesUpgradeSettings`.
- `upgrade` runs Winget elevated through gsudo (one UAC prompt per run). List installers that refuse elevation in `DotfilesUpgradeSettings.WingetNoElevationIds`.
- Run `upgrade -Help` for step switches (`-Only`, `-Skip`). Each run writes a log to `%LOCALAPPDATA%\dotfiles-windows\upgrade-logs` (last 20 kept). Install the optional `BurntToast` module for a silent finish notification.
- Enable expensive profile niceties per host with environment variables such as `DOTFILES_PROFILE_ENABLE_TERMINAL_ICONS=1`.
- Keep usernames, absolute repo roots, OneDrive tenant names, and drive-specific paths out of source-controlled templates.

## Validation

Before pushing changes, run:

```powershell
pwsh -NoProfile -File .\Test-Dotfiles.ps1
pwsh -NoProfile -Command ". .\PowerShell\Microsoft.PowerShell_profile.ps1"
git diff --check
```

If available, also run `Invoke-ScriptAnalyzer` and any relevant Pester tests.

## Common Commands

- `upgrade` runs Windows/package-manager maintenance.
- `upgradeWSL` updates WSL separately from the main Windows upgrade path.
- `backupAll` exports supported package-manager state.
- `backupChocolatey`, `backupWinget`, and `backupScoop` run individual package-manager backups.
- `restoreWinget` installs the shared winget list, then this host's latest Winget export.
- `glall` pulls Git repositories under child folders.
