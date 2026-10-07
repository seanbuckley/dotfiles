# Development Guide

## Running the Setup

```bash
cd scripts
bash ./setup.sh
```

Setup choices and the SSH key email are asked up front. `chsh` and `ssh-keygen`
may still prompt during installation. Set
`DOTFILES_ASSUME_YES=1` to accept every prompt.

The setup script runs these in order:
1. `apt-install.sh` - System packages via apt
2. `oh-my-zsh-install.sh` - Oh My Zsh, plugins, theme, default shell
3. `homebrew-install.sh` - Homebrew package manager
4. `homebrew-packages.sh` - Homebrew-specific packages
5. `dotfile-install.sh` - Symlink dotfiles into home
6. `node-install.sh` - Node.js via vite-plus
7. `npm-install.sh` - Global npm packages
8. Generates an SSH key
9. `repos-install.sh` - Clone or update the common repos into `~/code`

Three prompts cannot be collected up front, because each belongs to a tool the
run has not reached yet: `chsh` (account password), `ssh-keygen` (passphrase)
and the GitHub sign-in. The choice block names whichever of them applies.

Scripts source `utils.sh` by path, so they can be run from any working directory.

## Running Individual Scripts

```bash
cd scripts
bash ./apt-install.sh       # Install apt packages
bash ./homebrew-install.sh   # Install Homebrew
bash ./homebrew-packages.sh   # Install Homebrew packages
bash ./dotfile-install.sh    # Deploy dotfiles
bash ./node-install.sh       # Install Node.js via vite-plus
bash ./npm-install.sh        # Install global npm packages
bash ./oh-my-zsh-install.sh  # Install Oh My Zsh plugins
bash ./repos-install.sh      # Clone/update common repos
```

## Testing Changes

### Test a Single Script
```bash
cd scripts
bash -x ./script-name.sh
```

### Lint Bash Scripts
```bash
shellcheck scripts/*.sh
```

### Test Against a Throwaway Home
`$HOME` is the only thing the dotfile and repo scripts write to, so:
```bash
T=$(mktemp -d)
HOME="$T" CODE_DIRECTORY="$T/code" bash ./dotfile-install.sh
```

## Profiling Zsh Startup

```bash
# Time shell startup
time zsh -i -c exit

# Profile with detailed breakdown
zsh -xft none -c 'source ~/.zshrc' 2>&1 | tail -30
```

## Common Tasks

### Add a New Dotfile
1. Add file to root of dotfiles repo
2. Add a `copyDotfile` call in [`dotfile-install.sh`](scripts/dotfile-install.sh)
3. Document in README.md

### Add a New Package
1. If apt available: add to [`apt-install.sh`](scripts/apt-install.sh)
2. If Homebrew only: add to [`homebrew-packages.sh`](scripts/homebrew-packages.sh)
3. If npm: add to [`npm-install.sh`](scripts/npm-install.sh)

### Add a New Zsh Plugin
1. Add install to [`oh-my-zsh-install.sh`](scripts/oh-my-zsh-install.sh)
2. Add to plugins list in [`.zshrc`](.zshrc)

### Add a New Repo
Add `owner/name` to the `repos` array in [`repos-install.sh`](scripts/repos-install.sh)
and to the list in README.md.

### Add a New Alias
1. Shell aliases → [`.aliases`](.aliases)
2. Git aliases → [`.gitconfig`](.gitconfig)

## Environment

- **OS**: Linux/WSL/Ubuntu
- **Shell**: Zsh with Oh My Zsh
- **Theme**: Powerlevel10k
- **Editor**: Neovim

## Files to Manually Ignore

When working in the dotfiles repo, these patterns should be locally ignored:

```bash
# Add to .git/info/exclude or use repo-specific gitignore
.*.????-??-??-??????  # Backup files from dotfile-install.sh
.idea/
.DS_Store
```

Note: The `.gitignore` file in this repo is deployed to `~/.gitignore` (your global ignore).
