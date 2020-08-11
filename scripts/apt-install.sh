#!/bin/bash

echo "Starting apt-install.sh"

# Add repos
echo "Adding Repositories"
sudo add-apt-repository ppa:aacebedo/fasd

echo "Updating Ubuntu"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove
# sudo apt full-upgrade

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo apt install -y $1
  else
    echo "Already installed: ${1}"
  fi
}

# Install command line utils
install build-essential
install git
install curl
install fasd
install zsh
install zsh-antigen

# Install VSCode prerequisites
# install shellcheck

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
nvm install --lts

# Make zsh the default shell
zsh --version
chsh -s $(which zsh)
echo $SHELL

# TODO
# - SSH keys
# - Setup [ssh keys](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh). Tutorials [here](https://www.howtogeek.com/424510/how-to-create-and-install-ssh-keys-from-the-linux-shell/) and [here](https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix/).
# - Install [MesloNF fonts for Powerlevel10k](https://github.com/romkatv/powerlevel10k#manual-font-installation). Also consider installing Microsoft's [Cascadia Code](https://github.com/microsoft/cascadia-code) font.


echo "Completed apt-install.sh"