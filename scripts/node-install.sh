#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applications

keep_sudo_alive

e_header "Starting nvm and nodejs install (node-install.sh)"

# Install NVM
e_header "Installing NVM"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

# This kills the install process
#e_header "Reloading the terminal"
#exec zsh -l

e_header "Sourcing NVM to use in the current process"
source $HOME/.nvm/nvm.sh;

e_header "Installing the latest Node.js using NVM"
nvm install --lts
nvm use --lts
nvm install-latest-npm

e_success "Completed node-install.sh"
