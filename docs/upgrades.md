# Upgrades

`upgrade` is the one command that updates everything on a machine: dotfiles, OS
packages and dev tools. Sean runs it often, so it must be reliable.

Today there are two implementations:

- **Linux:** a single `&&` alias chain (`.aliases:114`). The first failure silently skips everything after it, and `apt autoremove` stops to ask.
- **Windows:** `Update-System.ps1`, which is well structured: switches, a log, gsudo, and a summary. It still uses nvm and has no vite-plus, PowerShell-module or WSL step.

The new design keeps the Windows structure and gives Linux the same shape.

## Behaviour (both OSes)

- **Steps run in a fixed order; each one is independent.** A failed step is recorded, and the next step still runs.
- **Summary at the end:** each step shows ✅ ok, ⚠️ warning, ❌ failed or ⏭ skipped. The exit code is non-zero if any step failed.
- **Skips steps whose tool isn't installed,** showing ⏭ rather than an error.
- **Selecting steps:** `--only <steps>` / `--skip <steps>` (Windows: `-Only` / `-Skip`), plus `--help` that lists the steps.
- **Log file** with timestamps. Keeps the last 20 runs.
  - Linux: `~/.local/state/dotfiles/upgrade-logs/`
  - Windows: `%LOCALAPPDATA%\dotfiles\upgrade-logs\`
- **One elevation prompt:**
  - Linux: `sudo -v` at the start, with a keep-alive that ends with the script.
  - Windows: gsudo cache on at the start, off in `finally`.
- **Idempotent:** running it twice in a row is harmless.
- **Local settings** (skip lists, blocked packages) come from a file the repo doesn't track ([architecture.md](architecture.md#local-overrides)).
- **Self-contained:** one script per OS family, readable top to bottom, with no shared library.

## Linux / WSL / macOS steps

| # | Step | Command | Notes |
|---|---|---|---|
| 1 | `dotfiles` | `chezmoi update` | Pulls the repo and applies it. The package list may change, so this runs first ([dotfiles-legacy#54](https://github.com/seanbuckley/dotfiles-legacy/issues/54)) |
| 2 | `system` | Omarchy: `omarchy-update` · apt: `apt-get update && apt-get -y upgrade && apt-get -y autoremove` · dnf: `dnf -y upgrade` · pacman: `pacman -Syu --noconfirm` · apk: `apk upgrade` · brew: `brew update && brew upgrade` | Exactly one of these, picked by `isOmarchy` / `osID` |
| 3 | `flatpak` | `flatpak update -y` | Only if installed |
| 4 | `vite-plus` | `vp upgrade`, then `vp env install lts` and `vp update -g` | Node + global JS tools ([dotfiles-legacy#88](https://github.com/seanbuckley/dotfiles-legacy/issues/88)) |
| 5 | `externals` | `chezmoi apply --refresh-externals` (weekly, via a date stamp) | zsh plugins, gitalias |
| 6 | `firmware` | `fwupdmgr refresh && fwupdmgr update` | **Off by default**; enable per machine in local settings |
| 7 | `reboot-check` | `/var/run/reboot-required` (Debian/Ubuntu) or the kernel version mismatch on Arch | Prints a note, never reboots |

Omarchy's own updater already runs `pacman`/`yay` and its migrations, and the
post-update hook re-applies chezmoi. So on Omarchy step 2 is just `omarchy-update`.

## Windows steps

The `Update-System.ps1` order is kept, and changes are marked **new** or **changed**.

| # | Step | Command | Notes |
|---|---|---|---|
| 1 | `Dotfiles` | `chezmoi update` | **new**; replaces the profile backup/copy |
| 2 | `Winget` | `winget source update`, then per-package upgrades | Existing logic, with `WingetNoElevationIds` / `WingetBlockedIds`. **Changed:** prefer `winget upgrade --all` where the column parsing is fragile ([windows#13](https://github.com/seanbuckley/dotfiles-windows/issues/13)) |
| 3 | `Store` | `winget upgrade --all --source msstore` | Existing |
| 4 | `Chocolatey` | `choco upgrade all` | Always part of the setup (D5). Existing exclusions and backup kept |
| 5 | `Scoop` | `scoop update`, `scoop update *`, `scoop cleanup *` | Always part of the setup (D5). Existing backup kept |
| 6 | `VitePlus` | `vp upgrade`, `vp env install lts`, `vp update -g` | **new**; replaces the `nvm` and `npm update -g` steps |
| 7 | `PSModules` | `Update-PSResource` for modules in the list | **new**; the profile no longer checks for updates at startup ([windows#6](https://github.com/seanbuckley/dotfiles-windows/issues/6)) |
| 8 | `WindowsUpdate` | PSWindowsUpdate if installed | Existing |
| 9 | `WSL` | `wsl --update`, then `wsl -e bash -lc upgrade` for the default distro (a login shell so `~/.local/bin` is on PATH) | **new**, opt-in with `-IncludeWSL`. It reuses the Linux `upgrade` and replaces `Update-WSL.ps1`'s duplicated apt logic |

Tailscale's `tailscale update` ([windows#61](https://github.com/seanbuckley/dotfiles-windows/issues/61)) is **parked**: it needs admin plus an interactive Y/N. Revisit it after v1.

## Removing nvm (Windows)

vite-plus manages Node, so nvm isn't needed. Both put a `node` on PATH, and whichever
comes first wins, which is confusing. Remove nvm in Phase 4:

1. vite-plus shows an installed LTS Node (check `vp help env` for the exact list command).
2. In a project that pins a Node version (`.nvmrc` / `.node-version` / `engines`), check `node -v` matches.
3. Run `nvm list` and note the versions, then uninstall nvm-windows (winget or Apps & features).
4. Remove leftover `NVM_HOME` / `NVM_SYMLINK` variables and PATH entries.
5. Open a new terminal: `where.exe node` shows only the vite-plus shim.

## Vite+ scope

Vite+ is a **separate workstream**. The dotfiles only install `vp`, keep it updated and
put its shims on PATH. Migrating actual JS projects to Vite+ 1.0 (the pasted migration
prompt) happens per project, in that project's repo.
