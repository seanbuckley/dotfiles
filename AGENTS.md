# AGENTS

Guidance for coding agents working in `seanbuckley/dotfiles`: one chezmoi-managed repo for Windows,
WSL and Linux. `CLAUDE.md` is a one-line `@AGENTS.md` import; edit this file.

**This repo is public, or will be.** Everything committed here can be read, cached and forked.

## Status

Mid-migration from two old repos. Read [docs/status.md](docs/status.md) first and update it before
you stop. The plan, tasks and decisions live in [docs/](docs/).

## Layout

| Path | What |
|---|---|
| `home/` | chezmoi source (`.chezmoiroot`), from Phase 2 |
| `docs/` | Plan, decisions, architecture: [architecture.md](docs/architecture.md) |
| `legacy/` | Frozen, read-only snapshot of the old repos. Never edit; deleted at v1.0.0 |
| `.github/` | CI quality gates ([testing.md](docs/testing.md)) |

Supported platforms and tiers: [platforms.md](docs/platforms.md).

## Validation

- `git diff --check`
- `gitleaks detect --no-git --source .`
- The lint workflow's checks, run locally where available: `shellcheck`, `shfmt -d -i 2 -ci`,
  `Invoke-ScriptAnalyzer`
- From Phase 2: `chezmoi diff` and `chezmoi apply --dry-run`

Report any check you couldn't run.

## Do not change casually

`.chezmoiroot`, chezmoi variable names, the `$PROFILE` loader, `packages.yaml` tiers, CI gates.
Propose the change in the PR body first.

## Privacy

- No secrets, ever: tokens, keys, passwords, Wi-Fi keys, encrypted blobs. Report any you find.
- No host-specific or private details: private IPs, hostnames, usernames other than `seanbuckley`,
  employer or tenant names, absolute user paths, private repo names. Rules:
  [security.md](docs/security.md).
- Email: only the GitHub noreply address.
- Private values go in local files (`~/.gitconfig_local`, `*.local`, chezmoi config), never here.
- The private-words CI job fails on a match and prints file names only. Fix the file; never print
  or commit the word list.

## Working rules

- One concern per PR: never mix repo setup, chezmoi conversion, package redesign, shell overhaul,
  prompt swap or Vite+.
- New idea or unrelated bug: open a `parked` issue and carry on. No feature creep.
- Stop at every phase gate for Sean's review.
- Commits and releases: [decisions.md](docs/decisions.md#commit-convention).

## Core

Shared word for word with Sean's other repos. Edit them together.

### Approval

- Ask every time, even with a session okay: commits, pushes, or merges to `main`; closing PRs; rewriting history on shared branches; bulk deletes or renames.
- Ask once per session: pushing to a branch you didn't create; deleting branches or tags; workflow files, labels, repo settings, releases, deployments; other people's PRs.
- Free: working-tree edits; committing, pushing, rebasing, and force-pushing your own unmerged branch; opening draft or ready PRs; reading anything.
- Trivial fixes may go straight to `main`, but ask first. Trivial means typos, docs, or lint; ≤ 5 files and ~50 lines; no behaviour change; no CI, auth, infra, dependency, or schema files.
- Plan first for destructive, security, infra, or schema changes.
- Issues, comments, and other visible actions beyond PRs in this repo need a fresh ask every time.

### Safety

- Never commit secrets. Report any you find.
- On failure or partial state, stop and report. Don't roll back or repair without approval. Routine cleanup of finished work is fine.
- Run the repo's existing checks before calling work done. Report any you couldn't run.
- Never skip or edit a failing test to get green; report it.

### Commits

- PR titles use `type(scope): summary`, lowercase and imperative. PRs squash-merge, so the title becomes the commit on `main`.
- Commits on your own branch can be rough; only the PR title lands.
- Types and scopes: use the lists in this file. If no scope fits, use the closest and propose an addition in the PR body.
- Keep branches short-lived and delete them after merge.

### References

- Name GitHub items with type, linked number, and a short descriptor: `Issue [#29](https://github.com/<owner>/<repo>/issues/29) (unnecessary header_up warning)`. Cross-repo: prefix `owner/repo`.
- This applies in chat, commits, PR and issue bodies, comments, and committed Markdown.
- In a `Closes` / `Fixes` / `Resolves` line, put the number directly after the keyword: `Closes [#29](url) (descriptor)`. A word in between (`Closes Issue #29`) silently fails to close the issue.

## Commit types and scopes

- Types: `feat`, `fix`, `refactor`, `docs`, `chore`.
- Scopes: `zsh`, `bash`, `pwsh`, `git`, `prompt`, `packages`, `upgrade`, `bootstrap`, `windows`, `linux`, `wsl`, `omarchy`, `ci`, `docs`, `meta` (this file, CLAUDE.md, root README), `repo` (repo-wide), `legacy` (the snapshot).
