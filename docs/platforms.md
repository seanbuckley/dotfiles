# Platforms and tools

## Support tiers

| Tier | Platforms | Meaning |
|---|---|---|
| **v1 (tested on real hardware)** | Windows 10/11 · WSL Ubuntu · Arch (Omarchy) · Ubuntu Server guest (`minimal`) | Must work before v1.0.0. Tested by Sean |
| **Best effort (CI only)** | Fedora · Debian/Ubuntu containers · Alpine (`minimal`, bash) | CI applies the dotfiles in a container. Not used daily |
| **Later** | macOS | Templates avoid Linux-only assumptions, and Homebrew is the package manager. **Not tested; nobody should claim it works.** A CI job may run with "allowed to fail" |

## Per-OS notes

| OS | Package manager | Shell | Notes |
|---|---|---|---|
| Windows | `winget` (main), plus Chocolatey and Scoop, both always installed (D5). Packages winget lacks or handles badly go in Chocolatey/Scoop, with the reason noted | PowerShell 7 (+5.1 loader) | `$PROFILE` may be on OneDrive or a network share. gsudo for elevation |
| WSL Ubuntu | `apt-get` | zsh | `isWSL` adds `open`/clipboard helpers. Windows `upgrade -IncludeWSL` runs the Linux `upgrade` inside WSL |
| Arch (Omarchy) | `pacman` (+ `yay` for AUR, only if needed) | zsh | `upgrade` calls `omarchy-update`, not `pacman -Syu`. Manage CLI files only |
| Ubuntu/Debian guests | `apt-get` | bash or zsh | `minimal` profile by default |
| Fedora | `dnf` | zsh | Best effort |
| Alpine | `apk` | bash | `minimal` only. musl: some tools are missing or older |
| macOS | `brew` | zsh | Later |

## Tool baseline

Tiers:

- **Required:** installed on every machine and every profile (`minimal` too). Scripts may assume these exist.
- **Recommended:** installed on `workstation`. Config must still work without them (guarded with `command -v` / `Get-Command`).
- **Optional:** not installed automatically. Listed so the config knows how to use them if present, or as candidates to promote.

> Package names below are a starting point written from memory on 2026-09-30.
> Task P3.04 verifies each one against the distro's repo (e.g. `apt-cache policy`,
> `dnf info`, `pacman -Si`, `apk search`), and CI proves they install.

A tool earns its place by replacing something or saving real time, not by being popular.
Promoting a tool = one small PR that edits `packages.yaml` plus this table.

### Required

| Tool | Why | winget | apt | dnf | pacman | apk | brew |
|---|---|---|---|---|---|---|---|
| git | everything | `Git.Git` | `git` | `git` | `git` | `git` | `git` |
| curl | bootstrap, downloads | built in | `curl` | `curl` | `curl` | `curl` | built in |
| chezmoi | dotfile manager | `twpayne.chezmoi` | one-liner¹ | `chezmoi` | `chezmoi` | `chezmoi` | `chezmoi` |
| micro | default `$EDITOR` | `zyedidia.micro` | `micro` | `micro` | `micro` | `micro` | `micro` |
| nano | fallback editor | via Git for Windows | `nano` | `nano` | `nano` | `nano` | `nano` |
| fzf | fuzzy finder (history, files) | `junegunn.fzf` | `fzf` | `fzf` | `fzf` | `fzf` | `fzf` |
| ripgrep | fast search (`rg`) | `BurntSushi.ripgrep.MSVC` | `ripgrep` | `ripgrep` | `ripgrep` | `ripgrep` | `ripgrep` |
| zoxide | smarter `cd` (`z`) | `ajeetdsouza.zoxide` | `zoxide` | `zoxide` | `zoxide` | `zoxide` | `zoxide` |
| jq | JSON on the command line | `jqlang.jq` | `jq` | `jq` | `jq` | `jq` | `jq` |
| bash / zsh | shells | — | `zsh` | `zsh` | `zsh` | `bash` | built in |
| Chocolatey | Windows package manager (secondary; D5) | install script (chocolatey.org) | — | — | — | — | — |
| Scoop | Windows package manager (secondary; D5) | install script (get.scoop.sh) | — | — | — | — | — |

