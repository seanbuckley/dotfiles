#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install dot files

source ./utils.sh
keep_sudo_alive

e_header "Starting dot file installations (dotfile-install.sh)"

# Move up from scripts directory
cd ..

# Copy file from dotfiles directory to home
copyDotfile .aliases
copyDotfile .antigenrc
#copyDotfile .bash_profile
#copyDotfile .bashrc
copyDotfile .gitattributes
#copyDotfile .git-completion.bash
copyDotfile .gitconfig
#copyDotfile .gitmessage
copyDotfile .gitignore
copyDotfile .p10k.zsh
#copyDotfile .tmux.conf
#copyDotfile .vimrc
copyDotfile .zshrc

e_success "Completed dot file installations"