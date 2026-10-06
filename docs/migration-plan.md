# Migration plan: one chezmoi-managed dotfiles repo

> **Start here.** This is the entry point for the dotfiles consolidation project.
> Current progress lives in [status.md](status.md). The step-by-step work lives in
> [tasks.md](tasks.md). Dates and milestones are in [schedule.md](schedule.md).

| | |
|---|---|
| Plan date | 2026-09-30 |
| Owner | Sean |
| Executors | Sean + AI agents (one small task per session) |
| Final repo | `seanbuckley/dotfiles` (fresh repo, see [Repo and history](#repo-and-history)) |
| Retired repos | `seanbuckley/dotfiles` → renamed `dotfiles-legacy`, and `seanbuckley/dotfiles-windows`. Both archived, not deleted |
| Tracking issue | [dotfiles-legacy#49](https://github.com/seanbuckley/dotfiles-legacy/issues/49) (Move to chezmoi) |
| Earlier review | [dotfiles-legacy#95](https://github.com/seanbuckley/dotfiles-legacy/issues/95) and closed PR [dotfiles-legacy#94](https://github.com/seanbuckley/dotfiles-legacy/pull/94). This plan supersedes the `MERGE_PLAN.md` on that branch |

## Goal

One public-ready repo, managed with [chezmoi](https://www.chezmoi.io), that sets up and
maintains every machine Sean uses:

- Windows 10/11 (PowerShell 7 + Windows PowerShell 5.1)
- WSL (Ubuntu)
- Arch Linux (Omarchy laptop)
- Proxmox LXCs and VMs (Ubuntu/Debian/Fedora/Alpine), using a small `minimal` profile
- macOS later, untested until there's hardware to test on

It should be:

- **Simple.** A junior developer can read any file and understand it. Files are commented, scripts are few, and each script is self-contained.
- **Unattended.** A new machine needs one command.
- **Up to date.** `upgrade` updates the whole machine reliably on each OS.
- **Safe to publish.** No secrets, and no host-specific values.

## Scope guard

The plan must stay small enough to finish. Anything not listed as in scope gets
**parked**: a GitHub issue labelled `parked`, reviewed at the next phase gate. It is
not built now.

| In scope for v1.0.0 | Deferred to after v1.0.0 |
|---|---|
| One repo, chezmoi layout | Most "add tool X" feature issues (see the [backlog](issue-triage.md#feature-backlog)) |
| Existing tools, ported (simplified where sensible) | macOS testing |
| Tool baseline, tiers *required* and *recommended* ([platforms.md](platforms.md)) | Hyprland / Omarchy desktop config |
| `upgrade` on Windows, WSL and Linux | Global agent files from the private agents repo ([dotfiles-legacy#109](https://github.com/seanbuckley/dotfiles-legacy/issues/109)) |
| Bootstrap, including a `minimal` profile for LXC/VM guests | Git backup scripts ([dotfiles-legacy#73](https://github.com/seanbuckley/dotfiles-legacy/issues/73)) |
| Starship prompt on every OS | Calling bootstrap from Ansible / cloud-init in the homelab repo |
| CI quality gates, and going public | Vite+ project migrations (a separate workstream) |

> [!NOTE]
> **Rule for agents:** if Sean asks for something new mid-phase, suggest parking it.
> Only add it to the plan if it blocks a v1.0.0 goal, and say why.

## Current-state inventory (2026-09-30)

A fuller per-file listing is produced in Phase 0b (`CONTENTS.md` in each old repo).

### `seanbuckley/dotfiles` (Linux/WSL), 24 tracked files

| Area | What exists | State |
|---|---|---|
| Shell | `.zshrc`: Oh My Zsh with 23 plugins, Powerlevel10k (`.p10k.zsh`, 1655 lines), vite-plus env. `.zprofile`, `.aliases` | Works. `~/.local/bin` is added to PATH 4 times. zoxide is installed but not initialised. `z` plugin is still active |
| Git | `.gitconfig`: delta, gitalias include, many aliases. `.gitignore`: a 689-line gitignore.io dump | The global ignore is never activated, and it's too broad to activate ([#89](https://github.com/seanbuckley/dotfiles-legacy/issues/89)) |
| Install | `scripts/setup.sh` plus 9 helper scripts. `set -euo pipefail`, prompts asked up front, one sudo prompt | **apt-only** (Ubuntu/WSL). No dnf/pacman/apk |
| Node | vite-plus (`vp`) installed by `node-install.sh`. nvm is removed | Good |
| Upgrade | One `&&` alias chain (`.aliases:114`): apt → brew → vp → omz | Fragile: the first failure skips the rest, and `apt autoremove` prompts |
| Docs/CI | README, DEVELOPMENT.md, TODO.md, `.shellcheckrc`, `.commitlintrc.json` | No CI |
| History | 84 commits. Scanned: no tokens, keys or IPs | Clean |

### `seanbuckley/dotfiles-windows`, 35 tracked files

| Area | What exists | State |
|---|---|---|
| Profile | `PowerShell/Microsoft.PowerShell_profile.ps1`: staged/deferred loading, cached init, oh-my-posh, zoxide, PSReadLine | Fast (~1.1 s). Some doc/code mismatches ([windows#53](https://github.com/seanbuckley/dotfiles-windows/issues/53)) |
| Scripts | `PowerShell/Scripts/*.ps1` (18 files): aliases, utilities, backups, WSL, Terminal merge | Bugs: [windows#52](https://github.com/seanbuckley/dotfiles-windows/issues/52), [windows#54](https://github.com/seanbuckley/dotfiles-windows/issues/54). Hardcoded `C:/dev` and Notepad++ paths |
| Install | `Install-Dotfiles.ps1` (ManagedCopy / Symlink), `Test-Dotfiles.ps1` | Symlink mode is half-implemented |
| Upgrade | `Update-System.ps1`: switches, transcript log, gsudo, choco → winget → Store → Scoop → nvm/npm → Windows Update | Good structure. Still uses nvm. No vite-plus, PS modules or WSL step |
| Terminals | Windows Terminal merge template (used). Legacy WT `settings.json`, Tabby, Hyper (unused) | Prune ([windows#55](https://github.com/seanbuckley/dotfiles-windows/issues/55)) |
| Docs | AGENTS.md, CLAUDE.md, DECISIONS.md (19 decisions), MASTER_PLAN.md, SESSION_HANDOVER.md (stale) | Carry over the useful decisions |
| History | 57 commits. `Tabby/config.yaml` history holds a LAN IP and a username | **Never import this history** |

### Duplicated functionality

- `.gitconfig` exists in both repos and has drifted. Editor, credential helper, local include and gitalias differ.
- These are implemented twice: `upgrade`, `glall` (pull all repos), fzf+bat preview, eza tree listing, and aliases in general.
- About 12 duplicate issue pairs are listed in [issue-triage.md](issue-triage.md#duplicate-pairs).

## Repo and history

**Decision:** start a fresh repo rather than merging git histories.

1. The old `dotfiles` repo is renamed `dotfiles-legacy`. Both old repos are tagged `pre-merge-baseline`, then archived at the end. Their history and issues stay readable.
2. A new, empty `seanbuckley/dotfiles` is created.
3. Its first commit is an **audited snapshot** of both repos' *current files* under `legacy/linux/` and `legacy/windows/`. It carries no git history, so nothing sensitive from old commits comes along.
4. Each later phase moves (`git mv`) or rewrites pieces from `legacy/` into the chezmoi layout. `git log --follow` then shows where each file came from.
5. `legacy/` is deleted at v1.0.0.

The history scrub question is therefore settled. No rewriting is needed, because no history is imported. The
snapshot still goes through the [security checklist](security.md) before the repo goes public.

## Phases

Every phase ends at a **gate**. The agent stops, updates [status.md](status.md), and Sean
reviews before the next phase starts. Tasks inside a phase are listed in
[tasks.md](tasks.md).

| Phase | Summary | Gate / milestone |
|---|---|---|
| **0a Plan** | These docs and a vault pointer | Sean approves the plan |
| **0b Annotate** | Old repos: a `CONTENTS.md` listing every file, header comments on every script/config, and inline comments where the logic is non-obvious. **No behaviour changes.** One PR per repo | Both PRs merged |
| **0c Research** | A one-session digest of best practices → `docs/research.md`, seeded from Sean's saved references | Sean reviews the digest |
| **0d Triage** | Classify every open issue; close obsolete/duplicate issues; build the feature backlog | Issues tidy |
| **0e Prepare** | Tag the baseline. chezmoi spike. Repoint clone remotes. Rename the old repo and create the new one | Tag `pre-merge-baseline` |
| **1 Baseline** | Fresh repo: `legacy/` snapshot, README, agent files, licence, editor/git config files, CI, labels. Audit, then go public | **Release v0.1.0 "Baseline"** |
| **2 Shared core** | chezmoi skeleton and variables. One templated `.gitconfig`. Global git ignore. Editor setup | Tag v0.2.0 |
| **3 Linux** | Lean zsh, bash fallback, tiered package install (apt/dnf/pacman/apk), vite-plus, Linux `upgrade`, Omarchy hook, `minimal` profile, container CI | Tag v0.3.0 |
| **4 Windows** | PowerShell profile, `$PROFILE` loaders, Terminal merge, winget list, ported `upgrade`, Windows CI | **Release v0.4.0 "All platforms"** |
| **5 Prompt** | Starship replaces Powerlevel10k and oh-my-posh | Tag v0.5.0 |
| **6 Cutover** | Move each real machine onto the new repo, one at a time. Rewrite vault links. Transfer surviving issues | All v1 machines migrated |
| **7 Retire** | Delete `legacy/`, archive both old repos, final reference updates | **Release v1.0.0 "Single repo"** |

### What each release means

| Release | Meaning |
|---|---|
| **v0.1.0 Baseline** | Everything is captured in the new public repo, CI is green, and nothing is deployed to machines yet. Old repos are still in daily use |
| **v0.4.0 All platforms** | The new repo can fully set up Windows, WSL, Omarchy and a `minimal` guest, **in test** (containers, a VM, a spare profile) |
| **v1.0.0 Single repo** | Every v1 machine runs from the new repo, and the old repos are archived. This is the point to announce the repo, if ever |

Tags without releases (v0.2.0, v0.3.0, v0.5.0) mark stable checkpoints to roll back to.
Later additions are tagged v1.x. See [decisions.md](decisions.md#releases-and-tags).

## Pre-merge blockers vs safe to defer

**Must happen before the new repo is created (Phase 0):**

- Annotate the old repos (0b), because the snapshot should carry the explanations.
- Triage issues (0d), so duplicates don't get transferred.
- Repoint every existing clone's `origin` to `dotfiles-legacy` **before** the new `dotfiles` exists. See [troubleshooting](troubleshooting.md#renamed-repo-redirect-breaks).
- Prune Tabby, Hyper and the legacy WT settings from the snapshot ([windows#55](https://github.com/seanbuckley/dotfiles-windows/issues/55)). These are simply not copied.

**Not blockers.** These bugs are fixed *by design* in the new repo, so don't fix them in the old repos:

- [#89](https://github.com/seanbuckley/dotfiles-legacy/issues/89) global ignore, [#91](https://github.com/seanbuckley/dotfiles-legacy/issues/91) zoxide, [#92](https://github.com/seanbuckley/dotfiles-legacy/issues/92) trash-cli, [#103](https://github.com/seanbuckley/dotfiles-legacy/issues/103) PATH
- [windows#52](https://github.com/seanbuckley/dotfiles-windows/issues/52), [windows#53](https://github.com/seanbuckley/dotfiles-windows/issues/53), [windows#54](https://github.com/seanbuckley/dotfiles-windows/issues/54), [windows#33](https://github.com/seanbuckley/dotfiles-windows/issues/33)

Exception: if a bug hurts daily use before cutover, fix it in the old repo as a tiny PR.

## Merge procedure (summary)

The detailed steps are in [tasks.md](tasks.md) (P0e and P1).

1. Tag `pre-merge-baseline` on both old repos' `main`.
2. On every machine, run `git remote set-url origin https://github.com/seanbuckley/dotfiles-legacy.git` in the old clone. The rename redirect covers the gap until step 4.
3. Rename `seanbuckley/dotfiles` → `seanbuckley/dotfiles-legacy` in GitHub settings.
4. Create a new, empty, private `seanbuckley/dotfiles`.
5. Agent: copy the current files (not history) into `legacy/`, excluding the pruned files, and run the security audit.
6. Sean: review the audit, then make the repo public. Tag `v0.1.0`.

## Other docs

| Doc | Purpose |
|---|---|
| [status.md](status.md) | Where we are right now. **Agents read and update this first** |
| [tasks.md](tasks.md) | Numbered, resumable tasks with checks and stop conditions |
| [schedule.md](schedule.md) | Timeline, milestones and when Sean is needed |
| [architecture.md](architecture.md) | Target layout, variables, profiles, escape hatches |
| [platforms.md](platforms.md) | Support tiers, per-OS notes, tool baseline |
| [bootstrap.md](bootstrap.md) | New-machine setup, including unattended runs |
| [upgrades.md](upgrades.md) | Design of the `upgrade` commands |
| [security.md](security.md) | Public-readiness checklist and findings |
| [testing.md](testing.md) | CI gates and the test matrix |
| [decisions.md](decisions.md) | Decisions with reasons |
| [issue-triage.md](issue-triage.md) | Every open issue classified, plus the feature backlog |
| [troubleshooting.md](troubleshooting.md) | Known gotchas and fixes |
| [research.md](research.md) | Ideas from other dotfiles repos, with adopt/reject verdicts (P0c) |
