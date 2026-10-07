#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install Homebrew
#
# What:     Installs Homebrew (Linuxbrew) if it is missing, and makes sure a
#           login shell can find it.
# Run:      by setup.sh (the "brew" step), or on its own.
# Platform: Ubuntu / WSL (its dependency install uses apt); macOS paths are
#           detected but untested.
# Needs:    sudo, curl, git; utils.sh (installPackage, run_remote_installer).
# Fate:     drop. The new repo uses native packages on Linux and Homebrew only
#           on macOS (docs/decisions.md, D4).

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
keep_sudo_alive

e_header "Starting Homebrew install (homebrew-install.sh)"

if command -v brew &> /dev/null; then
  e_warning "Already installed: Homebrew ($(brew --version | head -1))"
  exit 0
fi

e_header "Checking for Homebrew dependencies..."
installPackage build-essential procps curl file git

e_header "Installing Homebrew..."
run_remote_installer \
  https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
  /bin/bash NONINTERACTIVE=1

BREW_BINARY=""
for candidate in /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew /opt/homebrew/bin/brew; do
  if [ -x "$candidate" ]; then
    BREW_BINARY="$candidate"
    break
  fi
done

if [ -z "$BREW_BINARY" ]; then
  e_error "Homebrew installation directory not found."
  exit 1
fi

# This repo's .zprofile and .zshrc already initialise Homebrew, and they are
# symlinks into the repo, so nothing may be appended to them. ~/.profile is only
# a fallback for a login shell that is not zsh — and only when no init exists
# anywhere yet, since the dotfiles step may not have run at this point.
PROFILE_FILE="${HOME}/.profile"
if ! grep -qs "brew shellenv" \
  "$PROFILE_FILE" "${HOME}/.zprofile" "${HOME}/.zshrc" 2> /dev/null; then
  e_header "Adding Homebrew to your PATH via ${PROFILE_FILE}"
  cat << 'EOF' >> "$PROFILE_FILE"

# Homebrew initialization
for _brew in /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew /opt/homebrew/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
done
unset _brew
EOF
fi

eval "$("$BREW_BINARY" shellenv)"

if command -v brew &> /dev/null; then
  e_success "Homebrew installed successfully."
  brew --version
else
  e_error "Homebrew installation failed. Please check the logs."
  exit 1
fi

e_success "Completed homebrew-install.sh"
