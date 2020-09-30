#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applications

source ./utils.sh
keep_sudo_alive

e_header "Starting nvm and nodejs install (node-install.sh)"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

# Reload Terminal
# This kills the install process
#exec zsh -l

# Source NVM to use in current process
source $HOME/.nvm/nvm.sh;

# Install the latest Node.js with NVM
nvm install --lts
nvm use --lts
nvm install-latest-npm

e_success "Completed node-install.sh"