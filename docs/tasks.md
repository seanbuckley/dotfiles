# Tasks

Step-by-step work for the migration. Each task is sized for **one session**. Each one can be
picked up by a less capable agent, or resumed after an interruption, using only this
file and [status.md](status.md).

- Phases 0 and 1 are fully detailed.
- Later phases are outlined. The agent that opens a phase details its tasks here first, in a docs-only PR, and Sean approves before any work starts.

## Rules for every task

1. **Read [status.md](status.md) first.** Update it at the end of the session, even if you failed.
2. **One task per branch and PR.** Use branch `claude/<task-id>-<slug>` (e.g. `claude/p0b01-annotate-linux`), unless the session assigns one.
3. **Commits and PR titles** follow `type(scope): summary`, lowercase and imperative:
   - Types: `feat`, `fix`, `refactor`, `docs`, `chore`.
   - Scopes are listed in [decisions.md](decisions.md#commit-convention).
   - PRs squash-merge, so the PR title becomes the commit.
   - Open PRs as drafts.
4. **Stay in scope.** For a new idea or unrelated bug, open a `parked` issue and carry on.
5. **Stop and ask Sean** when any of these happens:
   - a validation step fails and the fix isn't obvious;
   - the task would change behaviour that the task doesn't mention;
   - anything looks like a secret;
   - you'd need to touch GitHub settings, tags, releases, or issues outside what the task says.
6. **Never:** commit secrets, force-push `main`, delete branches you didn't create, skip a gate, or combine two tasks.
7. **Owner** says who does it. `Sean` tasks are checklists for him; an agent can prepare commands but not run them.

Task template (copy this when detailing a later phase):

```text
### PXX.NN Title
- Owner:
- Objective:
- Files:
- Actions:
- Validation:
- Expected result:
- Rollback:
- Stop if:
```

---

## Phase 0a: Plan

### P0a.01 Write the plan docs ✅
- Owner: agent
- Objective: a durable plan in the repo, plus a pointer in the vault.
- Files: `docs/*.md` (this set), plus a project note in the vault.
- Validation: `git diff --check`; links resolve; every open issue appears in [issue-triage.md](issue-triage.md).
- Expected result: draft PRs in `seanbuckley/dotfiles` and the vault.
- Rollback: close the PRs.

### P0a.02 Approve the plan ★ ✅
- Owner: Sean
- Actions: read [migration-plan.md](migration-plan.md), [decisions.md](decisions.md) and [schedule.md](schedule.md). Comment on the PR with changes, or approve and merge.
- Gate: tick **0a** in [status.md](status.md).

---

## Phase 0b: Annotate the old repos

Goal: every file in both old repos is explained *before* it is snapshotted.
Comments only. **No behaviour changes**, not even "obvious" fixes; park those as issues.

Comment standard (applies to both repos):

- **Header block at the top of every script and config file**, in the file's own comment syntax. For JSON, which has no comments, describe the file in `CONTENTS.md` instead. The header covers:
  - what the file is for;
  - how it is used: sourced by X, run by Y, or deployed to Z;
  - which platforms it applies to;
  - its dependencies (tools it expects);
  - any gotchas.
- **Inline comments only where the logic is non-obvious:** a regex, a workaround, an ordering requirement, a magic value. Don't narrate simple lines.
- Plain language for a junior developer. Link issues as `owner/repo#N`.
- Keep line endings and encodings exactly as they are. `.ps1` files may be CRLF or UTF-8 with BOM; check with `file` before and after.

### P0b.01 Annotate `seanbuckley/dotfiles` (Linux) ✅
- Owner: agent
- Objective: a `CONTENTS.md`, plus a header on every tracked file.
- Files: all 24 tracked files. New `CONTENTS.md`. A one-line link to it in `README.md`.
- Actions:
  1. Branch from `origin/main`.
  2. Write `CONTENTS.md`: a table per folder with columns *File · Purpose · Used by · Platform · Fate in merge*. "Fate" is one of *port*, *rewrite*, *drop*, or *replaced by chezmoi*, and [architecture.md](architecture.md) is the reference for it.
  3. Add headers to `.zshrc`, `.zprofile`, `.aliases`, `.gitconfig`, `.gitattributes`, `.gitignore`, `.npmrc`, `.shellcheckrc`, and each `scripts/*.sh`. `.p10k.zsh` is generated: add a 3-line header only.
  4. Add section comments in `.aliases` and `.zshrc` where groups of lines lack them.
  5. `README.md`: add "See CONTENTS.md for a file-by-file guide".
- Validation:
  - `git diff --check`
  - `shellcheck scripts/*.sh` gives the same result as on `main` (comments must not add warnings)
  - `zsh -n .zshrc .aliases .zprofile` (syntax only)
  - `bash -n scripts/*.sh`
  - `git diff main --stat` shows only additions in code files (plus `CONTENTS.md`/README)
- Expected result: draft PR `docs(repo): annotate every file and add CONTENTS.md`.
- Rollback: close the PR.
- Stop if: a comment would require explaining behaviour you're unsure of. Write `TODO(sean): what does X do?` in the PR description, not in the file.

### P0b.02 Annotate `seanbuckley/dotfiles-windows` ✅
- Owner: agent, then ★ Sean validates on Windows
- Objective: same as P0b.01, for the Windows repo.
- Files: all 35 tracked files. New `CONTENTS.md`. README link.
- Actions:
  1. Branch from `origin/main`.
  2. `CONTENTS.md` as above. Mark `Tabby/config.yaml`, `.hyper.js` and `Windows Terminal/settings.json` as *drop*, per [windows#55](https://github.com/seanbuckley/dotfiles-windows/issues/55).
  3. Add a comment-based help block (`<# .SYNOPSIS .DESCRIPTION .NOTES #>`) at the top of every `.ps1` that lacks one. That's PowerShell's standard, and it makes `Get-Help` work.
  4. Add inline comments at the non-obvious spots: deferred-warmup queue, cached init, `Get-WingetUpgradeCandidates` column parsing, gsudo cache, UTF-16 WSL output handling, OneDrive discovery.
  5. Mark `SESSION_HANDOVER.md` and `MASTER_PLAN.md` as superseded, with a one-line note at the top pointing to this plan.
- Validation:
  - agent: `git diff --check`; `pwsh -NoProfile -Command` parse check of each `.ps1` if `pwsh` is available, otherwise state that it wasn't run;
  - agent: line-ending check, `file` output unchanged per file.
  - **Sean:** `pwsh -NoProfile -File .\Test-Dotfiles.ps1`, open a new terminal (profile loads, timing similar), run `upgrade -Help`.
- Expected result: draft PR `docs(repo): annotate every file and add CONTENTS.md`.
- Rollback: close the PR.
- Stop if: a file's encoding or line endings would change.

### P0b.03 Merge annotations ★
- Owner: Sean. Review and merge both PRs, then tick gate **0b**.

---

## Phase 0c: Research

### P0c.01 Best-practice digest ✅
- Owner: agent. **Timebox: one session.**
- Objective: `docs/research.md`, a short table per source: *idea · adopt / adapt / reject · why · phase*.
- Sources (Sean's saved references first):
  - The three evanhahn.com posts saved in the vault.
  - A saved list of example dotfiles repos: tomnomnom, victoriadrake, samuelramox/wsl-setup, matchai, lukesmith, jayharris/dotfiles-windows, StefanScherer/dotfiles-windows.
  - [dotfiles-legacy#26](https://github.com/seanbuckley/dotfiles-legacy/issues/26): paulirish, mislav, grml zsh, the upgrade-script reviews and HN threads.
  - [windows#3](https://github.com/seanbuckley/dotfiles-windows/issues/3) (jayharris).
  - [dotfiles-legacy#28](https://github.com/seanbuckley/dotfiles-legacy/issues/28) (awesome-zsh-plugins), for plugins worth keeping only.
  - Vault note *Dotfile* (Dotter, Dotbot): one line on why chezmoi wins.
  - chezmoi examples: [twpayne/dotfiles](https://github.com/twpayne/dotfiles), [joaodrp/omarchy](https://github.com/joaodrp/omarchy), [bandoyer/dotfiles](https://github.com/bandoyer/dotfiles), plus the chezmoi docs on templates, scripts and externals.
  - The [Omarchy manual: dotfiles](https://omarchy.org/manual/dotfiles/) page, to confirm hooks and file ownership.
- Rules: anything "adopt" must fit the [scope guard](migration-plan.md#scope-guard); everything else becomes a backlog line. No new tools are added in this task.
- Validation: every source has a row; every "adopt" names a phase.
- Expected result: docs PR `docs(docs): add best-practice research digest`.
- Stop if: the digest suggests changing a decision in [decisions.md](decisions.md). List it for Sean; don't edit the decision.

### P0c.02 Review research ★
- Owner: Sean. Accept, reject or park each "adopt", then tick gate **0c**.

---

## Phase 0d: Issue triage

### P0d.01 Confirm the triage tables ✅
- Owner: agent
- Objective: [issue-triage.md](issue-triage.md) matches the live issue lists; any issues opened since 2026-09-30 are added.
- Validation: the counts per repo equal the GitHub open-issue counts.

### P0d.02 Act on the triage ★ ✅
- Owner: Sean (or an agent, with explicit per-batch approval, since issues are visible actions)
- Actions:
  1. Create labels in both old repos: `parked`, `post-v1`, `fixed-by-design`.
  2. Close the **Close** rows with the comment given in the table.
  3. Label the **Backlog** rows `post-v1`.
  4. Leave the **Fixed-by-design** rows open until cutover (Phase 6 closes them with a link to the new code).
- Gate: tick **0d**.

---

## Phase 0e: Prepare

### P0e.01 Tag the baseline ★ ✅
- Owner: Sean
- Actions:
  - In each old repo on up-to-date `main`: `git tag -a pre-merge-baseline -m "Last state before the chezmoi merge"`, then `git push origin pre-merge-baseline`.
- Validation: the tag is visible on GitHub for both repos.
- Rollback: `git push --delete origin pre-merge-baseline`.

### P0e.02 chezmoi spike ★ ✅
- Owner: Sean (agent writes the steps in [bootstrap.md](bootstrap.md#spike))
- Objective: prove chezmoi works with Sean's real workflow before building on it.
- Actions: on WSL and on Windows, run `chezmoi init` with a **scratch** source dir, `chezmoi add ~/.gitconfig`, edit it via `chezmoi edit`, `chezmoi diff`, `chezmoi apply`. Use it for a few days.
- Expected result: Sean is comfortable with the edit → diff → apply loop.
- Rollback: `chezmoi purge` removes chezmoi's config and state; `~/.gitconfig` stays as last applied.
- Stop if: anything feels wrong. Record it in [decisions.md](decisions.md) and reassess before P0e.03.

### P0e.03 Repoint existing clones ★ ✅
- Owner: Sean
- Actions: on **every** machine with an old `dotfiles` clone (WSL, Omarchy, any VMs):
  ```sh
  cd ~/code/dotfiles   # or wherever the clone is
  git remote set-url origin https://github.com/seanbuckley/dotfiles-legacy.git
  ```
  Run it **right before** the rename and rename straight after: between the two, fetches fail.
  A machine you can't reach yet keeps working through GitHub's rename redirect, but only until the new
  `seanbuckley/dotfiles` exists, so repoint every machine before creating it.
  `dotfiles-windows` clones need no repoint: that repo isn't renamed.
  Also check the private agents repo and any scripts or cron jobs that clone `seanbuckley/dotfiles`.
- Why: see [troubleshooting](troubleshooting.md#renamed-repo-redirect-breaks).

### P0e.04 Rename and create ★ ✅
- Owner: Sean
- Note (2026-10-05): the new repo was created empty; Sean pushed an empty first commit to `main` so that P1.01 could land as a PR.
- Actions:
  1. GitHub → `seanbuckley/dotfiles` → Settings → rename to `dotfiles-legacy`.
  2. Update its description to "Archived: see seanbuckley/dotfiles".
  3. Create a new **private**, empty `seanbuckley/dotfiles`: no README, licence or .gitignore, so the first commit is ours.
  4. Give the agent session access to the new repo.
- Validation: `git ls-remote https://github.com/seanbuckley/dotfiles-legacy.git` works; the new repo is empty.
- Rollback: before the new repo has content, delete it and rename legacy back.
- Gate: tick **0e**.

---

## Phase 1: Baseline (fresh repo) → v0.1.0

### P1.01 Snapshot the old repos into `legacy/` ✅
- Owner: agent
- Objective: the first commit captures the current files of both repos, without history.
- Actions:
  1. `git archive pre-merge-baseline` from each old repo, extracted into `legacy/linux/` and `legacy/windows/`.
  2. **Exclude** `Tabby/`, `.hyper.js`, `Windows Terminal/settings.json`, `.vscode/` and the old `docs/` (moved to the root in P1.02).
  3. Replace personal emails with the GitHub noreply address (e.g. `.npmrc`). Record each replacement in the PR description.
  4. Add `legacy/README.md`: "Frozen copy of the old repos at `pre-merge-baseline`. Read-only reference. Deleted at v1.0.0."
- Validation:
  - `gitleaks detect --no-git --source .` is clean;
  - the manual checklist in [security.md](security.md) is done;
  - the file count matches the old repos minus the exclusions.
- Expected result: commit `chore(legacy): snapshot old repos at pre-merge-baseline`.
- Stop if: gitleaks or the checklist finds anything. Report it; don't "fix and continue".

### P1.02 Repo scaffolding ✅
- Owner: agent
- Files:
  - `README.md` (what this is, supported OSes, "status: migration in progress", link to `docs/`)
  - `AGENTS.md` + `CLAUDE.md` (`@AGENTS.md`), see [architecture.md](architecture.md#agent-files)
  - `LICENSE` (MIT)
  - `.editorconfig`
  - `.gitattributes` (`* text=auto eol=lf`; only `*.cmd`/`*.bat` CRLF. PowerShell reads LF fine, and one rule is simpler)
  - `.gitignore` (the repo's own ignores, not the global one)
  - `docs/` (this set, moved from the old repo)
- Validation: `git diff --check`; `editorconfig-checker` if available.
- Expected result: PR `chore(repo): add repo scaffolding, agent files and docs`.

### P1.03 CI quality gates ✅
- Owner: agent
- Files: `.github/workflows/lint.yml`, `.github/dependabot.yml` (GitHub Actions updates only).
- Actions: jobs from [testing.md](testing.md#quality-gates): shellcheck + shfmt, PSScriptAnalyzer, gitleaks, private words, JSON/YAML/TOML parse, markdown link check. In Phase 1 these run on `docs/` and root files only; `legacy/` is excluded from lint but **included** in gitleaks and the private-words check.
- Prerequisite (Sean ★): add the `AUDIT_WORDS` Actions secret ([security.md](security.md#private-words)). Until it exists the job fails, rather than passing silently.
- Validation: the workflow is green on the PR.
- Expected result: PR `feat(ci): add lint and secret-scan workflow`.
- Stop if: an action needs a secret or token beyond `GITHUB_TOKEN` and `AUDIT_WORDS`.

### P1.04 Labels and branch protection ★ ✅
- Owner: Sean (agent lists the exact settings)
- Actions: create labels `parked`, `post-v1`, `bug`, `enhancement`; protect `main` (require the PR and the lint check; no force-push).

### P1.05 Update the shared Core line in other repos ✅
- Owner: agent
- Objective: the `AGENTS.md` of each private repo that shares the Core section lists `seanbuckley/dotfiles` too. The link runs one way only: this public repo never names those repos.
- Expected result: one small PR per repo, `docs(meta): add dotfiles to the shared core list`.

### P1.06 Go public and release v0.1.0 ★ ✅
- Owner: Sean
- Actions:
  1. Re-read [security.md](security.md) findings. Confirm both `AUDIT_WORDS` secrets hold the **full** word list (not a temporary one) and that the latest `lint` run on `main` used it and is green.
  2. Settings → change visibility to public.
  3. Tag `v0.1.0` and publish a GitHub Release, "Baseline", with notes from [migration-plan.md](migration-plan.md#what-each-release-means).
- Rollback: set back to private. **Anything already public may have been cached**; that's why the audit comes first.
- Gate: tick **1**.

---

## Phase 2: Shared core → v0.2.0

Nothing in this phase touches a real machine until P2.06. Each task is one PR on the session branch.
CI renders and dry-runs the source on `ubuntu-latest` and `windows-latest` from P2.01 on.

### P2.01 chezmoi skeleton
- Owner: agent
- Files:
  - `.chezmoiroot` → `home`
  - `home/.chezmoiversion` → minimum chezmoi version (2.73.0, current at writing)
  - `home/.chezmoi.toml.tmpl`: the four questions from [architecture.md](architecture.md#variables) (`profile`, `name`, `email`, `codeDir`), each reading its `DOTFILES_*` env var first, then `promptStringOnce` with a default; plus the derived `osID`, `isWSL`, `isOmarchy`
  - `home/.chezmoiignore`: OS gating stubs (empty sections for Windows-only and Linux-only paths)
  - `.github/workflows/lint.yml`: new `chezmoi` job (matrix `ubuntu-latest`, `windows-latest`): install the pinned chezmoi, `chezmoi init --promptDefaults --source .` into a throwaway `HOME`, then `chezmoi apply --dry-run --verbose` and `chezmoi data`
- Validation: the new job is green on both runners; `chezmoi execute-template` on the config template locally; existing jobs still green.
- Rollback: revert the PR. Nothing is applied anywhere yet.
- ★ Sean: add `chezmoi (ubuntu-latest)` and `chezmoi (windows-latest)` to the `main` ruleset's required checks after merge.

### P2.02 One git config
- Owner: agent
- File: `home/dot_gitconfig.tmpl` → `~/.gitconfig`. Not `~/.config/git/config`: `git config --global` and tools like `gh` write to `~/.gitconfig`, which would shadow the XDG file.
- Content, merged from both `legacy/*/.gitconfig`:
  - `[user]` from the `name` / `email` data (defaults: Sean Buckley, the noreply address)
  - the shared `[alias]` block, kept as-is, except the three that hard-coded `master`: replaced per [decisions.md](decisions.md#git-aliases-that-hard-coded-master-2026-10-07) (`main`, default-branch `sync`, `undopush` on `main`)
  - gitalias pulled by `home/.chezmoiexternal.toml` (weekly refresh) and included, replacing the old symlink
  - `delta` as pager and `interactive.diffFilter` only when `lookPath "delta"` finds it; `git-lfs` filter only when `git-lfs` is installed
  - credentials: `gh auth git-credential` for github.com and gist.github.com when `gh` is installed; otherwise the OS default (GCM on Windows)
  - kept: `merge.conflictStyle=zdiff3`, `pull.rebase`, `rebase.autoStash/autoSquash`, `rerere`, `init.defaultBranch=main`
  - added from [research.md](research.md) (git core devs): the 14 safe defaults, one line each with a comment
  - removed: `core.editor` (D10), the old `[color]` block (defaults since git 1.8.4)
  - last line: `[include] path = ~/.gitconfig_local`, so a local file always wins
- Validation: rendered file parses (`git config --file <rendered> --list`) on both CI runners; PR body lists every setting added, changed or dropped against each legacy copy.
- Rollback: revert the PR. On a machine that already applied it: `chezmoi forget ~/.gitconfig` and restore `~/.gitconfig.pre-chezmoi` (P2.06 makes that backup).

### P2.03 Global git ignore
- Owner: agent
- File: `home/dot_config/git/ignore` → `~/.config/git/ignore`, git's default global ignore path on every OS, so no `core.excludesFile` is needed.
- Content: OS and editor junk only (`.DS_Store`, `Thumbs.db`, `desktop.ini`, `*~`, `*.swp`, `.idea/`, `.vscode/`, `*.local`, `audit-words.txt`). No images, `dist/` or `.env`. Fixes [dotfiles-legacy#89](https://github.com/seanbuckley/dotfiles-legacy/issues/89).
- Validation: CI renders it; a test in the job checks that `git check-ignore` ignores `x/.DS_Store` and does **not** ignore `x/a.png` or `x/.env`.
- Rollback: revert the PR.

### P2.04 Editor
- Owner: agent
- File: `home/dot_config/shell/env.sh`: POSIX sh, sets `EDITOR`/`VISUAL` to `micro` if on PATH, else `nano`, without overriding a value the user already set (so `EDITOR=nvim` in a `.local` file wins, D10).
- Not sourced by anything until Phase 3 wires zsh/bash to it; the PowerShell side lands in Phase 4.
- Validation: shellcheck + shfmt (existing `shell` job); a CI test sources it with and without `micro` on PATH and with `EDITOR` preset.
- Rollback: revert the PR.

### P2.05 Work git identity
- Owner: agent
- `home/dot_gitconfig.tmpl` gains one `[includeIf "gitdir:<dir>/"] path = ~/.gitconfig_work` per entry in a `workGitDirs` list. The list lives only in the machine's `~/.config/chezmoi/chezmoi.toml` (`[data]`), never in the repo; empty by default, so the block renders to nothing.
- `~/.gitconfig_work` (work name, email, signing key) is created by Sean per machine. The repo never creates it.
- Closes [dotfiles-legacy#66](https://github.com/seanbuckley/dotfiles-legacy/issues/66) at cutover.
- Validation: CI renders with an empty list and with a sample `workGitDirs = ["/tmp/work"]`; `git config --file` parses both.
- Rollback: revert the PR.

### P2.06 Dry run on real machines ★
- Owner: Sean (agent writes the exact commands in [bootstrap.md](bootstrap.md))
- On WSL and on Windows: back up `~/.gitconfig` to `~/.gitconfig.pre-chezmoi`, then `chezmoi init seanbuckley` (no `--apply`) and `chezmoi diff`. Exact commands: [bootstrap.md](bootstrap.md#phase-2-dry-run-p206). Read the diff; apply only if it looks right, or skip applying until Phase 6.
- Expected result: the diff matches the PR descriptions; no surprises.
- Stop if: the diff changes anything not described, or chezmoi prompts when it shouldn't.
- Gate: tick **2**, then tag `v0.2.0` (tag only, no release).

## Phase 3: Linux → v0.3.0 (outline)

- P3.01 ★ OMZ usage check: agent writes a small script that counts OMZ-alias usage in `~/.zsh_history`; Sean runs it; the results decide which aliases survive ([decisions.md](decisions.md#oh-my-zsh)).
- P3.02 `dot_zshrc.tmpl`: lean zsh with plugins via `.chezmoiexternal`, and zoxide/fzf/direnv init.
- P3.03 `dot_bashrc` fallback + shared `aliases`.
- P3.04 `.chezmoidata/packages.yaml` + `run_onchange_before_10-install-packages.sh.tmpl` (apt/dnf/pacman/apk, tiers).
- P3.05 vite-plus install script.
- P3.06 Linux `upgrade` script ([upgrades.md](upgrades.md)).
- P3.07 Omarchy post-update hook.
- P3.08 `minimal` profile + bootstrap one-liner ([bootstrap.md](bootstrap.md)).
- P3.09 CI container matrix.
- P3.10 ★ Test on Omarchy (spare user or `chezmoi diff` only) and a throwaway LXC.

## Phase 4: Windows → v0.4.0 (outline)

- P4.01 Move the PowerShell profile + Scripts to `home/dot_config/powershell/`.
- P4.02 `run_onchange_after_` script that writes the `$PROFILE` loaders (MyDocuments/OneDrive-safe).
- P4.03 Windows Terminal merge as a `run_onchange_` script.
- P4.04 winget package list from the shared `packages.yaml`.
- P4.05 Port `upgrade` (+vp, −nvm, PS modules, `chezmoi update`, `-IncludeWSL`).
- P4.06 Fix [windows#52](https://github.com/seanbuckley/dotfiles-windows/issues/52), [#53](https://github.com/seanbuckley/dotfiles-windows/issues/53) and [#54](https://github.com/seanbuckley/dotfiles-windows/issues/54) in the ported code.
- P4.07 CI on `windows-latest`.
- P4.08 ★ Test in a spare Windows user profile or VM.
- P4.09 ★ Release v0.4.0.

## Phase 5: Prompt → v0.5.0 (outline)

- P5.01 `dot_config/starship.toml`: one config, commented, close to the current p10k rainbow look.
- P5.02 Init Starship in zsh, bash and PowerShell; remove the p10k and oh-my-posh wiring.
- P5.03 ★ Look-and-feel sign-off.

## Phase 6: Cutover (outline)

One machine per session. Each follows the [bootstrap.md cutover checklist](bootstrap.md#cutover-an-existing-machine).

- P6.01 ★ WSL
- P6.02 ★ Omarchy
- P6.03 ★ Windows: remove the old loaders first
- P6.04 ★ One Proxmox guest (`minimal`)
- P6.05 Rewrite vault links (the list in [issue-triage.md](issue-triage.md#references-to-update))
- P6.06 ★ Transfer surviving issues; close fixed-by-design issues with links

## Phase 7: Retire → v1.0.0 (outline)

- P7.01 Delete `legacy/`.
- P7.02 ★ Final README pointer commits in both old repos, then archive them.
- P7.03 Final doc pass: this migration folder becomes history (`docs/history/`), and the README describes steady state.
- P7.04 ★ Release v1.0.0.
