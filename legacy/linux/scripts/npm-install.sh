#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install global npm packages
#
# What:     Installs a few global Node CLI tools (npm-check-updates, commitlint,
#           the npm trash-cli pair) with `vp install -g`, falling back to npm.
# Run:      by setup.sh (the "npm" step), or on its own. Needs node-install.sh first.
# Platform: Linux / WSL / macOS.
# Needs:    vite-plus or npm; utils.sh (load_vite_plus).
# Fate:     review. The npm trash-cli/empty-trash-cli pair is dropped
#           (dotfiles#92); the rest may become an optional list.

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

e_header "Starting global npm package installation (npm-install.sh)"

# node-install.sh ran as a separate process, so its PATH change is gone.
load_vite_plus

# Note: @commitlint/cli currently triggers a deprecation warning for its
# transitive dependency `git-raw-commits`. Known upstream issue; we are on the
# latest version and awaiting their migration.
# Disabled, kept as a reminder of what was tried: create-react-app,
# create-react-native-app, eslint, sass, typescript, tslint — all better pinned
# per project than installed globally.
packages=(
  npm-check-updates
  trash-cli
  empty-trash-cli
  @commitlint/cli
  @commitlint/config-conventional
)

# Prefer `vp install -g`. Under vite-plus, `npm install -g` writes to npm's own
# global directory, which is not on PATH, so the npm shim stops mid-run to ask
# to link the binaries onto PATH. It also lands where `vp update -g` —
# the upgrade alias — never looks, and is lost on a Node version switch.
# vite-plus keeps its own globals across Node versions and on PATH.
if command -v vp &> /dev/null; then
  for package in "${packages[@]}"; do
    vp install -g "$package"
  done
elif command -v npm &> /dev/null; then
  e_warning "vite-plus not found; installing with npm instead."
  npm install -g "${packages[@]}"
else
  e_error "Neither vp nor npm found. Run node-install.sh first."
  exit 1
fi

e_success "Finished global package installation."
