#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applicatiyons

source ./utils.sh
keep_sudo_alive

e_header "Starting application install (apt-install.sh)"

e_header "Adding Repositories"
sudo add-apt-repository -y ppa:aacebedo/fasd
sudo add-apt-repository -y ppa:git-core/ppa

e_header "Github CLI repository"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository https://cli.github.com/packages

e_header "Updating Ubuntu"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove
# sudo apt full-upgrade

e_header "Installing command line utilities:"
installPackage git
installPackage build-essential
installPackage curl
installPackage fasd
installPackage fzf
installPackage zsh
installPackage gh
#installPackage zsh-antigen # Problems with this antigen install method.

# Install Antigen manually instead
e_header "Installing Antigen with curl"
sudo curl -L git.io/antigen > ~/.antigen.zsh

seek_confirmation "Warning: Is this a WSL installation?"
if is_confirmed; then
  e_header "Installing WSL utilities"
  installPackage ubuntu-wsl # See https://github.com/wslutilities/wslu
else
  e_warning "Skipped WSL utilities install"
fi

seek_confirmation "Warning: Is this a Visual Studio Code installation?"
if is_confirmed; then
  e_header "Installing VSCode extension prerequisites"
  #installPackage shellcheck
else
  e_warning "Skipped WSL utilities install"
fi

# Raw ZSH install not required. Currently installed by Antigen.
#e_header "Installing Oh My Zsh"
#sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

e_header "Making zsh the default shell"
chsh -s $(which zsh)
#chsh -s /bin/zsh
zsh --version

e_header "Default shell is now: {$SHELL}"

e_success "Completed apt-install.sh"