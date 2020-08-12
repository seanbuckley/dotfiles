#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install applications

source ./install/utils.sh
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

e_header "Installing utilities"
function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    e_header "Installing: ${1}..."
    sudo apt install -y $1
  else
    e_warning "Already installed: ${1}"
  fi
}

# Install command line utils
install git
install build-essential
install curl
install fasd
install zsh
install zsh-antigen

# Install WSL items
seek_confirmation "Warning: Is this a WSL installation?"
if is_confirmed; then
  e_header "Installing WSL utilities"
  install ubuntu-wsl # See https://github.com/wslutilities/wslu
else
  e_warning "Skipped WSL utilities install"
fi


# Install VSCode prerequisites
# install shellcheck

# Install oh-my-zsh
# Currently using antigen above
#sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make zsh the default shell
#chsh -s $(which zsh)
chsh -s /bin/zsh

# zsh version info
zsh --version

e_header "Default shell:"
echo $SHELL

e_success "Completed apt-install.sh"