#!/bin/bash
#
#
# --- Linux/WSL Setup Scripts ---
# Install dot files

source ./install/utils.sh
keep_sudo_alive

e_header "Starting dot file installations (dotfile-install.sh)"

# Move up from scripts directory
cd ..

# Copy file from dotfiles director to home
copyDotfile .aliases
copyDotfile .antigenrc
#copyDotfile .bash_profile
#copyDotfile .bashrc
copyDotfile .gitattributes
#copyDotfile .git-completion.bash
copyDotfile .gitconfig
#copyDotfile .gitmessage
copyDotfile .gitignore
#copyDotfile .tmux.conf
#copyDotfile .vimrc
copyDotfile .zshrc