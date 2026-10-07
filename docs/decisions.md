# Decisions

Short records of what was decided and why. When a decision changes, edit its row and
add a dated note. Don't delete the old reasoning.

## Summary (2026-09-30)

| # | Topic | Decision | Why |
|---|---|---|---|
| D1 | Dotfile manager | **chezmoi** | One repo for Windows + Linux. Templates remove the `.gitconfig` drift. `run_onchange_` scripts replace the setup scripts. Copies files on Windows (no admin). GNU Stow ([#79](https://github.com/seanbuckley/dotfiles-legacy/issues/79)) can't do PowerShell or templates. A bare repo ([#27](https://github.com/seanbuckley/dotfiles-legacy/issues/27)) or per-machine branches ([#29](https://github.com/seanbuckley/dotfiles-legacy/issues/29)) drift. Dotter/Dotbot are less cross-platform. **Validated by the P0e.02 spike before building on it** |
| D2 | Repo and history | Fresh `seanbuckley/dotfiles`; old repo renamed `dotfiles-legacy`; both old repos archived. Current files snapshotted into `legacy/`, **no history imported** | A clean, public-ready history with no scrubbing. The old history stays browsable in the archived repos |
| D3 | Visibility | Public from v0.1.0, after the [audit](security.md) | Unauthenticated bootstrap for CI, LXCs and new machines. Forces good hygiene |
| D4 | Linux packages | Native manager per distro (apt/dnf/pacman/apk) from one list in `packages.yaml`; Homebrew only on macOS | Linuxbrew is heavy, doesn't work on Alpine (musl), and duplicates what distros ship. Omarchy is pacman-based |
| D5 | Windows packages | **winget is the main package manager.** Chocolatey and Scoop are **still installed and kept** (bootstrap installs them; `upgrade` and the backups cover them). A package goes in winget unless it's missing or worse there; then it goes in Chocolatey or Scoop, with the reason noted next to it. *(Clarified 2026-09-30 by Sean: both are required, not optional.)* | One main list keeps things predictable; the other two cover the gaps winget still has |
| D6 | Node | vite-plus (`vp`) on every OS; remove nvm-windows | Linux already moved. Two Node managers fight over PATH |
| D7 | Shell | zsh on workstations; bash on `minimal` and Alpine | zsh is Sean's daily shell; bash is everywhere on small guests |
| D8 | Oh My Zsh | Replace with a lean `.zshrc`. **Final call after the P3.01 usage check** | See [Oh My Zsh](#oh-my-zsh) |
| D9 | Prompt | Starship everywhere, in its own phase (5), replacing p10k and oh-my-posh | One config file for zsh, bash and PowerShell. Replaces two prompt systems. Supersedes [#53](https://github.com/seanbuckley/dotfiles-legacy/issues/53) and [#58](https://github.com/seanbuckley/dotfiles-legacy/issues/58)/[windows#8](https://github.com/seanbuckley/dotfiles-windows/issues/8) |
| D10 | Editor | `$EDITOR`/`$VISUAL` = micro if installed, else nano. No `core.editor` in gitconfig. neovim installed for learning, and one line in a local override (`~/.zshrc.local` / `*.local.ps1`: `EDITOR=nvim`) makes it the editor on that machine; VS Code (`code --wait`) opt-in the same way | micro has Ctrl-S/Ctrl-Q keys like a GUI editor. git, crontab and sudoedit all honour `$EDITOR` |
| D11 | Dev folder | `~/code`, as a chezmoi variable | Avoids a clash with `/dev`. Already used by the Linux scripts ([#72](https://github.com/seanbuckley/dotfiles-legacy/issues/72) closed) |
| D12 | Profiles | `workstation` and `minimal` | Proxmox guests and agent containers want aliases + git, not the full desktop kit |
| D13 | v1 platforms | Windows 10/11, WSL Ubuntu, Arch (Omarchy), plus `minimal` on an Ubuntu guest. Others are CI best effort; macOS later | The machines Sean uses daily; testing is only honest where hardware exists |
| D14 | Secrets | None in the repo. Local config for per-host values; chezmoi `age` later if ever needed | Public repo. Matches SOPS + age elsewhere; the Bitwarden CLI stays retired for automation |
| D15 | Omarchy | Manage only shell/git/CLI files; add a post-update hook that re-runs `chezmoi apply`; `upgrade` calls `omarchy-update` | Omarchy owns its desktop config and updates it; fighting it causes churn |
| D16 | Windows Terminal | Keep the merge-template approach; don't manage `settings.json` as a file | The Terminal app rewrites that file; merging is safer |
| D17 | Scope control | New ideas become `parked` issues and are reviewed at phase gates | Keeps the migration finishable |
| D18 | Vite+ | A separate workstream; the dotfiles only install and upgrade `vp` | Keeps this plan focused |

## chezmoi spike result

P0e.02, 2026-10-05: the edit → diff → apply loop worked on WSL and Windows. Sean's reservation:
chezmoi is one more abstraction layer. D1 stands, with these mitigations:

- Plain files stay plain; a file becomes a template only when it really differs per machine.
- `chezmoi cd` + ordinary `git` is the everyday workflow; no chezmoi-only tricks.
- Revisit at the end of Phase 2 if the layer still feels heavy. Switching is cheap until then.

## Oh My Zsh

What removing Oh My Zsh costs, plugin by plugin, from the current `.zshrc:80-110`:

| OMZ plugin / part | What it gave you | Replacement |
|---|---|---|
| `git` | ~150 short aliases (`gst`, `gco`, `gcmsg`, `gp`, `glog`…) | **The biggest loss.** P3.01 counts which ones you actually use. Keep those as plain aliases, or source just OMZ's `plugins/git/git.plugin.zsh` + `lib/git.zsh` via `.chezmoiexternal` |
| `common-aliases` | `ll`, `la`, `l`, global aliases like `G`/`L` | Own `aliases.sh` (eza-based) |
| `z` | directory jumping | zoxide (`z`, `zi`) ([#91](https://github.com/seanbuckley/dotfiles-legacy/issues/91)) |
| `fzf` | Ctrl-R / Ctrl-T key bindings | `source <(fzf --zsh)` (fzf ≥ 0.48) |
| `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search` | the 3 plugins that matter most | **Kept**, sourced directly (distro package, or `.chezmoiexternal`) |
| `ssh-agent` | starts an agent, loads keys | The OS agent (systemd user `ssh-agent`, Windows OpenSSH service), or `keychain` if needed |
| `colored-man-pages`, `colorize` | coloured man pages, `ccat` | `MANPAGER` using bat; `bat` itself |
| `dotenv` | auto-load `.env` | direnv (already installed, just needs its hook) |
| `extract`, `gitignore` | `x file.tar.gz`, `gi node` | Two tiny commented functions, or dropped |
| `docker`, `docker-compose`, `gh`, `npm`, `node`, `ansible` | completions (+ a few aliases) | The tools ship their own zsh completions. Compose aliases → [#43](https://github.com/seanbuckley/dotfiles-legacy/issues/43) backlog |
| `command-not-found` | "install package X" hint | Ubuntu's `/etc/zsh_command_not_found`; Arch `pkgfile` hook (optional) |
| `aliases`, `alias-finder` | list / suggest aliases | `alias \| rg name` |
| `gatsby`, `vscode`, `zsh-navigation-tools`, `git-extras` | rarely used | Dropped |
| OMZ `lib/` | history settings, completion menu style, key bindings, `..`/`...`, `take`, terminal title | ~40 commented lines of `setopt`/`zstyle`/`bindkey` in `.zshrc` |
| `omz update` | self-updater | Gone. Plugins are updated by `upgrade` (chezmoi externals) |

**Gains:**
- faster shell start;
- every line is visible and commented in one file;
- nothing updates itself behind chezmoi's back;
- the same approach works for bash.

**Fallback:** if the usage check shows heavy reliance on OMZ, keep OMZ loaded via
`.chezmoiexternal` with a short plugin list, and revisit after v1.

## Commit convention

Same Core rules as Sean's other (private) repos:

- PR titles: `type(scope): summary`, lowercase and imperative. PRs squash-merge, so the title becomes the commit on `main`.
- Commits on your own branch can be rough.
- Types: `feat` (new config/feature), `fix` (broken behaviour), `refactor` (restructure, same behaviour), `docs`, `chore` (hygiene, deps).
- Scopes: `zsh`, `bash`, `pwsh`, `git`, `prompt`, `packages`, `upgrade`, `bootstrap`, `windows`, `linux`, `wsl`, `omarchy`, `ci`, `docs`, `meta` (AGENTS/CLAUDE/root README), `repo` (repo-wide), `legacy` (the snapshot).
- If no scope fits, use the closest one and propose an addition in the PR body.

## Releases and tags

- **Tags** mark stable checkpoints (`v0.2.0`, `v0.3.0`, `v0.5.0`, `v1.x`). They're annotated: `git tag -a vX.Y.Z -m "…"`.
- **GitHub Releases** only for meaningful milestones: v0.1.0 *Baseline*, v0.4.0 *All platforms*, v1.0.0 *Single repo*. Release notes = what changed for Sean + known gaps.
- After v1.0.0:
  - minor (`v1.1.0`) = new tool or feature;
  - patch (`v1.0.1`) = fixes;
  - major = a breaking layout or variable change that needs re-running `chezmoi init`.
- The old repos get one tag, `pre-merge-baseline`.

## Carried over from dotfiles-windows `DECISIONS.md`

| Old # | Decision | Status in the new repo |
|---|---|---|
| 1 | Shared UI helpers for script output | **Keep** (PowerShell); Linux `upgrade` uses the same symbols |
| 2 | Dynamic paths, nothing hardcoded | **Keep**; now a repo-wide rule |
| 3 | Safer backups before overwriting | **Keep**; chezmoi shows a diff, and loader/merge scripts back up first |
| 4 | MASTER_PLAN.md | **Superseded** by this plan |
| 5 | No machine defaults in templates | **Keep**; the local overrides rule |
| 6 | Validate with `pwsh -NoProfile` | **Keep**; in testing.md |
| 7 | Repo-owned Chocolatey backups | **Keep** (Chocolatey stays; D5) |
| 8 | WSL kept separate from upgrade | **Changed**: WSL is an opt-in `-IncludeWSL` step that calls the Linux `upgrade` |
| 9 | Local block lists | **Keep** (`WingetBlockedIds`, etc.) |
| 10 | Manual follow-up section in upgrade output | **Keep** |
| 11 | Loaders for both PowerShell editions | **Keep** |
| 12 | Chocolatey reinstall metadata | **Keep** |
| 13 | Lean startup, lazy/cached init | **Keep** |
| 14 | Expensive niceties opt-in | **Keep**; make the code match ([windows#53](https://github.com/seanbuckley/dotfiles-windows/issues/53)) in Phase 4 |
| 15 | Load time as a guardrail | **Keep**; measure before and after profile changes |
| 16 | Bulk-operation output | **Keep** |
| 17 | Winget non-errors reported as notes | **Keep** |
| 18 | Refresh winget sources first | **Keep** |
| 19 | Resolve the oh-my-posh theme path; vendor the theme | **Obsolete** after Phase 5 (Starship) |
