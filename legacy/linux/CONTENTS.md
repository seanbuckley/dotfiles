# Contents

A file-by-file guide to this repo, written in Phase 0b of the
[migration plan](docs/migration-plan.md). Each file also has a header comment,
except the JSON files, which can't hold comments.

**Fate in merge** says what happens to the file when this repo and
`dotfiles-windows` become one chezmoi-managed repo:

| Fate | Meaning |
|---|---|
| port | Carried over mostly as-is (renamed into chezmoi's layout) |
| rewrite | The idea is kept but the file is rewritten (simpler, cross-platform) |
| replaced by chezmoi | chezmoi does this job itself |
| drop | Not carried over |
| review | Decided in a later phase |

## How the pieces fit

1. `scripts/setup.sh` asks which steps to run, then runs the step scripts in `scripts/`.
2. `scripts/dotfile-install.sh` symlinks the dotfiles below into `$HOME`. Editing `~/.zshrc` therefore edits this repo's `.zshrc`.
3. A new zsh reads `~/.zprofile` (login shells), then `~/.zshrc`, which loads Oh My Zsh, `~/.aliases` and `~/.p10k.zsh`.
4. Day to day, `upgrade` (in `.aliases`) updates the system, and `upgradedot` re-runs the symlink step.

## Root: dotfiles deployed to `$HOME`

| File | Purpose | Used by | Platform | Fate in merge |
|---|---|---|---|---|
| `.zshrc` | Interactive zsh setup: Oh My Zsh + plugins, p10k, Homebrew, PATH, aliases, vite-plus | every interactive zsh | Linux / WSL | rewrite (lean zsh, no Oh My Zsh; D8) |
| `.zprofile` | Login-shell PATH: Homebrew, `~/bin`, `~/.local/bin` | zsh login shells | Linux / WSL / macOS | rewrite (one PATH block) |
| `.aliases` | Aliases and small functions: listing, navigation, `upgrade`, git, WSL, docker | sourced by `.zshrc` | zsh on WSL | rewrite (shared zsh/bash aliases; WSL lines gated) |
| `.p10k.zsh` | Powerlevel10k prompt settings (generated) | sourced by `.zshrc` | zsh | drop (Starship replaces it; D9) |
| `.gitconfig` | Global git settings: identity, gh credential helper, delta, aliases, defaults | git | Linux / WSL | rewrite (merged with the Windows copy into one template; P2.02) |
| `.gitattributes` | LF line endings; CRLF for `.cmd`/`.bat` | git (as this repo's attributes) | all | port (as the new repo's `.gitattributes`) |
| `.gitignore` | Intended global ignore: a large gitignore.io dump. **Not active**, since `core.excludesfile` is unset | nothing yet | all | rewrite (short global ignore; P2.03, dotfiles#89) |
| `.npmrc` | `npm init` defaults (author, version, licence) | npm | all | review (personal values move to local config) |

## Root: repo-only files (not deployed)

| File | Purpose | Used by | Fate in merge |
|---|---|---|---|
| `README.md` | Install steps, script table, environment options | people | rewrite (new README) |
| `CONTENTS.md` | This guide | people, agents | rewrite for the new layout |
| `DEVELOPMENT.md` | How to test the scripts, script order, lint and profiling tips | people | review (useful parts into `docs/`) |
| `TODO.md` | Older to-do list; most items now live in GitHub issues | people | drop (issues are the single tracker) |
| `.shellcheckrc` | ShellCheck settings for `scripts/` | `shellcheck` run from the repo | port |
| `.commitlintrc.json` | Allowed commit types and scopes (Conventional Commits) | commitlint (run by hand) | drop (PR-title convention in `docs/decisions.md`) |
| `.vscode/settings.json` | VS Code: commit scopes for the Conventional Commits extension | VS Code | drop |

## `scripts/`: install scripts (Ubuntu / WSL)

Run in this order by `setup.sh`. Each script can also be run on its own.

| File | Purpose | Platform | Fate in merge |
|---|---|---|---|
| `setup.sh` | Entry point: asks all questions, then runs the steps below | Ubuntu / WSL | replaced by chezmoi (`chezmoi init --apply`) |
| `utils.sh` | Shared helpers: logging, prompts, sudo keep-alive, symlinks, apt installs, vite-plus PATH, safe installers, GitHub host keys, clone-or-update | bash | drop as a library; good ideas reused inline |
| `apt-install.sh` | apt update/upgrade; base tools; GitHub CLI; `ubuntu-wsl` on WSL | Ubuntu / WSL | rewrite (apt branch of the shared package installer) |
| `oh-my-zsh-install.sh` | Oh My Zsh, three zsh plugins, p10k; `chsh` to zsh | Linux / WSL | rewrite (plugins via chezmoi; OMZ/p10k dropped) |
| `homebrew-install.sh` | Installs Linuxbrew | Ubuntu / WSL | drop (native packages; D4) |
| `homebrew-packages.sh` | eza, sd, yq, lazygit, zoxide via brew | wherever brew is | drop (tools move to the shared list) |
| `dotfile-install.sh` | Symlinks the dotfiles; downloads gitalias.txt | Linux / WSL / macOS | replaced by chezmoi |
| `node-install.sh` | Installs vite-plus, then the latest LTS Node | Linux / WSL / macOS | port (as a chezmoi install script) |
| `npm-install.sh` | Global Node CLIs via `vp install -g` | Linux / WSL / macOS | review (npm trash-cli pair dropped; dotfiles#92) |
| `repos-install.sh` | Clones/updates everyday repos into `~/code` (SSH → gh token → anonymous) | Linux / WSL / macOS | review (repo list may move to local data) |

## `docs/`: the migration plan

| File | Purpose |
|---|---|
| `docs/migration-plan.md` | Start here: goal, scope, phases, milestones |
| `docs/status.md` | Where the work is right now (agents update it every session) |
| `docs/tasks.md` | Step-by-step tasks |
| `docs/schedule.md` | Timeline |
| `docs/architecture.md`, `platforms.md`, `bootstrap.md`, `upgrades.md` | Target design |
| `docs/security.md`, `testing.md`, `decisions.md`, `issue-triage.md`, `troubleshooting.md` | Supporting detail |

All of `docs/` moves to the new repo at v0.1.0.