¹ Ubuntu's apt has no current `chezmoi`; the official install script (`get.chezmoi.io`) puts it in `~/.local/bin`.

### Recommended (workstation)

| Tool | Why | winget | apt | dnf | pacman | apk | brew | Issue |
|---|---|---|---|---|---|---|---|---|
| gh | GitHub CLI, auth helper | `GitHub.cli` | `gh`² | `gh` | `github-cli` | `github-cli` | `gh` | |
| bat | `cat` with colours; fzf preview; man pager | `sharkdp.bat` | `bat`³ | `bat` | `bat` | `bat` | `bat` | [#77](https://github.com/seanbuckley/dotfiles-legacy/issues/77) |
| fd | friendly `find` | `sharkdp.fd` | `fd-find`³ | `fd-find` | `fd` | `fd` | `fd` | [#59](https://github.com/seanbuckley/dotfiles-legacy/issues/59) |
| eza | `ls` replacement | `eza-community.eza` | `eza` | `eza` | `eza` | `eza` | `eza` | [#83](https://github.com/seanbuckley/dotfiles-legacy/issues/83) |
| git-delta | readable git diffs | `dandavison.delta` | `git-delta` | `git-delta` | `git-delta` | `delta` | `git-delta` | |
| starship | prompt (Phase 5) | `Starship.Starship` | install script | `starship` | `starship` | `starship` | `starship` | [#58](https://github.com/seanbuckley/dotfiles-legacy/issues/58) |
| direnv | per-folder env vars | — | `direnv` | `direnv` | `direnv` | `direnv` | `direnv` | |
| neovim | learning; `nvim` | `Neovim.Neovim` | `neovim` | `neovim` | `neovim` | `neovim` | `neovim` | |
| yq | YAML/TOML on the command line | `MikeFarah.yq` | `yq`⁴ | `yq` | `go-yq` | `yq` | `yq` | |
| tree, wget, unzip | basics | — | ✓ | ✓ | ✓ | ✓ | ✓ | |
| trash-cli | safe delete (`trash`), **no** `rm` alias | — | `trash-cli` | `trash-cli` | `trash-cli` | — | — | [#92](https://github.com/seanbuckley/dotfiles-legacy/issues/92), [#55](https://github.com/seanbuckley/dotfiles-legacy/issues/55) |
| vite-plus (`vp`) | Node runtime + JS toolchain | install script | install script | install script | install script | — | install script | [#88](https://github.com/seanbuckley/dotfiles-legacy/issues/88) |
| gsudo | elevation on Windows | `gerardog.gsudo` | — | — | — | — | — | |
| PowerShell 7 | shell | `Microsoft.PowerShell` | — | — | — | — | — | |

² Ubuntu's `gh` comes from GitHub's apt repo (the existing script adds it).
³ Debian/Ubuntu name the binaries `batcat` and `fdfind`; the config aliases them.
⁴ Ubuntu's `yq` is a different tool on older releases; check the version at install time, or park `yq` as optional on apt.

### Optional (not auto-installed; see the backlog)

`just`, lazygit, sd, tealdeer (`tldr`), difftastic, fastfetch, glow, btop, atuin **or**
mcfly (pick one, not both), croc, nala, npkill (`vp dlx npkill`), Terminal-Icons,
PowerShell.tiPS.

Each has a triage row in [issue-triage.md](issue-triage.md#feature-backlog).

> `just` vs `make`: neither is needed for v1. The repo's own commands are
> `chezmoi` and the CI workflow. If a task runner is ever wanted for repo chores,
> prefer `just` (clearer syntax, and it works on Windows), as an optional tool.

## Dropped

| Tool | Why |
|---|---|
| Oh My Zsh | Replaced by a lean `.zshrc` (see [decisions.md](decisions.md#oh-my-zsh)) |
| Powerlevel10k, oh-my-posh | Replaced by Starship |
| nvm / nvm-windows | vite-plus manages Node |
| keychain | Unused; OS SSH agent instead |
| npm `trash-cli`, `empty-trash-cli` | Duplicates of the system trash-cli |
| Homebrew on Linux | Native packages instead |
| Tabby, Hyper configs | Unused / self-syncing |
