#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Main install script
#
# Windows reminder: Carrage returns must be set to LF, not CF
#
## Referenced from: https://github.com/samuelramox/wsl-setup/blob/master/install/utils.sh

source ./scripts/utils.sh
keep_sudo_alive

e_header "Startng main setup script"

e_header "System version info"
lsb_release -a

# Install applications
seek_confirmation "Warning: This step will installation basic utilities and applications."
if is_confirmed; then
  e_header "Please, configure/disable your applications before installation:"
  nano ${DOTFILES_DIRECTORY}/scripts/apt-install.sh
  bash ./scripts/apps.sh
else
  e_warning "Skipped installing applications."
fi

# Copy dot files
seek_confirmation "Warning: This step may overwrite your existing dot files and git configurations."
if is_confirmed; then
  bash ./scripts/dotfile-install.sh
else
  e_warning "Skipped copying dot files."
fi

# Install npm packages
seek_confirmation "Warning: This step will install gloabl npm packages"
if is_confirmed; then
  bash ./scripts/npm-install.sh
else
  e_warning "Skipped npm global package installation."
fi

# Generate ssh
seek_confirmation "Warning: This step generate will generate SSH keys."
if is_confirmed; then
  ask "Please provide an email address: " && printf "\n"
  ssh-keygen -t rsa -b 4096 -C "$REPLY"
  e_success "Generated SSH key."
  e_warning "After finishing the installation, use the copyssh command to copy the SSH key to the clipboard."
else
  e_warning "Skipped SSH key generation."
fi

# Create a directory for projects and development
e_header "Creating developer directory in Home"
mkdir ${HOME}/dev

# Cleanup cached downloads and remove the installation zip and folder
e_header "Removing unnecessary files"
sudo apt -y autoremove
rm -rf ${HOME}/wsl-setup.tar.gz
rm -rf ${HOME}/wsl-setup.zip
#rm -rf ${DOTFILES_DIRECTORY}

e_success "Ending main setup script. Goodbye."