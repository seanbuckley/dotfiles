#!/bin/bash
#
# --- Oh My Zsh Setup Script ---
# Install Oh My Zsh, plugins and theme
#
# What:     Installs Oh My Zsh, three zsh plugins and the Powerlevel10k theme,
#           then makes zsh the default login shell (chsh).
# Run:      by setup.sh (the "zsh" step), or on its own. Needs zsh (apt step).
# Platform: Linux / WSL.
# Needs:    git, curl, zsh; chsh asks for your account password.
# Fate:     rewrite. Oh My Zsh and p10k are planned to go (docs/decisions.md,
#           D8 and D9); the three plugins stay, fetched by chezmoi.

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "${HOME}/.oh-my-zsh" ]; then
  e_warning "Already installed: Oh My Zsh"
else
  e_header "Installing Oh My Zsh"
  # Unattended: don't let the installer run zsh or change the shell here.
  run_remote_installer \
    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
    sh RUNZSH=no CHSH=no KEEP_ZSHRC=yes
fi

# Each must also be listed in the plugins array in .zshrc to take effect.
e_header "Installing Zsh custom plugins"
clone_or_update_git_repo https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM_DIR}/plugins/zsh-autosuggestions"
clone_or_update_git_repo https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM_DIR}/plugins/zsh-syntax-highlighting"
clone_or_update_git_repo https://github.com/zsh-users/zsh-history-substring-search \
  "${ZSH_CUSTOM_DIR}/plugins/zsh-history-substring-search"
clone_or_update_git_repo https://github.com/romkatv/powerlevel10k \
  "${ZSH_CUSTOM_DIR}/themes/powerlevel10k"

# Disabled, kept as a reminder of what was tried:
#   desyncr/auto-ls               - install script no longer works
#   changyuheng/zsh-interactive-cd
#   zsh-users/zsh-completions     - fpath entry only, no plugin load
#   zdharma-continuum/fast-syntax-highlighting - using zsh-syntax-highlighting

e_header "Setting zsh as the default shell"
ZSH_PATH="$(command -v zsh || true)"
if [ -z "$ZSH_PATH" ]; then
  e_error "zsh not installed; default shell unchanged."
  exit 1
elif [ "$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)" = "$ZSH_PATH" ]; then
  e_warning "Default shell is already ${ZSH_PATH}"
else
  # chsh needs the account password — the one prompt this script cannot avoid.
  if chsh -s "$ZSH_PATH"; then
    e_success "Default shell is now ${ZSH_PATH}"
  else
    e_error "Could not set zsh as the default shell."
    exit 1
  fi
fi

# Deliberately no `source ~/.zshrc` or `exec zsh` here: the Powerlevel10k docs
# warn that re-sourcing mid-script is unstable. Reload with `exec zsh -l`.
e_success "Completed oh-my-zsh-install.sh"
