# ==============================================================================
# ~/.zprofile: zsh login-shell setup (Linux / WSL / macOS)
#
# What:     Sets up PATH for login shells: Homebrew, ~/bin and ~/.local/bin.
# Used by:  zsh login shells only (a new terminal on most systems, `zsh -l`,
#           `zsh -lc cmd`). Runs *before* ~/.zshrc. Symlinked by
#           scripts/dotfile-install.sh.
# Gotchas:  ~/.local/bin is added twice below (the second copy was appended by
#           an installer) and again in .zshrc (dotfiles#103).
# Fate:     merge into one PATH-building block in the new shell config.
# ==============================================================================

# Homebrew initialization. The same guarded block is in .zshrc on purpose:
# .zprofile covers login shells, including non-interactive ones (`zsh -lc`, which
# never read .zshrc); .zshrc covers interactive non-login shells, which never read
# .zprofile. The guard means a shell that reads both runs `brew shellenv` once.
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
