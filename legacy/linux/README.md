# dotfiles

Personal dot files and shell installation scripts.

> [!NOTE]
> This repo and `dotfiles-windows` are being merged into one chezmoi-managed repo.
> See [docs/migration-plan.md](docs/migration-plan.md) for the plan and
> [docs/status.md](docs/status.md) for current progress.

See [CONTENTS.md](CONTENTS.md) for a file-by-file guide to this repo.

## Installation

1. Clone this [repository](https://github.com/seanbuckley/dotfiles) into your
   working directory:

   ```bash
   mkdir -p ~/code && git clone git@github.com:seanbuckley/dotfiles.git ~/code/dotfiles
   ```

   No SSH key on this machine yet? Clone over HTTPS
   (`https://github.com/seanbuckley/dotfiles.git`) and let `setup.sh` generate
   the key.

## Usage

1. `cd ~/code/dotfiles/scripts`
2. `bash setup.sh`

   Setup choices and the SSH key email are asked up front. `sudo` is
   requested once. `chsh` may ask for the account password, and `ssh-keygen`
   may ask for a passphrase during installation.

   Progress messages go to stderr, so capture a log with
   `bash setup.sh 2>&1 | tee setup.log`.

3. Reload the terminal with `exec zsh -l`.
4. Install Tailscale.
5. Set up the [GitHub CLI](https://cli.github.com/):
   1. `gh auth login`
   2. `gh config set editor nvim`

### Options

| Variable | Effect |
| --- | --- |
| `DOTFILES_ASSUME_YES=1` | Accept every prompt without asking. Never starts a GitHub login. |
| `DOTFILES_EMAIL` | Comment for a generated SSH key; skips that prompt. |
| `CODE_DIRECTORY` | Working directory for git checkouts (default `~/code`). |
| `DOTFILES_GIT_PROTOCOL=ssh\|https` | Force a clone protocol instead of detecting one. |
| `GITHUB_META_URL` | Override where GitHub's published host keys are fetched from. |

## Scripts

| Script | Purpose |
| --- | --- |
| `setup.sh` | Main entry point; prompts, then runs the rest. |
| `apt-install.sh` | System packages, GitHub CLI, WSL utilities. |
| `homebrew-install.sh` | Homebrew for Linux. |
| `homebrew-packages.sh` | Packages with no apt equivalent. |
| `dotfile-install.sh` | Symlinks dot files into `$HOME`. |
| `node-install.sh` | Node.js via vite-plus. |
| `npm-install.sh` | Global npm packages. |
| `oh-my-zsh-install.sh` | Oh My Zsh, plugins, Powerlevel10k, default shell. |
| `repos-install.sh` | Clones or updates the common repos into `~/code`. |
| `utils.sh` | Shared helpers (sourced, not run). |

## Repositories

`repos-install.sh` clones or fast-forwards these into `$CODE_DIRECTORY`. A repo
with uncommitted changes, or one that cannot fast-forward, is skipped with a
warning rather than modified.

It picks the protocol that works on this machine: an SSH key GitHub recognises,
else a GitHub CLI token over HTTPS, else anonymous HTTPS. Before trying SSH it
pins GitHub's host keys in `~/.ssh/known_hosts` from the list GitHub publishes at
`https://api.github.com/meta`, so the key is verified over HTTPS rather than
trusted on first connection. If that list cannot be fetched and no key is pinned
yet, SSH is skipped rather than trusted blindly. On a new machine you
are usually in the last case — the public repos still clone, the private ones
are named at the end, and the step offers to run `gh auth login` for you. To do
it by hand:

```bash
gh auth login && gh auth setup-git
bash scripts/repos-install.sh
```

- [seanbuckley/dotfiles](https://github.com/seanbuckley/dotfiles)
