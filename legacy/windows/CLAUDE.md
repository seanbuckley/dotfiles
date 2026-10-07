# CLAUDE.md — dotfiles-windows

Portable Windows dotfiles (PowerShell profile, Git, Windows Terminal, Tabby/Hyper, package-manager
maintenance). See [README.md](README.md). Design notes: `DECISIONS.md`, `MASTER_PLAN.md`,
`SESSION_HANDOVER.md`.

## The one rule: stay portable

- **Never bake host-specific values into tracked files** — no usernames, drive letters, absolute
  checkout paths, or OneDrive tenant names. Shared behavior lives in the repo; host-specific values
  go in ignored local files: `~/.gitconfig_local`, `DotfilesUpgradeSettings`, or per-host env vars
  (e.g. `DOTFILES_PROFILE_ENABLE_TERMINAL_ICONS=1`).
- Optional tools/modules are detected when present — the profile must still load without them. Don't
  hard-require a tool; guard it.

## Working here

- Install mode `ManagedCopy` is the default (merges, non-admin); `Symlink` is opt-in + elevated.
- **Before pushing**, run: `pwsh -NoProfile -File .\Test-Dotfiles.ps1`, reload the profile clean,
  and `git diff --check`. Run `Invoke-ScriptAnalyzer` / Pester if available.
- Git (commits, branches, PRs) follows the global `~/.claude/CLAUDE.md`.
