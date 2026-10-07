#!/bin/bash
#
# Shared helpers for the install scripts.
# Sourced, never executed directly.
#
# What:     Shared helpers: coloured log lines, yes/no prompts, one-time sudo,
#           symlinking dotfiles, apt installs, vite-plus PATH, safe remote
#           installers, GitHub SSH host-key pinning and clone-or-update.
# Used by:  every other script in this folder (`source .../utils.sh`).
# Platform: bash on Linux / WSL; installPackage is apt-only.
# Fate:     not carried over as a shared library. The new repo keeps each
#           script self-contained (docs/architecture.md, design rule 2); the
#           good ideas here (sudo keep-alive, safe installer) are reused inline.

# --- Global variables ---

# Repo root, resolved from this file's location so scripts work from any cwd.
DOTFILES_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIRECTORY

# Main working directory for git checkouts.
CODE_DIRECTORY="${CODE_DIRECTORY:-${HOME}/code}"
export CODE_DIRECTORY

# --- Output ---
# tput fails without a terminal (CI, piped output), so colours degrade to plain.
if [ -t 2 ] && command -v tput > /dev/null 2>&1 && tput setaf 1 > /dev/null 2>&1; then
  C_YELLOW="$(tput setaf 3)"
  C_GREEN="$(tput setaf 2)"
  C_RED="$(tput setaf 1)"
  C_ORANGE="$(tput setaf 136)"
  C_RESET="$(tput sgr0)"
else
  C_YELLOW=""; C_GREEN=""; C_RED=""; C_ORANGE=""; C_RESET=""
fi

# Each takes a single message. Colours come from the block above, so these stay
# readable when output is piped to a file.
# All four write to stderr. Functions such as resolve_git_protocol return their
# result on stdout, and a log line landing there would be captured as the value.
e_header()  { printf "\n%s%s%s\n" "$C_YELLOW" "$1" "$C_RESET" >&2; }
e_success() { printf "\n%s✓ %s%s\n" "$C_GREEN" "$1" "$C_RESET" >&2; }
e_error()   { printf "\n%sx %s%s\n" "$C_RED" "$1" "$C_RESET" >&2; }
e_warning() { printf "\n%s! %s%s\n" "$C_ORANGE" "$1" "$C_RESET" >&2; }

# --- Prompts ---

# Ask for confirmation. Answers default to "no" on a bare Enter.
# Set DOTFILES_ASSUME_YES=1 to accept every prompt without asking.
seek_confirmation() {
  printf "\n"
  e_warning "$1"
  if [ "${DOTFILES_ASSUME_YES:-0}" = "1" ]; then
    REPLY="y"
    printf "Continue? (y/N) y (DOTFILES_ASSUME_YES)\n"
    return 0
  fi
  # read returns non-zero on EOF (piped or redirected stdin); under set -e that
  # would abort the run instead of taking the safe "no".
  read -r -p "Continue? (y/N) " REPLY || REPLY=""
  printf "\n"
}

