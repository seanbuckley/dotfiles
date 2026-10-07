#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applications via apt
#
# What:     Updates Ubuntu, then installs the base command-line tools with apt,
#           the GitHub CLI (from GitHub's own apt repo) and, on WSL, ubuntu-wsl.
# Run:      by setup.sh (the "apt" step), or on its own: bash scripts/apt-install.sh
# Platform: Ubuntu / WSL Ubuntu only (uses apt-get, dpkg and a Launchpad PPA).
# Needs:    sudo, curl; utils.sh (installPackage, ensure_bin_symlink).
# Fate:     rewrite as the apt branch of the chezmoi package installer, driven by
#           the shared tool list (docs/platforms.md).

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
keep_sudo_alive

e_header "Starting application install (apt-install.sh)"

e_header "Adding repositories"
# Guarded: add-apt-repository re-reads the PPA from Launchpad on every run.
if ! grep -rqs "git-core/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/; then
  sudo add-apt-repository -y ppa:git-core/ppa
else
  e_warning "Already added: ppa:git-core/ppa"
fi

# apt-get, not apt: apt is the interactive front end and warns "does not have a
# stable CLI interface" whenever its output is piped, e.g. into a log with tee.
# Both drive the same package manager. The one default that differs: apt's
# upgrade installs new packages an upgrade depends on, while apt-get's holds
# that upgrade back. --with-new-pkgs gives apt-get apt's behaviour.
e_header "Updating Ubuntu"
sudo apt-get update
sudo apt-get upgrade -y --with-new-pkgs
sudo apt-get autoremove -y

# python3, golang, bat, ripgrep, fd-find, jq, tree and direnv were Homebrew-only
# before; Ubuntu packages them now. Anything still without an apt package lives
# in homebrew-packages.sh instead.
e_header "Installing command line utilities"
installPackage \
  build-essential \
  curl \
  fzf \
  git \
  git-delta \
  grep \
  keychain \
  micro \
  neovim \
  trash-cli \
  tmux \
  zsh \
  python3 \
  golang \
  bat \
  ripgrep \
  fd-find \
  jq \
  tree \
  direnv

# Debian renames these binaries; link them back to the names everything expects.
ensure_bin_symlink batcat bat
ensure_bin_symlink fdfind fd

# WSL detection, rather than asking. See https://github.com/wslutilities/wslu
if grep -qi microsoft /proc/version 2> /dev/null; then
  e_header "WSL detected: installing WSL utilities"
  installPackage ubuntu-wsl
else
  e_warning "Not WSL: skipped WSL utilities."
fi

# See https://github.com/cli/cli/blob/trunk/docs/install_linux.md
e_header "Installing GitHub CLI"
if command -v gh &> /dev/null; then
  e_warning "Already installed: gh ($(gh --version | head -1))"
else
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update
  installPackage gh
fi
# Disabled, kept as a reminder of what was tried:
#   thefuck - noisy, and shadows real command errors
#   the shellcheck package - installed via the VSCode extension instead

e_success "Completed apt-install.sh"
