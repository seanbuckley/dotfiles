# Contents

A file-by-file guide to this repo, written in Phase 0b of the merge plan
(`docs/migration-plan.md` in `seanbuckley/dotfiles`). Scripts and configs also have
a header comment. The JSON files have no header, because they can't hold comments
safely.

**Fate in merge** says what happens to each file when this repo is folded into the
single chezmoi-managed `seanbuckley/dotfiles` repo:

| Fate | Meaning |
|---|---|
| port | Carried over mostly as-is (moved into chezmoi's layout) |
| rewrite | The idea is kept but the file is rewritten |
| replaced by chezmoi | chezmoi does this job itself |
| drop | Not carried over |
| review | Decided in a later phase |

## How the pieces fit

1. `Install-Dotfiles.ps1` wires a Windows machine to this checkout. It adds one "loader" line to each `$PROFILE`, for both PowerShell 7 and Windows PowerShell 5.1. It also adds a git `[include]` for `.gitconfig`, and merges the Terminal template into Windows Terminal's own `settings.json`.
2. Every new PowerShell window runs the loader, which dot-sources `PowerShell/Microsoft.PowerShell_profile.ps1`.
3. The profile loads its helpers from `PowerShell/Scripts/` in three ways:
   - **eagerly:** straight away;
   - **deferred:** one per prompt, after the first prompt appears;
   - **lazily:** only when you first type the command, as with `upgrade`.
4. `Test-Dotfiles.ps1` checks that the wiring is in place.

## Root

| File | Purpose | Fate in merge |
|---|---|---|
| `Install-Dotfiles.ps1` | Wires a machine to this repo: `$PROFILE` loaders, git include, Terminal merge | rewrite as chezmoi `run_onchange` scripts (P4.02/P4.03) |
| `Test-Dotfiles.ps1` | Health and portability check of that wiring | rewrite as CI + `chezmoi verify` |
| `.gitconfig` | Shared git settings (Windows copy) | rewrite (merged template; P2.02) |
| `README.md` | Install and usage guide | drop (new README) |
| `CONTENTS.md` | This guide | drop |
| `AGENTS.md`, `CLAUDE.md` | Rules for AI agents: portability, validation, commits | rewrite into the new repo's `AGENTS.md` |
| `DECISIONS.md` | 20 design decisions | review (carried over in `docs/decisions.md`) |
| `MASTER_PLAN.md` | Old roadmap. **Superseded** by the merge plan | drop |
| `SESSION_HANDOVER.md` | Old hand-off note. **Superseded** by `docs/status.md` | drop |
| `.hyper.js` | Hyper terminal settings (legacy) | drop (dotfiles-windows#55) |
| `.vscode/settings.json` | VS Code spell-check words and commit scopes | drop |
| `Packages/winget-shared.json` | Shared winget list: apps every machine gets, used by `Restore-Winget` | port into `packages.yaml` (P4.04) |

## `PowerShell/`

| File | Purpose | Loaded | Fate in merge |
|---|---|---|---|
| `Microsoft.PowerShell_profile.ps1` | The main profile: timers, deferred/lazy loading, modules, prompt, local override | by the `$PROFILE` loader | port (P4.01) |
| `Themes/powerlevel10k_rainbow.omp.json` | oh-my-posh theme, kept here in case the install lacks it | by the profile | drop (Starship; P5) |
| `powershell.config.json` | Empty PowerShell settings file | not used | drop |
| `Setup.md` | Old manual setup steps (README covers them) | people | drop |

## `PowerShell/Scripts/`

| File | Purpose | Loaded | Fate in merge |
|---|---|---|---|
| `UI-Helpers.ps1` | `Write-Success`, `Write-Info`, `Write-Task*`… for consistent output | eager (first) | port |
| `Aliases.ps1` | Short commands: folder jumps, Explorer, hashes, unzip, reboot, reload | eager | rewrite (match Linux names) |
| `Utilities.ps1` | Elevation helpers, fallback prompt, WSL checks, backup-folder and Terminal-path discovery | eager | port (drop duplicate WSL helpers; #54) |
| `PSReadLineSettings.ps1` | Command-line editing, history search, predictions | eager | port |
| `tailscale.ps1` | Generated tab completion for `tailscale` | eager, only if tailscale is installed | drop (generate at runtime; #58) |
| `Backup-Chocolatey.ps1` | Saves the Chocolatey package list to backup folders | eager | review |
| `Backup-Scoop.ps1` | Saves the Scoop app list | eager | review |
| `Backup-Winget.ps1` | Saves the winget package list | eager | port |
| `Backup-PackageManagers.ps1` | Runs all three backups | eager | review |
| `Edit-Profile.ps1` | `Backup-Profile` / `Copy-Profile` (pre-loader design) | eager | drop (chezmoi deploys the profile) |
| `Update-System.ps1` | `upgrade`: Chocolatey, winget, Store, Scoop, Node, Windows Update | lazy | port and extend (P4.05) |
| `Update-WSL.ps1` | `upgradeWSL`: WSL kernel + apt inside the default distro | lazy | replaced by `upgrade -IncludeWSL` |
| `Restore-Winget.ps1` | Installs the shared winget list, then the newest winget backup for this host | lazy | port |
| `Merge-WindowsTerminalSettings.ps1` | Merges the Terminal template into `settings.json` | lazy; used by the installer | port (P4.03) |
| `Install-MyModule.ps1` | `Install-My-Module`: import or install a module | lazy | review |
| `Invoke-FzfBat.ps1` | `fzfb`: fuzzy file finder with a bat preview | lazy | port |
| `Invoke-GitPullAllSubfolders.ps1` | `glall`: `git pull` in every repo below here | lazy | port |

## `Windows Terminal/`

| File | Purpose | Fate in merge |
|---|---|---|
| `settings.merge-template.json` | The repo's Terminal preferences, merged into the real `settings.json` | port |
| `settings.json` | Old full copy of a Terminal settings file (legacy) | drop (#55) |

## `Tabby/`

| File | Purpose | Fate in merge |
|---|---|---|
| `config.yaml` | Old copy of Tabby's settings. Tabby syncs its own; contains a LAN host and username | drop (#55). **Never goes public** |

## Local, untracked files the repo reads

| File / setting | Read by |
|---|---|
| `~/.gitconfig_local` | `.gitconfig` (`[include]`) |
| `PowerShell/Microsoft.PowerShell_profile.local.ps1` | end of the profile |
| `DOTFILES_PROFILE_ENABLE_<FEATURE>` environment variables | the profile, to turn optional features on or off |
| `DotfilesUpgradeSettings` | `upgrade` (skip lists, blocked winget ids) |

Issue numbers (#33, #52, #54, #55, #58, #63) refer to `seanbuckley/dotfiles-windows`.
