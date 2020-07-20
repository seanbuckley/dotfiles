#!/bin/bash

echo "Updating Ubuntu"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove
sudo apt full-upgrade

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo apt install -y $1
  else
    echo "Already installed: ${1}"
  fi
}

# Add repos
sudo add-apt-repository ppa:aacebedo/fasd
sudo apt-get update -y

# Install command line utils
install build-essential
install git
install curl
install fasd
install zsh
install zsh-antigen

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
nvm install --lts

# Make zsh the default shell
zsh --version
chsh -s $(which zsh)
echo $SHELL