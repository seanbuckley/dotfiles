#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applications

source ./install/utils.sh
keep_sudo_alive

e_header "Starting nvm and nodejs install (node-install.sh)"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

# Reload Terminal
exec zsh -l

# Install the latest Node.js with NVM
nvm install --lts

e_success "Completed node-install.sh"