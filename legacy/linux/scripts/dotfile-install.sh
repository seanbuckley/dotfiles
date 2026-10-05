#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Symlink dot files into $HOME
#
# What:     Symlinks the repo's dotfiles into $HOME (backing up anything already
#           there) and downloads gitalias.txt.
# Run:      by setup.sh (the "dotfiles" step), or via the `upgradedot` alias.
# Platform: Linux / WSL / macOS.
# Needs:    curl; utils.sh (copyDotfile, installGitAlias).
# Fate:     replaced by chezmoi, which writes the files itself; gitalias moves to
#           .chezmoiexternal (docs/architecture.md).

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

e_header "Starting dot file installations (dotfile-install.sh)"

# Symlinks, not copies, so edits in $HOME are edits to the repo and show up in
# git status. Add a new dotfile here and to the list in README.md.
e_header "Linking dotfiles into ${HOME}. Existing files are backed up."
copyDotfile .aliases
copyDotfile .gitattributes
copyDotfile .gitconfig
copyDotfile .gitignore
copyDotfile .npmrc
copyDotfile .p10k.zsh
copyDotfile .zprofile
copyDotfile .zshrc

# Disabled, kept as a reminder of what was tried: .bash_profile, .bashrc,
# .git-completion.bash, .gitmessage, .tmux.conf, .vimrc.

e_success "Completed dot file installations"

# https://github.com/GitAlias/gitalias — the same path is sourced from .gitconfig
e_header "Adding gitalias.txt to config directory."
installGitAlias
e_success "Completed gitalias.txt installation."
