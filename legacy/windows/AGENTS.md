# AGENTS.md

## Purpose
- Keep this repo portable across Windows hosts, drives, usernames, and folder layouts.
- Favor boring, durable PowerShell over clever host-specific shortcuts.

## Branching
- Never work on `main`.
- Create branches from the active feature branch using the `codex/` prefix.
- Keep PRs narrow: fix/runtime, docs/handover, and feature work should be split when practical.

## Commit Hygiene
- Keep commits small, focused, and easy to follow.
- Use Conventional Commits for all commit messages and always include a scope.
- For commits larger than a few lines of changes, include a terse, practical body that explains what changed and why.

## Hard Rules
- Do not hardcode usernames, drive letters, OneDrive tenant names, or repo roots.
- Keep host-specific values in ignored local files such as `Microsoft.PowerShell_profile.local.ps1` and `~/.gitconfig_local`.
- Prefer `$PSScriptRoot`, `$PSCommandPath`, environment variables, and guarded discovery helpers.
- Assume scripts may run in non-interactive shells. Guard UI and PSReadLine features accordingly.

## Validation
- Run PowerShell commands with `-NoProfile` when validating automation behavior.
- Minimum validation before proposing a push:
- `pwsh -NoProfile -File .\Test-Dotfiles.ps1`
  - `pwsh -NoProfile -Command ". .\PowerShell\Microsoft.PowerShell_profile.ps1"`
  - `git diff --check`
- If available, also run `Invoke-ScriptAnalyzer` and relevant `Pester` tests.

## Documentation and Handoffs
- Update `DECISIONS.md` when an implementation choice changes long-term repo behavior.
- Update `SESSION_HANDOVER.md` with current branch, validation status, blockers, and next steps.
- Keep notes terse and operational so another human or agent can resume quickly.
