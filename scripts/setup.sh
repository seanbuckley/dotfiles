#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Main install script
#
# Windows reminder: Carrage returns must be set to LF, not CF
#
## Referenced from: https://github.com/samuelramox/wsl-setup/blob/master/install/utils.sh

# http://www.gnu.org/software/bash/manual/bashref.html#The-Set-Builtin
# Use the set command:
# -a: Mark variables and function which are modified or created for export to the environment of subsequent commands.
set -a
# Put variables that will be marked for export in here.
# These will be available from within other scripts and other commands.
# If script2 modifies these variables, the modifications will not be present in the other scripts.

# 
# https://stackoverflow.com/a/246128
# "Is a useful one-liner which will give you the full directory name of the script no matter where it is being called from."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/utils.sh

set +a

keep_sudo_alive

e_header "Startng main setup script"

e_header "System version info"
lsb_release -a

e_header "--- Applications ---"
seek_confirmation "Warning: This step will installation basic utilities and applications."
if is_confirmed; then
  #e_header "Please, configure/disable your applications before installation:"
  #nano ${DOTFILES_DIRECTORY}/scripts/apt-install.sh
  bash ./apt-install.sh
else
  e_warning "Skipped installing applications."
fi

e_header "--- Dotfiles ---"
seek_confirmation "Warning: This step may overwrite your existing dot files and git configurations."
if is_confirmed; then
  bash ./dotfile-install.sh
else
  e_warning "Skipped copying dot files."
fi

e_header "--- NVM and Node.js ---"
seek_confirmation "Warning: This step will install nvm and nodejs"
if is_confirmed; then
  bash ./node-install.sh
else
  e_warning "Skipped nvm and nodejs installation."
fi

e_header "--- Global Node Packages ---"
seek_confirmation "Warning: This step will install gloabl npm packages"
if is_confirmed; then
  bash ./npm-install.sh
else
  e_warning "Skipped npm global package installation."
fi

e_header "--- Generate SSH ---"
seek_confirmation "Warning: This step generate will generate SSH keys."
if is_confirmed; then
  ask "Please provide an email address: " && printf "\n"
  ssh-keygen -t rsa -b 4096 -C "$REPLY"
  e_success "Generated SSH key."
  e_warning "After finishing the installation, use the copyssh command to copy the SSH key to the clipboard."
else
  e_warning "Skipped SSH key generation."
fi

e_header "--- Folder Setup ---"
e_header "Creating developer directory in Home"
mkdir ${HOME}/dev

e_header "--- Cleanup ---"
e_header "Removing unnecessary apt files"
sudo apt -y autoremove
e_header "Deleting temporary installation folders"
rm -rf ${HOME}/wsl-setup.tar.gz
rm -rf ${HOME}/wsl-setup.zip
#rm -rf ${DOTFILES_DIRECTORY}

e_success "Ending main setup script. Goodbye."
