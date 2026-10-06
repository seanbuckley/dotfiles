# Issue triage

Every open issue in both old repos, as of 2026-09-30 (52 + 29 = 81), with a proposed
action. **Sean confirms** in task P0d.02 before anything is closed or labelled.

## How to read the tables

| Action | Meaning | What happens |
|---|---|---|
| **Close: done** | Already fixed on `main` | Close now, with the note as the comment |
| **Close: obsolete / superseded** | No longer applies, or replaced by a decision | Close now, linking the decision |
| **Close: duplicate** | The same request exists in the other repo | Close now; the twin survives |
| **Close after P0c** | A list of links/ideas | Close once `docs/research.md` has absorbed it |
| **Fixed-by-design** | The new repo fixes it in the named phase | Label `fixed-by-design`; close at cutover (Phase 6) with a link to the new code |
| **Backlog** | A feature worth keeping, but not for v1 | Label `post-v1`; transfer to the new repo in Phase 6; revisit after v1.0.0 |
| **Review ★** | Unclear intent | Sean decides |
| **Keep open** | Tracking issue | Closed at v1.0.0 |

Summary: 29 close now, 27 fixed-by-design, 20 backlog, 2 close after research, 2 need Sean, 1 tracking.

> [!NOTE]
> **Applied 2026-09-30 (P0d.02).**
> - **Closed 32 issues** with a comment each: 19 in dotfiles, 13 in dotfiles-windows.
> - **Sean's decisions:** #4 moves to the backlog; #50 closed as won't do. #38 was closed as a duplicate of #83.
> - **Labels:** `fixed-by-design` on 27 issues; `post-v1` on 21, plus the new [#118](https://github.com/seanbuckley/dotfiles-legacy/issues/118) (`winget configure`).
> - **Open afterwards:** dotfiles 34, dotfiles-windows 16. Every open issue carries a label except the tracking issue #49.

## seanbuckley/dotfiles (52 open)

| Issue | Title | Action | Phase | Note |
|---|---|---|---|---|
| [#109](https://github.com/seanbuckley/dotfiles-legacy/issues/109) | Update script to include global agents file | Backlog | post-v1 | Twin of windows#65. Scope guard: deferred |
| [#107](https://github.com/seanbuckley/dotfiles-legacy/issues/107) | Make all queries at the start | Close: done | 0d | Done in `setup.sh:31-53`; new bootstrap asks nothing beyond chezmoi init |
| [#106](https://github.com/seanbuckley/dotfiles-legacy/issues/106) | Only one sudo password entry | Close: done | 0d | Done in `utils.sh:77-96`; same pattern kept in `upgrade` |
| [#104](https://github.com/seanbuckley/dotfiles-legacy/issues/104) | Remove wsl-setup.tar.gz references | Close: done | 0d | References are gone from `setup.sh` |
| [#103](https://github.com/seanbuckley/dotfiles-legacy/issues/103) | Audit/repair duplicate PATH entries | Fixed-by-design | P3.02 | PATH built in one place |
| [#101](https://github.com/seanbuckley/dotfiles-legacy/issues/101) | `set -euo pipefail` in all scripts | Close: done | 0d | All scripts have it |
| [#95](https://github.com/seanbuckley/dotfiles-legacy/issues/95) | Full repo review 2026-07-18 | Close: superseded | 0d | Findings folded into this plan |
| [#93](https://github.com/seanbuckley/dotfiles-legacy/issues/93) | NVM loaded twice | Close: obsolete | 0d | nvm removed; vite-plus manages Node |
| [#92](https://github.com/seanbuckley/dotfiles-legacy/issues/92) | trash-cli installed twice | Fixed-by-design | P3.04 | One system trash-cli; npm pair dropped |
| [#91](https://github.com/seanbuckley/dotfiles-legacy/issues/91) | zoxide installed but not initialised | Fixed-by-design | P3.02 |  |
| [#90](https://github.com/seanbuckley/dotfiles-legacy/issues/90) | Remove `sleep 2` from log helpers | Close: done | 0d | Already removed |
| [#89](https://github.com/seanbuckley/dotfiles-legacy/issues/89) | Global .gitignore not activated / too broad | Fixed-by-design | P2.03 |  |
| [#88](https://github.com/seanbuckley/dotfiles-legacy/issues/88) | Add vite-plus to upgrade | Close: done | 0d | `vp upgrade` is in the upgrade alias; kept in the new design |
| [#83](https://github.com/seanbuckley/dotfiles-legacy/issues/83) | Replace `ls` (eza) | Fixed-by-design | P3.03 | eza is *recommended* tier |
| [#82](https://github.com/seanbuckley/dotfiles-legacy/issues/82) | Tailscale tab completion | Backlog | post-v1 | Optional: `tailscale completion zsh` if installed |
| [#81](https://github.com/seanbuckley/dotfiles-legacy/issues/81) | Add McFly | Backlog | post-v1 | Pick **one** of McFly / Atuin (#70); fzf Ctrl-R covers v1 |
| [#80](https://github.com/seanbuckley/dotfiles-legacy/issues/80) | Fastfetch | Backlog | post-v1 | Optional tier |
| [#79](https://github.com/seanbuckley/dotfiles-legacy/issues/79) | GNU Stow | Close: superseded | 0d | chezmoi chosen (decisions D1) |
| [#78](https://github.com/seanbuckley/dotfiles-legacy/issues/78) | Remove plugin manager (antigen) | Close: obsolete | 0d | antigen already gone; OMZ decision D8 |
| [#77](https://github.com/seanbuckley/dotfiles-legacy/issues/77) | Add bat | Fixed-by-design | P3.04 | *recommended* tier |
| [#76](https://github.com/seanbuckley/dotfiles-legacy/issues/76) | Add Difftastic | Backlog | post-v1 | Optional; delta covers v1 |
| [#75](https://github.com/seanbuckley/dotfiles-legacy/issues/75) | Add neofetch | Close: obsolete | 0d | neofetch is archived; see #80 |
| [#74](https://github.com/seanbuckley/dotfiles-legacy/issues/74) | Add TLDR | Backlog | post-v1 | Optional (tealdeer) |
| [#73](https://github.com/seanbuckley/dotfiles-legacy/issues/73) | Script to back up all git repos | Backlog | post-v1 | Scope guard: deferred |
| [#70](https://github.com/seanbuckley/dotfiles-legacy/issues/70) | Atuin | Backlog | post-v1 | See #81 |
| [#66](https://github.com/seanbuckley/dotfiles-legacy/issues/66) | Conditional Git configurations | Fixed-by-design | P2.05 | `includeIf` + local data |
| [#60](https://github.com/seanbuckley/dotfiles-legacy/issues/60) | Replace Z | Fixed-by-design | P3.02 | zoxide |
| [#59](https://github.com/seanbuckley/dotfiles-legacy/issues/59) | Add fd | Fixed-by-design | P3.04 | *recommended* tier |
| [#58](https://github.com/seanbuckley/dotfiles-legacy/issues/58) | Try the Starship prompt | Fixed-by-design | P5 | Decisions D9 |
| [#57](https://github.com/seanbuckley/dotfiles-legacy/issues/57) | Add Glow | Backlog | post-v1 | Optional |
| [#55](https://github.com/seanbuckley/dotfiles-legacy/issues/55) | trash-cli features | Fixed-by-design | P3.03 | No `rm` alias; auto-empty + completions → backlog if wanted |
| [#54](https://github.com/seanbuckley/dotfiles-legacy/issues/54) | Dotfile refresh in upgrade | Fixed-by-design | P3.06 | `upgrade` step 1 = `chezmoi update` |
| [#53](https://github.com/seanbuckley/dotfiles-legacy/issues/53) | Switch p10k to Oh My Posh | Close: superseded | 0d | Starship instead (D9) |
| [#50](https://github.com/seanbuckley/dotfiles-legacy/issues/50) | Add nala | Closed: won't do | 0d | Sean: native `apt-get` is enough |
| [#49](https://github.com/seanbuckley/dotfiles-legacy/issues/49) | Move to chezmoi | Keep open | P7 | Tracking issue; close at v1.0.0 |
| [#47](https://github.com/seanbuckley/dotfiles-legacy/issues/47) | Commands starting with a comma | Backlog | post-v1 | Naming convention for personal scripts |
| [#46](https://github.com/seanbuckley/dotfiles-legacy/issues/46) | Add Tailscale | Backlog | post-v1 | Host setup belongs in the homelab repo, not dotfiles |
| [#45](https://github.com/seanbuckley/dotfiles-legacy/issues/45) | Sync aliases Linux ↔ Windows | Fixed-by-design | P4.01 | One alias table in docs; same names on both OSes where sensible |
| [#43](https://github.com/seanbuckley/dotfiles-legacy/issues/43) | docker-compose aliases | Backlog | post-v1 | Was in OMZ plugin; re-add only if used (P3.01) |
| [#38](https://github.com/seanbuckley/dotfiles-legacy/issues/38) | Command line colours | Closed: duplicate of #83 | 0d | Content was exa/ls colours; covered by eza (#83) and bat |
| [#32](https://github.com/seanbuckley/dotfiles-legacy/issues/32) | Duplicate nvm install (antigen) | Close: obsolete | 0d | antigen and nvm both gone |
| [#29](https://github.com/seanbuckley/dotfiles-legacy/issues/29) | Branches for different machines | Close: superseded | 0d | chezmoi templates + profiles (D1) |
| [#28](https://github.com/seanbuckley/dotfiles-legacy/issues/28) | ZSH plugins & config | Close: superseded | 0d | Covered by D8 + research digest |
| [#27](https://github.com/seanbuckley/dotfiles-legacy/issues/27) | Bare git repo | Close: superseded | 0d | chezmoi (D1) |
| [#26](https://github.com/seanbuckley/dotfiles-legacy/issues/26) | General Dot File Ideas | Closed: done | 0c | Links reviewed in `docs/research.md` |
| [#25](https://github.com/seanbuckley/dotfiles-legacy/issues/25) | Add .bash_profile | Fixed-by-design | P3.03 | bash fallback |
| [#24](https://github.com/seanbuckley/dotfiles-legacy/issues/24) | Add .bashrc | Fixed-by-design | P3.03 | bash fallback |
| [#19](https://github.com/seanbuckley/dotfiles-legacy/issues/19) | Add npkill | Backlog | post-v1 | No install needed: `vp dlx npkill` |
| [#8](https://github.com/seanbuckley/dotfiles-legacy/issues/8) | Add croc | Backlog | post-v1 | Optional |
| [#5](https://github.com/seanbuckley/dotfiles-legacy/issues/5) | Improve SSH key setup | Backlog | post-v1 | Kept manual on purpose ([bootstrap.md](bootstrap.md#safe-unattended-vs-needs-confirmation)) |
| [#4](https://github.com/seanbuckley/dotfiles-legacy/issues/4) | Add wakatime | Backlog | post-v1 | Sean: keep in backlog |
| [#3](https://github.com/seanbuckley/dotfiles-legacy/issues/3) | Add font installations | Fixed-by-design | P5 | Nerd Font for Starship on Windows (Omarchy ships them) |

## seanbuckley/dotfiles-windows (29 open)

| Issue | Title | Action | Phase | Note |
|---|---|---|---|---|
| [#65](https://github.com/seanbuckley/dotfiles-windows/issues/65) | Update script to include global agents file | Backlog | post-v1 | Twin of dotfiles#109 |
| [#63](https://github.com/seanbuckley/dotfiles-windows/issues/63) | Slow profile startup (network Documents) | Fixed-by-design | P4.01 | Apply its fixes 1–3 while porting; fix 4 is machine-local |
| [#61](https://github.com/seanbuckley/dotfiles-windows/issues/61) | Tailscale `upgrade` improvement | Backlog | post-v1 | Needs admin + interactive Y/N |
| [#60](https://github.com/seanbuckley/dotfiles-windows/issues/60) | Convert helper scripts into script modules | Backlog | post-v1 | Port as-is first; refactor later |
| [#58](https://github.com/seanbuckley/dotfiles-windows/issues/58) | Tailscale – review script | Fixed-by-design | P4.01 | Generate completion at runtime if tailscale exists; don't vendor it |
| [#57](https://github.com/seanbuckley/dotfiles-windows/issues/57) | Consolidate into seanbuckley/dotfiles (plan exists) | Close: superseded | 0d | Replaced by this plan / dotfiles#49 |
| [#55](https://github.com/seanbuckley/dotfiles-windows/issues/55) | Prune Tabby, .hyper.js, legacy WT settings | Fixed-by-design | P1.01 | Not copied into the snapshot |
| [#54](https://github.com/seanbuckley/dotfiles-windows/issues/54) | WSL helpers duplicated | Fixed-by-design | P4.05 | `Update-WSL.ps1` replaced by `-IncludeWSL` |
| [#53](https://github.com/seanbuckley/dotfiles-windows/issues/53) | Profile defaults contradict decision 14 | Fixed-by-design | P4.06 |  |
| [#52](https://github.com/seanbuckley/dotfiles-windows/issues/52) | Protect-String bug | Fixed-by-design | P4.06 | Not ported |
| [#45](https://github.com/seanbuckley/dotfiles-windows/issues/45) | Provision WSL | Backlog | post-v1 | Document `wsl --install` in bootstrap.md; automation later |
| [#33](https://github.com/seanbuckley/dotfiles-windows/issues/33) | Hard coded dev folder | Fixed-by-design | P2 | `codeDir` variable |
| [#32](https://github.com/seanbuckley/dotfiles-windows/issues/32) | Add PowerShell.tiPS | Backlog | post-v1 | Optional |
| [#31](https://github.com/seanbuckley/dotfiles-windows/issues/31) | Replace `ls` (eza) | Close: duplicate | 0d | of dotfiles#83 |
| [#30](https://github.com/seanbuckley/dotfiles-windows/issues/30) | Add McFly | Close: duplicate | 0d | of dotfiles#81 |
| [#27](https://github.com/seanbuckley/dotfiles-windows/issues/27) | Fastfetch | Close: duplicate | 0d | of dotfiles#80 |
| [#20](https://github.com/seanbuckley/dotfiles-windows/issues/20) | Add bat | Close: duplicate | 0d | of dotfiles#77 |
| [#17](https://github.com/seanbuckley/dotfiles-windows/issues/17) | Add Difftastic | Close: duplicate | 0d | of dotfiles#76 |
| [#16](https://github.com/seanbuckley/dotfiles-windows/issues/16) | Add Scoop | Close: done | 0d | Scoop is installed and upgraded; winget is the main manager (D5) |
| [#14](https://github.com/seanbuckley/dotfiles-windows/issues/14) | Add TLDR | Close: duplicate | 0d | of dotfiles#74 |
| [#13](https://github.com/seanbuckley/dotfiles-windows/issues/13) | Improve `upgrade` script | Fixed-by-design | P4.05 | [upgrades.md](upgrades.md) |
| [#12](https://github.com/seanbuckley/dotfiles-windows/issues/12) | Back up all git repos | Close: duplicate | 0d | of dotfiles#73 |
| [#10](https://github.com/seanbuckley/dotfiles-windows/issues/10) | Conditional Git configurations | Close: duplicate | 0d | of dotfiles#66 |
| [#9](https://github.com/seanbuckley/dotfiles-windows/issues/9) | Change personal development directory | Fixed-by-design | P2 | `~/code` (D11) |
| [#8](https://github.com/seanbuckley/dotfiles-windows/issues/8) | Starship | Close: duplicate | 0d | of dotfiles#58 |
| [#6](https://github.com/seanbuckley/dotfiles-windows/issues/6) | Check for module updates on start | Fixed-by-design | P4.05 | Moved to `upgrade` (PSModules step), not startup |
| [#4](https://github.com/seanbuckley/dotfiles-windows/issues/4) | Add common bash aliases to PowerShell | Fixed-by-design | P4.01 | With dotfiles#45 |
| [#3](https://github.com/seanbuckley/dotfiles-windows/issues/3) | Integrate jayharris/dotfiles-windows | Close after P0c | 0c | Reviewed in `docs/research.md` |
| [#1](https://github.com/seanbuckley/dotfiles-windows/issues/1) | Zoxide | Close: done | 0d | Profile already uses zoxide |

## Duplicate pairs

The Linux-repo issue survives (it's older, and the Linux repo is the one renamed and transferred from).

| Topic | Survives | Closed as duplicate |
|---|---|---|
| eza | [dotfiles-legacy#83](https://github.com/seanbuckley/dotfiles-legacy/issues/83) | [windows#31](https://github.com/seanbuckley/dotfiles-windows/issues/31) |
| McFly | [dotfiles-legacy#81](https://github.com/seanbuckley/dotfiles-legacy/issues/81) | [windows#30](https://github.com/seanbuckley/dotfiles-windows/issues/30) |
| fastfetch | [dotfiles-legacy#80](https://github.com/seanbuckley/dotfiles-legacy/issues/80) | [windows#27](https://github.com/seanbuckley/dotfiles-windows/issues/27) |
| bat | [dotfiles-legacy#77](https://github.com/seanbuckley/dotfiles-legacy/issues/77) | [windows#20](https://github.com/seanbuckley/dotfiles-windows/issues/20) |
| Difftastic | [dotfiles-legacy#76](https://github.com/seanbuckley/dotfiles-legacy/issues/76) | [windows#17](https://github.com/seanbuckley/dotfiles-windows/issues/17) |
| TLDR | [dotfiles-legacy#74](https://github.com/seanbuckley/dotfiles-legacy/issues/74) | [windows#14](https://github.com/seanbuckley/dotfiles-windows/issues/14) |
| Git repo backup | [dotfiles-legacy#73](https://github.com/seanbuckley/dotfiles-legacy/issues/73) | [windows#12](https://github.com/seanbuckley/dotfiles-windows/issues/12) |
| Conditional git config | [dotfiles-legacy#66](https://github.com/seanbuckley/dotfiles-legacy/issues/66) | [windows#10](https://github.com/seanbuckley/dotfiles-windows/issues/10) |
| Starship | [dotfiles-legacy#58](https://github.com/seanbuckley/dotfiles-legacy/issues/58) | [windows#8](https://github.com/seanbuckley/dotfiles-windows/issues/8) |
| Zoxide | [dotfiles-legacy#60](https://github.com/seanbuckley/dotfiles-legacy/issues/60) | [windows#1](https://github.com/seanbuckley/dotfiles-windows/issues/1) (already done on Windows) |
| Global agents file | [dotfiles-legacy#109](https://github.com/seanbuckley/dotfiles-legacy/issues/109) | [windows#65](https://github.com/seanbuckley/dotfiles-windows/issues/65) (keep both open until transfer; merge then) |
| Dev directory | Both fixed-by-design | [windows#9](https://github.com/seanbuckley/dotfiles-windows/issues/9) + [windows#33](https://github.com/seanbuckley/dotfiles-windows/issues/33) |

## Feature backlog

The "additions" worth keeping, for after v1.0.0. The suggested order is highest value for the least effort first.
Sean re-ranks it at the v1.0.0 review. Each one is a single small PR later: add it to
`packages.yaml` (optional → recommended) plus any config.

| Order | Issue | Feature | Value | Effort | Note |
|---|---|---|---|---|---|
| 1 | [dotfiles-legacy#74](https://github.com/seanbuckley/dotfiles-legacy/issues/74) | tealdeer (`tldr`) | High: quick command examples | Tiny | Package on every OS |
| 2 | [dotfiles-legacy#109](https://github.com/seanbuckley/dotfiles-legacy/issues/109) | Apply the private agents repo's global agent files | High | Small | A `run_onchange_` script, or an `upgrade` step that calls `apply.sh`/`apply.ps1` if `~/code/ai` exists |
| 3 | [dotfiles-legacy#76](https://github.com/seanbuckley/dotfiles-legacy/issues/76) | difftastic (`difft`) | Medium | Tiny | As a git difftool alongside delta |
| 4 | [dotfiles-legacy#81](https://github.com/seanbuckley/dotfiles-legacy/issues/81) / [#70](https://github.com/seanbuckley/dotfiles-legacy/issues/70) | Shell history: Atuin **or** McFly | Medium | Small | Pick one. Atuin syncs across machines (can self-host) |
| 5 | [dotfiles-legacy#80](https://github.com/seanbuckley/dotfiles-legacy/issues/80) | fastfetch | Low (fun) | Tiny | Not on shell start (slows startup) |
| 6 | [dotfiles-legacy#57](https://github.com/seanbuckley/dotfiles-legacy/issues/57) | glow | Low | Tiny | Markdown in the terminal |
| 7 | [dotfiles-legacy#82](https://github.com/seanbuckley/dotfiles-legacy/issues/82) | Tailscale completion | Low | Tiny | Only when tailscale is installed |
| 8 | [dotfiles-legacy#43](https://github.com/seanbuckley/dotfiles-legacy/issues/43) | docker compose aliases | Depends on the P3.01 usage check | Tiny | |
| 9 | [dotfiles-legacy#47](https://github.com/seanbuckley/dotfiles-legacy/issues/47) | Comma-prefixed personal commands | Medium (clarity) | Small | A naming rule for `~/.local/bin` scripts |
| 10 | [dotfiles-legacy#73](https://github.com/seanbuckley/dotfiles-legacy/issues/73) | Back up all git repos | Medium | Medium | Better as a homelab job? |
| 11 | [windows#45](https://github.com/seanbuckley/dotfiles-windows/issues/45) | Provision WSL | Medium | Small | Needs admin; document first |
| 12 | [windows#60](https://github.com/seanbuckley/dotfiles-windows/issues/60) | PowerShell script modules | Medium (maintainability) | Medium | |
| 13 | [windows#61](https://github.com/seanbuckley/dotfiles-windows/issues/61) | `tailscale update` in upgrade | Low | Small | Admin + interactive |
| 14 | [dotfiles-legacy#8](https://github.com/seanbuckley/dotfiles-legacy/issues/8) | croc | Low | Tiny | |
| 15 | [dotfiles-legacy#19](https://github.com/seanbuckley/dotfiles-legacy/issues/19) | npkill | Low | None | Just `vp dlx npkill`; maybe close |
| 16 | [windows#32](https://github.com/seanbuckley/dotfiles-windows/issues/32) | PowerShell.tiPS | Low | Tiny | |
| 17a | [dotfiles-legacy#118](https://github.com/seanbuckley/dotfiles-legacy/issues/118) | `winget configure` (DSC YAML) for Windows packages | Medium | Medium | v1 uses a plain winget list (Sean, 2026-09-30) |
| 17b | [dotfiles-legacy#4](https://github.com/seanbuckley/dotfiles-legacy/issues/4) | wakatime (coding-time tracking) | Low | Small | Kept by Sean |
| 17 | [dotfiles-legacy#5](https://github.com/seanbuckley/dotfiles-legacy/issues/5) | SSH key setup | Medium | Medium | Stays manual; maybe a guide instead of a script |
| — | [dotfiles-legacy#46](https://github.com/seanbuckley/dotfiles-legacy/issues/46) | Tailscale install | — | — | Belongs in the homelab repo; suggest transferring or closing |

## Parked during the migration

New ideas raised while the migration runs go here (and into a `parked` issue):

| Date | Issue | Idea | Raised in |
|---|---|---|---|
| | | | |

## References to update

Links and instructions in other repos that point at the old setup. They're updated in Phase 6,
once the new targets exist, **except** links to old issues. Those change meaning as soon
as the new `dotfiles` repo is created (see [troubleshooting](troubleshooting.md#renamed-repo-redirect-breaks)),
so they're rewritten to `dotfiles-legacy` in P0e.

The private targets (the notes vault, the homelab repo and the agents repo) are listed by path
in the frozen copy of this file, `docs/issue-triage.md` in the private `seanbuckley/dotfiles-legacy`
repo, so this public copy doesn't name them.

| Repo | File | What | When |
|---|---|---|---|
| Vault (private) | ~10 setup, backup and concept notes | Old clone steps, URLs and issue links | Old issue links: **P0e**; the rest: Phase 6 |
| Other private repos | `AGENTS.md` "Core shared word for word by…" | Add `seanbuckley/dotfiles` | P1.05 |
| dotfiles-windows | README, `%LOCALAPPDATA%\dotfiles-windows\upgrade-logs`, `DOTFILES_PROFILE_ENABLE_*` | Names in the ported code | Phase 4: keep the env var names, move logs to `dotfiles` |
