# Status

> **Agents: read this file first, and update it before you stop.**
> It is the single place that says where the migration is. If a session dies part-way
> through, the next agent resumes from here. Keep it short: replace the "Now" section,
> and append one line to the log.

## Now

| Field | Value |
|---|---|
| Phase | **2 Shared core** in progress |
| Active task | P2.01 chezmoi skeleton (PR open) |
| Last verified step | `chezmoi` CI job green on ubuntu + windows; env overrides and a bad profile tested |
| Next step | P2.02 one git config, once P2.01 merges |
| Open PRs | [#11](https://github.com/seanbuckley/dotfiles/pull/11) (P2.01 chezmoi skeleton) |
| Blockers | None |
| Waiting on Sean | Merge #11; then add `chezmoi (ubuntu-latest)` and `chezmoi (windows-latest)` to the `main` ruleset |

## How to resume (for any agent)

1. Read this file, then the current phase in [tasks.md](tasks.md).
2. Check the open branches and PRs listed above. Fetch them, and don't start a second copy.
3. If the active task was interrupted:
   1. Look at the branch's last commit and compare it with the task's steps.
   2. Re-run the task's **validation** commands to see what's done.
   3. Continue from the first step that fails validation.
4. Never skip a gate. If the phase's gate is not ticked in [tasks.md](tasks.md), stop and ask Sean.
5. Commit early and often on your own branch (`wip:` messages are fine there; only the PR title lands on `main`). Update the **Now** table in each commit that changes the state.
6. New idea or unrelated bug? Open a `parked` issue in this repo, note it in the log, and carry on.

## Gates

| Gate | Ticked | Date | Notes |
|---|---|---|---|
| 0a Plan approved | [x] | 2026-09-30 | Plan PR [#113](https://github.com/seanbuckley/dotfiles-legacy/pull/113) merged |
| 0b Old repos annotated | [x] | 2026-09-30 | [#114](https://github.com/seanbuckley/dotfiles-legacy/pull/114), [dotfiles-windows#66](https://github.com/seanbuckley/dotfiles-windows/pull/66) merged |
| 0c Research reviewed | [x] | 2026-09-30 | [seanbuckley/dotfiles-legacy#117](https://github.com/seanbuckley/dotfiles-legacy/pull/117) merged |
| 0d Issues triaged | [x] | 2026-09-30 | 32 closed, 48 labelled, [#118](https://github.com/seanbuckley/dotfiles-legacy/issues/118) opened |
| 0e Repos prepared (`pre-merge-baseline`) | [x] | 2026-10-05 | Tags: legacy `eabd871`, windows `94578fb` (moved from `d737109`); old repo renamed `dotfiles-legacy`; new repo created |
| 1 Baseline (v0.1.0) | [x] | 2026-10-07 | Public; [v0.1.0](https://github.com/seanbuckley/dotfiles/releases/tag/v0.1.0) released |
| 2 Shared core (v0.2.0) | [ ] | | |
| 3 Linux (v0.3.0) | [ ] | | |
| 4 Windows (v0.4.0) | [ ] | | |
| 5 Prompt (v0.5.0) | [ ] | | |
| 6 Cutover | [ ] | | |
| 7 Retire (v1.0.0) | [ ] | | |

## Log

Newest last. One line per session: `date · who · task · result`.

- 2026-09-30 · agent · P0a.01 · Reviewed both repos and all open issues; wrote `docs/` plan set; vault pointer PR opened.
- 2026-09-30 · Sean · P0a.02 · Plan approved (#113 merged).
- 2026-09-30 · agent · P0b.01 · Annotated every file, added CONTENTS.md; no behaviour changes.
- 2026-09-30 · Sean · P0b.01 · Merged #114 (annotations) and #115 (mkcd, ls colour, gh credential fixes); credential fix confirmed on WSL.
- 2026-09-30 · agent · P0b.02 · Annotated dotfiles-windows, added CONTENTS.md; no behaviour changes.
- 2026-09-30 · Sean · P0b.02 · Windows checks on the main Windows PC: Test-Dotfiles OK (one pre-existing `.gitconfig` wiring warning), `upgrade -Help` OK, fresh tab loads fine.
- 2026-09-30 · agent · P0c.01 · Wrote `docs/research.md`; no conflicts with decisions, two questions for Sean.
- 2026-09-30 · Sean · P0b.02 · Merged dotfiles-windows#66; gate 0b done. Clarified D5: Chocolatey and Scoop stay required; winget is the main manager.
- 2026-09-30 · Sean · P0c/P0d · Answered the research questions (glall → script; no install wrapper; plain winget list, `winget configure` post-v1). Approved the triage run; #4 kept, #50 closed.
- 2026-09-30 · agent · P0d.02 · Closed 32 issues, labelled 48 (`fixed-by-design` / `post-v1`), opened #118. Verified counts 34 / 16.
- 2026-09-30 · Sean · P0c · Merged #117; gate 0c done (not recorded at the time).
- 2026-10-05 · Sean · P0e.01 · Re-tagged `dotfiles-windows` `pre-merge-baseline` at `94578fb` to include the latest bug-fix PRs.
- 2026-10-05 · Sean · P0e.02 · chezmoi spike done on WSL and Windows. Works; reservation about one more abstraction layer (see decisions.md).
- 2026-10-05 · Sean · P0e.03–04 · Repointed clones (one retired machine skipped); renamed to `dotfiles-legacy`; created the new repo with an empty first commit; gate 0e done.
- 2026-10-05 · agent · P1.01 · Snapshot PR #1: 58 files, gitleaks clean, private repo names removed after Sean's word-list run.
- 2026-10-07 · Sean · P1.01 · Merged #1. D10 editor: micro → nano stays the default; neovim per machine via a one-line local override (option B).
- 2026-10-06 · agent · P1.02 · Moved `docs/` here, scrubbed private repo names and hostnames, fixed old issue links to `dotfiles-legacy`; added the private-words layer to security.md and P1.03.
- 2026-10-07 · Sean · P1.02 · Merged #2; vault link fix merged in the vault.
- 2026-10-07 · agent · P1.03 · Added `lint.yml` (7 jobs) and Dependabot for Actions; all 7 jobs green on the PR, including private words with the Actions secret.
- 2026-10-07 · Sean · P1.03–04 · Merged #3. Labels and `main` ruleset created. `AUDIT_WORDS` set in Actions and Dependabot with a minimal temporary list; full list to follow.
- 2026-10-07 · agent · P1.05 · Core line updated in the three private repos (one PR each), merged by Sean. #4 merged.
- 2026-10-07 · Sean · P1.06 · Full `AUDIT_WORDS` in both secrets; audit checklist ticked (#7); repo made public; secret scanning and push protection on; `v0.1.0` Baseline released. Gate 1 done.
- 2026-10-07 · Sean · Gate 1 · Go-ahead for Phase 2.
- 2026-10-07 · agent · Phase 2 · Detailed P2.01–P2.06 in tasks.md.
- 2026-10-07 · agent · P2.02 prep · Recorded Sean's call on the `master` aliases in decisions.md (`main`, default-branch `sync`, `undopush` on `main`).
- 2026-10-07 · agent · P2.01 · chezmoi skeleton: `.chezmoiroot`, config template with `DOTFILES_*` overrides, OS-gating `.chezmoiignore`, `chezmoi` CI job on ubuntu + windows.
