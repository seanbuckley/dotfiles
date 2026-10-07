#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Main install script
#
# Windows reminder: line endings must be LF, not CRLF.
#
# Referenced from: https://github.com/samuelramox/wsl-setup/blob/master/install/utils.sh
#
# What:     The entry point. Asks which steps to run (all questions up front),
#           then runs each chosen step script below as a child process.
# Run:      bash scripts/setup.sh   (from anywhere; it cd's to its own folder)
#           DOTFILES_ASSUME_YES=1 answers "yes" to every step (unattended).
# Platform: Ubuntu / WSL Ubuntu (apt-based only).
# Needs:    bash, sudo, curl, git; utils.sh next to it.
# Fate:     replaced by `chezmoi init --apply` (docs/bootstrap.md).

set -euo pipefail

# Run from this script's directory so the sibling scripts resolve from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

e_header "Starting main setup script"

e_header "System version info"
if command -v lsb_release &> /dev/null; then
  lsb_release -a 2> /dev/null
else
  uname -a
fi

# Collect every setup choice before installing anything, so the install itself
# runs unattended.
e_header "--- Choose steps ---"
do_apt="$(confirm_step "This step will install basic utilities and applications (apt).")"
do_zsh="$(confirm_step "This step will install Oh My Zsh with plugins and make zsh your default shell.")"
do_brew="$(confirm_step "This step will install Homebrew, a package manager for Linux.")"
do_brew_pkgs="$(confirm_step "This step will install remaining packages via Homebrew (eza, sd, yq, lazygit, zoxide).")"
do_dotfiles="$(confirm_step "This step will replace your existing dot files and git configuration (originals are backed up).")"
do_node="$(confirm_step "This step will install Node.js using vite-plus.")"
do_npm="$(confirm_step "This step will install global npm packages.")"
do_ssh="$(confirm_step "This step will generate an SSH key.")"
# Asked here rather than at the keygen step below, so no prompt interrupts the
# install. Skipped when a key already exists, since none will be generated.
# DOTFILES_EMAIL answers it in advance, and DOTFILES_ASSUME_YES never stops
# here: the email is only the key's comment, so git's user.email is good enough.
ssh_email="${DOTFILES_EMAIL:-}"
if [ "$do_ssh" = yes ] && [ ! -f "${HOME}/.ssh/id_ed25519" ] && [ -z "$ssh_email" ]; then
  if [ "${DOTFILES_ASSUME_YES:-0}" = 1 ]; then
    ssh_email="$(git config --global user.email 2> /dev/null || true)"
  else
    ask "Please provide an email address: "
    ssh_email="$REPLY"
  fi
fi

do_repos="$(confirm_step "This step will clone or update the common repos into ${CODE_DIRECTORY}.")"

# The answers are typed at the terminal and never reach a tee'd log, so record
# what was chosen.
e_header "Selected steps"
printf '  apt=%s zsh=%s brew=%s brew-packages=%s dotfiles=%s\n' \
  "$do_apt" "$do_zsh" "$do_brew" "$do_brew_pkgs" "$do_dotfiles" >&2
printf '  node=%s npm=%s ssh-key=%s repos=%s\n' \
  "$do_node" "$do_npm" "$do_ssh" "$do_repos" >&2

# Three prompts cannot be collected here, because each belongs to a tool this
# run has not installed or invoked yet. Say so, so none of them is a surprise.
prompts_left=()
[ "$do_zsh" = yes ] && prompts_left+=("chsh asks for your account password")
[ "$do_ssh" = yes ] && [ ! -f "${HOME}/.ssh/id_ed25519" ] &&
  prompts_left+=("ssh-keygen asks for a key passphrase")
[ "$do_repos" = yes ] && prompts_left+=("GitHub sign-in, if you are not already authenticated")
if [ ${#prompts_left[@]} -gt 0 ]; then
  e_warning "Later in the run you may still be asked:"
  printf '  - %s\n' "${prompts_left[@]}"
fi

# One sudo prompt for the whole run; child scripts inherit the timestamp.
# Only these steps use sudo.
if [ "$do_apt" = yes ] || [ "$do_brew" = yes ]; then
  keep_sudo_alive
fi

# Both directories are wanted whatever was chosen above, and both are cheap.
e_header "--- Folder setup ---"
mkdir -p "$CODE_DIRECTORY"
e_success "Working directory ready: ${CODE_DIRECTORY}"

# The oh-my-zsh ssh-agent plugin warns on every shell start without this.
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Each step runs as a child process, so a failure surfaces here via set -e
# rather than being swallowed.
e_header "--- Applications ---"
if [ "$do_apt" = yes ]; then
  bash ./apt-install.sh
else
  e_warning "Skipped installing applications."
fi

# Needs zsh, which the apt step installs.
e_header "--- Zsh / Oh My Zsh ---"
if [ "$do_zsh" = yes ]; then
  bash ./oh-my-zsh-install.sh
else
  e_warning "Skipped Oh My Zsh and the default shell change."
fi

e_header "--- Homebrew ---"
if [ "$do_brew" = yes ]; then
  bash ./homebrew-install.sh
else
  e_warning "Skipped installing Homebrew."
fi

e_header "--- Homebrew packages ---"
if [ "$do_brew_pkgs" = yes ]; then
  bash ./homebrew-packages.sh
else
  e_warning "Skipped Homebrew package installation."
fi

e_header "--- Dotfiles ---"
if [ "$do_dotfiles" = yes ]; then
  bash ./dotfile-install.sh
else
  e_warning "Skipped copying dot files."
fi

e_header "--- Node.js ---"
if [ "$do_node" = yes ]; then
  bash ./node-install.sh
else
  e_warning "Skipped Node.js installation."
fi

e_header "--- Global node packages ---"
if [ "$do_npm" = yes ]; then
  bash ./npm-install.sh
else
  e_warning "Skipped npm global package installation."
fi

e_header "--- SSH key ---"
if [ "$do_ssh" = yes ]; then
  # Never overwrite a key — doing so would lock this machine out of every host
  # and forge it is registered with.
  if [ -f "${HOME}/.ssh/id_ed25519" ]; then
    e_warning "Existing key found at ~/.ssh/id_ed25519; left untouched."
  else
    ssh-keygen -t ed25519 -C "$ssh_email" -f "${HOME}/.ssh/id_ed25519"
    e_success "Generated SSH key."
    e_warning "Use the copyssh command to copy the public key to the clipboard."
    # A brand new key is not on GitHub yet, so the repos step below will fall
    # back to the GitHub CLI rather than SSH.
    e_warning "Add it at https://github.com/settings/keys before cloning over SSH."
  fi
else
  e_warning "Skipped SSH key generation."
fi

e_header "--- Repositories ---"
if [ "$do_repos" = yes ]; then
  bash ./repos-install.sh
else
  e_warning "Skipped repository setup."
fi

e_success "Ending main setup script. Goodbye."
e_header "Reload the shell with: exec zsh -l"
