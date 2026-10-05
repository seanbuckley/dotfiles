> [!NOTE]
> **Superseded.** Planning for this repo now lives in the merge plan in
> `seanbuckley/dotfiles`: see `docs/migration-plan.md` and `docs/status.md` there.
> This file is kept for history until the repo is archived.

# Master Plan: Dotfiles Windows Standardization & Enhancement

## Goals

- **Robustness & Portability**: Eliminate hardcoded paths; work across different host setups.
- **Legibility & Simplicity**: Keep code clean (KISS) and understandable.
- **Visual UX**: Modernize CLI output with better notices, colors, and helpful info.
- **Upfront Decision Capture**: Collect user choices and prerequisites at the start of interactive scripts before making changes.

---

## Phase 1: Robustness & Portability (High Priority)

*Target: Fix brittle code that breaks on new host setups.*

1. **Fix Hardcoded Paths (Issue #33)**
   - Refactor `Edit-Profile.ps1` to use `$env:USERPROFILE` and dynamic discovery.
   - Detect OneDrive path for "PowerShell Backup" instead of assuming `$Home\OneDrive`.
2. **Refactor `Install-Dotfiles.ps1`**
    - Better detection of PowerShell profile directory (check for OneDrive/Documents).
    - Use `$Global:DotfilesRoot` consistently.
    - Add an initial questionnaire/preflight step that gathers required user choices up front before any install actions run.
3. **Clean Up `.gitconfig`**
   - Remove absolute paths to `gh.exe`; use `gh` from PATH.
   - Move machine-specific `[safe]` directories to `~/.gitconfig_local`.
4. **Environment Consistency**
   - Standardize on `$env:USERPROFILE\dev` but allow overrides via local config.

## Phase 2: Visual UX & UI Refactoring

*Target: Make the CLI "look good" and provide better feedback.*

1. **UI Helpers Module**
   - Create `PowerShell/Scripts/UI-Helpers.ps1` with standardized functions:
     - `Write-Info`, `Write-Success`, `Write-Warning`, `Write-Error`.
     - Use consistent icons (✅, ℹ️, ⚠️, ❌) and colors.
2. **Standardize script headers**
   - Update `Update-System.ps1`, `Install-Dotfiles.ps1`, and `Microsoft.PowerShell_profile.ps1` with new UI helpers.
   - Add clear progress indicators for long-running tasks.

## Phase 3: Performance & Startup Optimization (Issue #15)

*Target: Faster terminal startup.*

1. **Deferred Loading**
   - Refactor `Microsoft.PowerShell_profile.ps1` to load modules only if they are installed.
   - Implement "lazy loading" for heavy modules where possible.
2. **Conditional Loading**
   - Check for tool existence (`gsudo`, `oh-my-posh`, etc.) before attempting to initialize them.

## Phase 4: Modern Tool Integration (Enhancements)

*Target: Replace legacy tools with modern, faster alternatives.*

1. **Zoxide integration (#1)**: Replace `z` with `zoxide`.
2. **Eza integration (#31)**: Replace `ls` with `eza`.
3. **Bat integration (#20)**: Use `bat` for `cat` and previews.
4. **Fastfetch (#27)**: Add system info summary on startup.
5. **Additional Utilities**: TLDR (#14), McFly (#30), Difftastic (#17), PowerShell.tiPS (#32).

## Phase 5: Maintenance & Backup Logic

*Target: Ensure system state is recoverable.*

1. **Git Repository Backup (#12)**: New script to backup all git repos in `dev` folder.
2. **Robust Update Script (#13)**: Check for existence of `choco`, `scoop`, `winget`, `nvm`, etc. before upgrading.
3. **Recovery Logic**: Added `Restore-Winget.ps1` for automated package manager re-hydration.
4. **Own Chocolatey Backups (#11)**: Keep Chocolatey package snapshots, pins, and recovery notes in repo-owned scripts instead of third-party config-driven tooling.

---

## Discarded / Deprioritized Items

- **Issue #3 (Integrate jayharris)**: Discarded. Project has diverged sufficiently; manual integration is no longer valuable.
- **Issue #8 (Starship)**: Deprioritized. `oh-my-posh` is already configured and works well.
- **Issue #6 (Check module updates on start)**: Discarded. Too slow for startup. Updates should be handled via `upgrade` command only.

---

## Execution Order

1. **Foundation**: Phase 1 (Robustness) + Phase 2 (UI Helpers).
2. **Polish**: Phase 3 (Performance).
3. **Features**: Phase 4 & 5 (New tools and maintenance).

---

## Current TODOs

- Add `PSScriptAnalyzer` coverage for scripts and root entrypoints.
- Add Pester smoke tests for install, validation, and profile loading.
- Add an `Install-Dotfiles.ps1` preflight before install actions.
- Test nonstandard repo paths, including another drive.
- Test zero, one, and multiple OneDrive roots.
- Test `Update-System` elevation behavior with and without `gsudo`.
- Remove remaining fixed install paths.
- Triage stale issues.
