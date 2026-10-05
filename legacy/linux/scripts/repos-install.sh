#!/bin/bash
#
# --- Linux/WSL Setup Scripts ---
# Clone or update the commonly used repositories into $CODE_DIRECTORY (~/code)
#
# What:     Clones (or fast-forwards) Sean's everyday repos into ~/code, using
#           SSH if a key works, else the GitHub CLI's token, else anonymous HTTPS.
# Run:      by setup.sh (the "repos" step), or on its own at any time.
# Platform: Linux / WSL / macOS.
# Needs:    git; optionally ssh and gh; utils.sh (clone_or_update_git_repo, ...).
# Fate:     review. The repo list may move to local, untracked data before the
#           repo goes public (docs/security.md).

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

e_header "Starting repository setup (repos-install.sh)"

# owner/name pairs; cloned to $CODE_DIRECTORY/<name>
repos=(
  seanbuckley/dotfiles
  seanbuckley/ai
  seanbuckley/notes
  drfld/infra
  buckley-ca/buckley.ca
)

# A fresh machine has no key registered with GitHub, so SSH cannot be the
# default. Pick whatever actually works here, and say which was chosen.
# DOTFILES_GIT_PROTOCOL=ssh|https overrides the detection.
resolve_git_protocol() {
  if [ -n "${DOTFILES_GIT_PROTOCOL:-}" ]; then
    printf "%s" "$DOTFILES_GIT_PROTOCOL"
    return 0
  fi
  if github_ssh_works; then
    printf "ssh"
    return 0
  fi
  # gh's token covers private repos over HTTPS once `gh auth setup-git` has run.
  if github_cli_authenticated; then
    printf "gh"
    return 0
  fi
  # Anonymous HTTPS still clones the public repos; private ones fail by name.
  printf "anon"
}

git_url() {
  case "$protocol" in
    ssh) printf "git@github.com:%s.git" "$1" ;;
    *) printf "https://github.com/%s.git" "$1" ;;
  esac
}

e_header "Checking GitHub access"
protocol="$(resolve_git_protocol)"

case "$protocol" in
  ssh)
    # Detection pins the host key on the way through; a forced
    # DOTFILES_GIT_PROTOCOL=ssh skips detection, so pin here as well. Refuse
    # rather than let ssh fall back to trusting an unknown key.
    if ! ensure_github_host_keys; then
      e_error "No verified GitHub host key available; not cloning over SSH."
      exit 1
    fi
    e_success "Cloning over SSH."
    ;;
  gh)
    e_success "GitHub CLI is authenticated; cloning over HTTPS with its token."
    # Teaches git to use gh's credentials. Harmless to repeat.
    gh auth setup-git || e_warning "gh auth setup-git failed; private repos may not clone."
    ;;
  https)
    e_warning "DOTFILES_GIT_PROTOCOL=https: private repos need credentials already configured."
    ;;
  anon)
    e_warning "Not authenticated with GitHub."
    printf "  Public repos will still clone. To get the private ones:\n"
    printf "    gh auth login && gh auth setup-git\n"
    printf "  then re-run: bash scripts/repos-install.sh\n"
    # Offer it now if gh is here and someone is watching. Not under
    # DOTFILES_ASSUME_YES: that would start a browser login on an unattended run.
    if command -v gh > /dev/null 2>&1 && [ -t 0 ] &&
      [ "${DOTFILES_ASSUME_YES:-0}" != 1 ]; then
      seek_confirmation "Run 'gh auth login' now?"
      if is_confirmed; then
        if gh auth login && gh auth setup-git; then
          protocol="gh"
          e_success "Authenticated; cloning over HTTPS with the GitHub CLI token."
        else
          e_warning "Login did not complete; continuing anonymously."
        fi
      fi
    fi
    ;;
  *)
    e_error "Unknown DOTFILES_GIT_PROTOCOL: ${protocol}"
    exit 1
    ;;
esac

mkdir -p "$CODE_DIRECTORY"

# A repo that cannot be reached is reported and the rest still run, so one
# private repo does not abort the whole step.
failed=()
for repo in "${repos[@]}"; do
  # ${repo##*/} strips the owner: seanbuckley/notes -> ~/code/notes.
  clone_or_update_git_repo "$(git_url "$repo")" "${CODE_DIRECTORY}/${repo##*/}" ||
    failed+=("$repo")
done

# The loop finishes every repo first, then the step still fails, so setup.sh does
# not report success over repos that are missing.
if [ ${#failed[@]} -gt 0 ]; then
  e_error "Could not clone: ${failed[*]}"
  printf "  Usually authentication. See the gh auth login note above.\n" >&2
  exit 1
fi

e_success "Completed repos-install.sh"
