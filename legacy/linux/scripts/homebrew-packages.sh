#!/bin/bash
#
# --- Homebrew Packages ---
# Only packages without an apt equivalent live here
#
# What:     Installs the few tools that had no apt package: eza, sd, yq,
#           lazygit, zoxide.
# Run:      by setup.sh (the "brew packages" step), or on its own.
# Platform: anywhere Homebrew is installed.
# Needs:    Homebrew (homebrew-install.sh); utils.sh.
# Fate:     drop. These tools move into the shared tool list, installed with
#           each distro's own package manager (docs/platforms.md).

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

e_header "Starting Homebrew package install (homebrew-packages.sh)"

# Homebrew may have been installed in this same run, so its shellenv is not yet
# in this shell. Prefixes differ by platform: linuxbrew, Apple silicon, Intel.
for brew_bin in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if ! command -v brew &> /dev/null && [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
  fi
done

if ! command -v brew &> /dev/null; then
  e_error "Homebrew not found. Run homebrew-install.sh first."
  exit 1
fi

packages=(
  eza     # Modern ls replacement
  sd      # Modern sed replacement
  yq      # YAML processor (jq for YAML)
  lazygit # TUI for git
  zoxide  # Smarter cd
)

# One brew list up front, rather than a `brew list <pkg>` per package: each of
# those spawns a full Homebrew run and is noticeably slow.
installed="$(brew list --formula -1 2> /dev/null || true)"

for package in "${packages[@]}"; do
  # -x so "sd" doesn't match a package that merely contains it.
  if grep -qx "$package" <<< "$installed"; then
    e_warning "Already installed: ${package}"
  else
    e_header "Installing: ${package}"
    brew install "$package" || { e_error "Failed to install: ${package}"; exit 1; }
  fi
done

e_success "Completed Homebrew package install (homebrew-packages.sh)"
