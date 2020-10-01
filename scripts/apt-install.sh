#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applicatiyons

source ./utils.sh
keep_sudo_alive

e_header "Starting application install (apt-install.sh)"

# Add repos
e_header "Adding Repositories"
sudo add-apt-repository -y ppa:aacebedo/fasd
sudo add-apt-repository -y ppa:git-core/ppa

e_header "Updating Ubuntu"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove
# sudo apt full-upgrade

# Install command line utils
e_header "Installing command line utilities:"
installPackage git
installPackage build-essential
installPackage curl
installPackage fasd
installPackage zsh
#installPackage zsh-antigen # Problems with this version

# Install Antigen manually instead
e_header "Installing Antigen with curl"
sudo curl -L git.io/antigen > ~/.antigen.zsh

# Install WSL items
seek_confirmation "Warning: Is this a WSL installation?"
if is_confirmed; then
  e_header "Installing WSL utilities"
  installPackage ubuntu-wsl # See https://github.com/wslutilities/wslu

  # Install VSCode prerequisites
  #installPackage shellcheck

else
  e_warning "Skipped WSL utilities install"
fi

# Install oh-my-zsh
# Not required. Currently installed by Antigen.
#e_header "Installing Oh My Zsh"
#sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make zsh the default shell
e_header "Making zsh the default shell"
chsh -s $(which zsh)
#chsh -s /bin/zsh

# zsh version info
zsh --version

e_header "Default shell is now: {$SHELL}"

e_success "Completed apt-install.sh"