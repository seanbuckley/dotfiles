#!/bin/bash
#
# --- Node.js Setup Script ---
# Installs Node.js using vite-plus
#
# What:     Installs vite-plus (`vp`) if missing, then uses it to install the
#           latest LTS Node.js and make it the default for new shells.
# Run:      by setup.sh (the "node" step), or on its own.
# Platform: Linux / WSL / macOS.
# Needs:    curl, bash; utils.sh (load_vite_plus).
# Fate:     port to a chezmoi install script, unchanged in spirit
#           (docs/upgrades.md covers keeping it up to date).

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

e_header "Starting Node.js installation (node-install.sh)"

if ! command -v vp &> /dev/null; then
  e_header "Installing vite-plus..."
  # A pipe, not "$(curl …)", so pipefail catches a failed download. See
  # run_remote_installer in utils.sh for why that distinction matters.
  curl -fsSL https://vite.plus | bash
fi

# The installer only updates PATH for new shells, so pick it up here too.
load_vite_plus

if command -v vp &> /dev/null; then
  e_header "Current node version:"
  vp env current || true

  # `vp env default` sets Node for every new shell. `vp env use` would only
  # change this script's own session, which ends with it. "lts" tracks the
  # newest LTS release. The install needs the version spelled out: a bare
  # `vp env install` looks for a project pin and fails outside a project.
  vp env default lts
  vp env install lts

  e_header "New node version installed:"
  vp env current
  e_success "Node.js installation via vite-plus finished."
else
  e_error "vite-plus (vp) not found after installation. Open a new shell and re-run this script."
  exit 1
fi

e_success "Completed node-install.sh"
