# Dotfiles TODO

## Critical

- [ ] **UPGRADE**: Transition to **chezmoi** for declarative dotfile management. This will replace the current "copy" script system with templates and secret management. ([#49](https://github.com/seanbuckley/dotfiles/issues/49))
- [x] **UPGRADE**: Transition from copying to symlinking dotfiles. `copyDotfile` in `scripts/utils.sh` now symlinks with a dated backup. (2026-09-21)

## High

- [ ] Impliment system specifc conditionals (e.g. for .gitconfig in WSL vs Linux vs Windows)
- [x] **REFACTOR**: Add robust error handling to all shell scripts. `set -uo pipefail` plus per-command error reporting; a single failed package no longer silently ends the run. (2026-09-21)
- [ ] **REMOVE**: `.aliases:133` - `alias rm=trash` is dangerous. It can break scripts expecting standard `rm` behavior; replace with `alias del=trash` or document the risk. ([#55](https://github.com/seanbuckley/dotfiles/issues/55))
- [ ] **FIX**: Audit and repair broken/duplicate `PATH` entries ([#30](https://github.com/seanbuckley/dotfiles/issues/30)).
- [x] **FIX**: Standardize development directory path on `~/code` via `$CODE_DIRECTORY` ([#72](https://github.com/seanbuckley/dotfiles/issues/72)). (2026-09-21)
- [x] **FEAT**: Adjust scripts to only require one `sudo` password entry at the start. `keep_sudo_alive` now prompts once with `sudo -v`; child scripts inherit the timestamp. (2026-09-21)
- [x] **FEAT**: Adjust scripts to ask all questions at the start, before things get installed. (2026-09-21)

## Medium

- [ ] **REMOVE**: `.zshrc:168` - Redundant `colors` autoload. Oh My Zsh already handles this initialization, making this line unnecessary.
- [ ] **CLEANUP**: `.zshrc:80-113` - Reduce plugin count (currently 20+). Profile startup time and remove redundant plugins like `gatsby`, `ansible`, `node`, and `npm`. ([#78](https://github.com/seanbuckley/dotfiles/issues/78))
- [ ] **FEAT**: Switch shell theme from Powerlevel10k to `Oh My Posh` ([#53](https://github.com/seanbuckley/dotfiles/issues/53)).
- [ ] **FEAT**: Try the `Starship` prompt ([#58](https://github.com/seanbuckley/dotfiles/issues/58)) as an alternative cross-shell prompt.
- [ ] **REPLACE**: `z` with `zoxide` in `.zshrc`. Transition to `zoxide` for faster directory jumping and better integration with tools like `fzf`. ([#60](https://github.com/seanbuckley/dotfiles/issues/60))
- [x] **FIX**: Removed `scripts/setup.sh` references to non-existent files (e.g., `wsl-setup.tar.gz`). (2026-09-21)
- [ ] **FEAT**: Implement conditional Git configurations ([#66](https://github.com/seanbuckley/dotfiles/issues/66)) (e.g., `includeIf` for work/personal).
- [ ] **FEAT**: Modernize core toolset: `bat` ([#77](https://github.com/seanbuckley/dotfiles/issues/77)) and `fd` ([#59](https://github.com/seanbuckley/dotfiles/issues/59)) are installed and symlinked to their usual names; still to add `fastfetch` ([#80](https://github.com/seanbuckley/dotfiles/issues/80)) and `glow` ([#57](https://github.com/seanbuckley/dotfiles/issues/57)).
- [ ] **REMOVE**: Transition away from `antigen` plugin manager ([#78](https://github.com/seanbuckley/dotfiles/issues/78)) to a faster alternative or manual loading.
- [ ] **FEAT**: Add dotfile refresh to the `upgrade` shell alias/script ([#54](https://github.com/seanbuckley/dotfiles/issues/54)).
- [ ] **UPGRADE**: Monitor `@commitlint/cli` for migration away from deprecated `git-raw-commits` to `@conventional-changelog/git-client`.

## Low

- [ ] **ADD**: `.gitconfig:18` - Configure a credential cache timeout (e.g., 3600s) to balance security and convenience during active development.
- [ ] **SPLIT**: `.aliases:107` - The `upgrade` alias is overloaded. Split it into discrete commands like `update` for system packages and `update-node` for npm.
- [ ] **CONSIDER**: Implement XDG Base Directory support. Move configuration files into `~/.config/` where supported to keep the `$HOME` directory cleaner.
- [ ] **CLEANUP**: Remove duplicate `ls` alias definitions in `.aliases`. Line 19 (`ls --color`) and line 27 (`eza`) provide conflicting or redundant functionality. ([#83](https://github.com/seanbuckley/dotfiles/issues/83))
- [ ] **FEAT**: Add `Tailscale` ([#46](https://github.com/seanbuckley/dotfiles/issues/46)) and configure tab completion ([#82](https://github.com/seanbuckley/dotfiles/issues/82)).
- [ ] **FEAT**: Implement a script to back up all local git repositories ([#73](https://github.com/seanbuckley/dotfiles/issues/73)).
- [ ] **FEAT**: Add `docker-compose` aliases ([#43](https://github.com/seanbuckley/dotfiles/issues/43)).
- [ ] **FEAT**: Sync aliases between Linux and Windows ([#45](https://github.com/seanbuckley/dotfiles/issues/45)).
- [ ] **FEAT**: Experiment with starting shell commands with a comma ([#47](https://github.com/seanbuckley/dotfiles/issues/47)) for custom shortcuts.
- [ ] **FEAT**: Add `.bashrc` ([#24](https://github.com/seanbuckley/dotfiles/issues/24)) and `.bash_profile` ([#25](https://github.com/seanbuckley/dotfiles/issues/25)) for better Bash support.
- [ ] **FEAT**: Support branches for different machines ([#29](https://github.com/seanbuckley/dotfiles/issues/29)).
- [ ] **FEAT**: Implement a bare git repo approach ([#27](https://github.com/seanbuckley/dotfiles/issues/27)) for dotfile management.
- [ ] **CLEANUP**: Audit Command Line Colours ([#38](https://github.com/seanbuckley/dotfiles/issues/38)).
- [x] **FEAT**: Automate population of the `~/code` directory via `scripts/repos-install.sh` ([#10](https://github.com/seanbuckley/dotfiles/issues/10)). (2026-09-21)
- [x] **FIX**: Add "check if exists" guards before command execution in scripts ([#9](https://github.com/seanbuckley/dotfiles/issues/9)). (2026-09-21)
- [ ] **CONSIDER**: Evaluate `GNU Stow` ([#79](https://github.com/seanbuckley/dotfiles/issues/79)) as an alternative to `chezmoi`.
- [ ] **FEAT**: Add `Difftastic` ([#76](https://github.com/seanbuckley/dotfiles/issues/76)) for structural diffing.
- [ ] **FEAT**: Add `TLDR` ([#74](https://github.com/seanbuckley/dotfiles/issues/74)) for simplified man pages.
- [ ] **FEAT**: Add `neofetch` ([#75](https://github.com/seanbuckley/dotfiles/issues/75)) for system information display.
- [ ] **FEAT**: Add `npkill` ([#19](https://github.com/seanbuckley/dotfiles/issues/19)) for easy cleanup of `node_modules`.
- [ ] **FEAT**: Add `croc` ([#8](https://github.com/seanbuckley/dotfiles/issues/8)) for secure file transfer.
- [ ] **FEAT**: Add `wakatime` ([#4](https://github.com/seanbuckley/dotfiles/issues/4)) for coding activity tracking.
- [ ] **FEAT**: Implement font installations script ([#3](https://github.com/seanbuckley/dotfiles/issues/3)).
- [ ] **FEAT**: Add `McFly` ([#81](https://github.com/seanbuckley/dotfiles/issues/81)) for neural network powered shell history search.
- [ ] **FEAT**: Add `Atuin` ([#70](https://github.com/seanbuckley/dotfiles/issues/70)) for syncable shell history.
- [ ] **FEAT**: Add `nala` ([#50](https://github.com/seanbuckley/dotfiles/issues/50)) for a prettier and faster `apt` frontend.

---

## Done

- [x] **FEAT**: Transition from NVM to **vite-plus** for Node.js version management. (2026-04-09)
- [x] **FIX**: Hardcoded Homebrew paths (`/home/linuxbrew/.linuxbrew`). Use `eval "$(brew shellenv)"` to support both x86_64 and ARM64 architectures portably. (2026-03-05)
- [x] **FEAT**: Add conventional commit configuration for CLI and VS Code (2026-03-05)
- [x] **FIX**: `utils.sh:56` - Refactored `keep_sudo_alive` with a robust `while true` loop (2026-03-05)
- [x] **FIX**: `setup.sh` / `apt-install.sh` - Corrected "Startng" typo and fixed VSCode extension warning (2026-03-05)
- [x] **UPDATE**: `scripts/setup.sh:87-95` - Modernized SSH key generation to use `ed25519` (2026-03-05)
- [x] **FIX**: Avoid "Moving up from scripts directory" during dotfiles intallation (2026-03-05)
- [x] **FIX**: `scripts/dotfile-install.sh:12` - Replace fragile `cd ..` with `cd "$(dirname "$0")/.."` to ensure the script works correctly regardless of where it's called from  (2026-03-05)
- [x] **FIX**: `utils.sh:6` - `DOTFILES_DIRECTORY` evaluation at call-time (2026-03-01)