# Test whether the result of a 'seek_confirmation' is a confirmation
is_confirmed() {
  [[ "$REPLY" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# Ask, and echo yes/no for a caller to capture:
#   do_thing="$(confirm_step "This step will …")"
confirm_step() {
  seek_confirmation "$1" >&2
  if is_confirmed; then printf "yes"; else printf "no"; fi
}

# Print a question and read the answer into REPLY
ask() {
  e_header "$1"
  read -r || REPLY=""
}

# --- sudo ---

# Prompt for sudo once, then refresh the timestamp in the background until this
# script exits. Child scripts inherit the live timestamp, so they skip the loop.
keep_sudo_alive() {
  if [ "${DOTFILES_SUDO_ALIVE:-0}" = "1" ]; then
    return 0
  fi

  if ! sudo -v; then
    e_error "sudo authentication failed. Re-run once you can elevate."
    exit 1
  fi
  export DOTFILES_SUDO_ALIVE=1

  # Refresh every 50s — well inside sudo's default timeout (15 minutes; 5 on
  # some systems) — and stop as soon as the parent script is gone, so no loop
  # outlives the run.
  while true; do
    sudo -n true
    sleep 50
    kill -0 "$$" 2> /dev/null || exit
  done 2> /dev/null &
}

# --- Files ---

# Symlink a dotfile into $HOME, backing up anything already there.
copyDotfile() {
  local name="$1"
  local dest="${HOME}/${name}"
  local sourceFile="${DOTFILES_DIRECTORY}/${name}"
  local dateStr

  if [ ! -e "$sourceFile" ]; then
    e_error "Missing dotfile in repo, skipped: ${name}"
    return 1
  fi

  if [ -L "$dest" ]; then
    # Already pointing at this repo: nothing to do. Re-linking every run would
    # churn backups for no reason.
    if [ "$(readlink "$dest")" = "$sourceFile" ]; then
      printf "Already linked: %s\n" "$name"
      return 0
    fi
  elif [ -e "$dest" ]; then
    # Seconds, not minutes, so two runs a moment apart don't collide. Purge the
    # backups later with the cleandot alias.
    dateStr="$(date +%Y-%m-%d-%H%M%S)"
    if [ -e "${dest}.${dateStr}" ] || [ -L "${dest}.${dateStr}" ]; then
      e_error "Backup already exists: ${dest}.${dateStr}"
      return 1
    fi
    e_warning "Backing up existing ${dest} as ${dest}.${dateStr}"
    mv "$dest" "${dest}.${dateStr}"
  fi

  printf "Linking dotfile: %s -> %s\n" "$name" "$dest"
  ln -sfn "$sourceFile" "$dest"
}

# Fetch https://github.com/GitAlias/gitalias. The same path is included from
# .gitconfig, so the two must agree.
installGitAlias() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/gitalias"
  mkdir -p "$dir"

  # -s, not -f: an empty file from an earlier failed run should be replaced.
  if [ ! -s "$dir/gitalias.txt" ]; then
    # Download beside the target and move it into place, so an interrupted
    # transfer never leaves a partial file that a later run would accept.
    if ! curl -fsSL https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt \
      -o "$dir/gitalias.txt.tmp"; then
      rm -f "$dir/gitalias.txt.tmp"
      e_error "Failed to download gitalias.txt"
      return 1
    fi
    mv -f "$dir/gitalias.txt.tmp" "$dir/gitalias.txt"
  fi
}

# Link a Debian-renamed binary (batcat, fdfind) to its usual name in ~/.local/bin
ensure_bin_symlink() {
  local actual="$1" wanted="$2" target
  target="$(command -v "$actual" 2> /dev/null)" || return 0
  [ -n "$target" ] || return 0

  local link="$HOME/.local/bin/${wanted}"
  mkdir -p "$HOME/.local/bin"
  # -e follows the link, so it is false for a dangling one; test -L as well.
  # A working file or link is left alone — it may be the user's own. A dangling
  # link is broken either way, so replace it.
  if [ -e "$link" ]; then
    return 0
  fi
  ln -sfn "$target" "$link"
  printf "Linked %s -> ~/.local/bin/%s\n" "$target" "$wanted"
}

# --- Packages ---

# Install one or more apt packages, skipping any already present.
installPackage() {
  local pkg
  for pkg in "$@"; do
    # Ask for the status itself: `dpkg -s` also succeeds for a package that was
    # removed but not purged, whose config files remain but whose binaries don't.
    if [ "$(dpkg-query -W -f='${db:Status-Status}' "$pkg" 2> /dev/null)" = installed ]; then
      e_warning "Already installed: ${pkg}"
    else
      e_header "Installing: ${pkg}"
      sudo apt-get install -y "$pkg" || { e_error "Failed to install: ${pkg}"; return 1; }
    fi
  done
}

# --- vite-plus ---

# Put vite-plus's node/npm shims on PATH for this process. Each install script
# runs as its own process, so one script sourcing the env does not help the next.
# Paths are vite-plus's split layout (v1.0 fresh install): env file in
# ~/.config/vite-plus, shims in ~/.local/share/vite-plus/bin. The older
# single-root ~/.vite-plus layout is not supported; move an install off it
# with `vp implode` and a reinstall, per vite-plus's upgrade guide.
load_vite_plus() {
  local env_file="${XDG_CONFIG_HOME:-$HOME/.config}/vite-plus/env"
  if [ -s "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
  fi
  # A fallback for when the env file is missing.
  if [ -d "$HOME/.local/share/vite-plus/bin" ]; then
    PATH="$HOME/.local/share/vite-plus/bin:$PATH"
  fi
}

# --- Remote installers ---

# Download an install script, check it arrived, then run it. `sh -c "$(curl …)"`
# reports success when the download fails, because an empty script exits 0.
# Usage: run_remote_installer <url> <interpreter> [VAR=value ...]
run_remote_installer() {
  local url="$1" interpreter="$2" tmp rc
  shift 2  # leaves any VAR=value pairs in "$@" for env below

  tmp="$(mktemp)" || return 1

  if ! curl -fsSL "$url" -o "$tmp"; then
    e_error "Failed to download installer: ${url}"
    rm -f "$tmp"
    return 1
  fi

  if [ ! -s "$tmp" ]; then
    e_error "Downloaded installer is empty: ${url}"
    rm -f "$tmp"
    return 1
  fi

  # env, rather than a VAR=value prefix, so the caller's settings reach the
  # installer whatever the interpreter is.
  env "$@" "$interpreter" "$tmp"
  rc=$?
  rm -f "$tmp"  # captured first: rm would otherwise overwrite $?

  if [ "$rc" -ne 0 ]; then
    e_error "Installer failed (exit ${rc}): ${url}"
    return "$rc"
  fi
}

# --- GitHub authentication ---

# GitHub publishes its current SSH host keys here. Overridable for testing.
GITHUB_META_URL="${GITHUB_META_URL:-https://api.github.com/meta}"

# ssh-keygen understands hashed known_hosts entries, which Debian writes by
# default, so prefer it. Fall back to grep where openssh-client is not installed
# yet, which only misses hashed entries — and those are then simply re-pinned.
_known_hosts_has_github() {
  local kh="$1"
  [ -f "$kh" ] || return 1
  if command -v ssh-keygen > /dev/null 2>&1; then
    ssh-keygen -F github.com -f "$kh" > /dev/null 2>&1
  else
    grep -q '^github\.com ' "$kh"
  fi
}

_known_hosts_drop_github() {
  local kh="$1" tmp
  [ -f "$kh" ] || return 0
  if command -v ssh-keygen > /dev/null 2>&1; then
    ssh-keygen -R github.com -f "$kh" > /dev/null 2>&1 || true
    rm -f "${kh}.old"  # ssh-keygen -R leaves a copy of the old file
    return 0
  fi
  tmp="$(mktemp)"
  grep -v '^github\.com ' "$kh" > "$tmp" || true
  cat "$tmp" > "$kh"  # truncate in place, keeping the file's mode
  rm -f "$tmp"
}

# Pin GitHub's SSH host keys in ~/.ssh/known_hosts, taking them from the list
# GitHub publishes over HTTPS. That anchors trust in the CA chain instead of
# accepting whatever key answers on the first connection.
# Returns non-zero when no verified key is available, so the caller can decline
# to use SSH rather than fall back to trusting an unknown key.
ensure_github_host_keys() {
  local known_hosts="${HOME}/.ssh/known_hosts" fetched

  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  # Key types GitHub currently offers: ssh-ed25519, ecdsa-sha2-nistp256, ssh-rsa.
  fetched="$(curl -fsSL --max-time 15 "$GITHUB_META_URL" 2> /dev/null |
    grep -oE '(ssh-(ed25519|rsa)|ecdsa-sha2-nistp[0-9]+) [A-Za-z0-9+/]+=*' || true)"

  if [ -z "$fetched" ]; then
    # Offline, or the endpoint moved. An entry pinned by an earlier run is still
    # a verified key, so keep using it.
    if _known_hosts_has_github "$known_hosts"; then
      e_warning "Could not reach ${GITHUB_META_URL}; using the host key pinned earlier."
      return 0
    fi
    e_warning "Could not fetch GitHub's published host keys, and none is pinned yet."
    return 1
  fi

  # Replace rather than append: GitHub rotates these (the RSA key changed in
  # 2023), and a stale entry would fail verification for good.
  touch "$known_hosts"
  chmod 600 "$known_hosts"
  _known_hosts_drop_github "$known_hosts"

  while IFS= read -r key; do
    [ -n "$key" ] && printf 'github.com %s\n' "$key" >> "$known_hosts"
  done <<< "$fetched"
}

# True when this machine's SSH key is registered with GitHub.
github_ssh_works() {
  local out
  command -v ssh > /dev/null 2>&1 || return 1

  # No StrictHostKeyChecking=accept-new here: that would trust whatever key
  # answers. Pin the published key first, then require it to match.
  ensure_github_host_keys || return 1

  # `ssh -T git@github.com` always exits 1 (GitHub grants no shell), so the
  # greeting is the only signal. BatchMode stops it prompting for a passphrase
  # or a host key on an unattended run.
  out="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=10 -T git@github.com 2>&1 || true)"

  case "$out" in
    *"successfully authenticated"*) return 0 ;;
  esac

  # Say why SSH was passed over. This runs inside "$(resolve_git_protocol)",
  # so it must go to stderr: e_warning does, and stdout is the return value.
  local reason="${out##*$'\n'}"  # ssh's last line carries the cause
  e_warning "SSH not used: ${reason:-ssh gave no output}"
  return 1
}

# True when the GitHub CLI holds a usable token.
github_cli_authenticated() {
  command -v gh > /dev/null 2>&1 || return 1
  gh auth status > /dev/null 2>&1
}

# --- Git repositories ---

# Clone a repo, or fast-forward it if it is already present and clean.
clone_or_update_git_repo() {
  local repo_url="$1" dest_path="$2" name
  name="$(basename "$dest_path")"

  if [ -d "$dest_path/.git" ]; then
    e_header "Updating ${name}"
    # Never touch a checkout with work in it — this runs unattended.
    if [ -n "$(git -C "$dest_path" status --porcelain)" ]; then
      e_warning "Skipped ${name}: uncommitted local changes."
      return 0
    fi
    # --ff-only: a diverged branch is the user's to resolve, not this script's.
    git -C "$dest_path" pull --ff-only ||
      e_warning "Skipped ${name}: pull could not fast-forward."
  elif [ -e "$dest_path" ]; then
    e_warning "Skipped ${name}: ${dest_path} exists but is not a git repo."
  else
    e_header "Cloning ${name}"
    mkdir -p "$(dirname "$dest_path")"
    # GIT_TERMINAL_PROMPT=0: without credentials, git would otherwise sit at a
    # username prompt forever instead of failing.
    GIT_TERMINAL_PROMPT=0 git clone "$repo_url" "$dest_path" ||
      { e_error "Failed to clone ${name}"; return 1; }
  fi
}

# Back-compat name used by oh-my-zsh-install.sh
install_or_update_git_repo() { clone_or_update_git_repo "$@"; }
