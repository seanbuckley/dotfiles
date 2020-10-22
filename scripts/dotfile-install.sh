#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Install dot files

source ./utils.sh
keep_sudo_alive

e_header "Starting dot file installations (dotfile-install.sh)"

e_header "Moving up from scripts directory"
cd ..

e_header "Copying dotfiles directory to home. Existing dotfiles will be backed up."
copyDotfile .aliases
copyDotfile .antigenrc
#copyDotfile .bash_profile
#copyDotfile .bashrc
copyDotfile .gitattributes
#copyDotfile .git-completion.bash
copyDotfile .gitconfig
#copyDotfile .gitmessage
copyDotfile .gitignore
copyDotfile .npmrc
copyDotfile .p10k.zsh
#copyDotfile .tmux.conf
#copyDotfile .vimrc
copyDotfile .zshrc

e_success "Completed dot file installations"