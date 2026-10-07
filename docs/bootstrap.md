# Bootstrap

How a machine gets the dotfiles. **Target design.** The commands work once Phase 3
(Linux) and Phase 4 (Windows) land. Until the repo is public (v0.1.0), cloning needs
GitHub auth (`gh auth login` first).

## New machine (workstation)

The whole flow is: install prerequisites → install chezmoi → clone and apply → install tools → OS setup → verify.
chezmoi does steps 2–5 in one command.

**Linux / WSL / macOS**

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply seanbuckley
```

**Windows** (PowerShell, as your normal user, not elevated)

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply seanbuckley"
```

Nothing needs installing first. The one-liner downloads the chezmoi program, then runs
it. chezmoi has git built in, so it can clone even on a machine without git. Only
`curl` (Linux/macOS) or PowerShell (Windows) is needed. By default the chezmoi program
lands in `./bin` under the current folder. To put it on your PATH instead, on Linux use
`sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply seanbuckley`. The package installers then install chezmoi and
git properly, so `chezmoi update` and `upgrade` work afterwards.

What happens:

1. chezmoi clones `github.com/seanbuckley/dotfiles` into its source directory (`~/.local/share/chezmoi`).
2. It asks the [init questions](architecture.md#variables): profile, name, email and code folder. Press Enter to accept the defaults.
3. It runs the `run_onchange_before_` scripts: package install for this OS and profile.
4. It writes the dotfiles.
5. It runs the `run_onchange_after_` scripts: the Windows `$PROFILE` loaders, the Terminal merge, the Omarchy hook.
6. You open a new terminal. **Verify:** run `chezmoi doctor`, then `chezmoi verify`, which prints nothing when everything matches.

## Unattended

Every init question reads an environment variable first, so nothing prompts:

```sh
DOTFILES_PROFILE=minimal \
DOTFILES_EMAIL=you@users.noreply.github.com \
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --promptDefaults seanbuckley
```

`--promptDefaults` makes chezmoi take the default for anything not set. The package installers
use non-interactive flags (`apt-get -y`, `dnf -y`, `pacman --noconfirm --needed`,
`apk add`, `winget --accept-package-agreements --accept-source-agreements`).

## Proxmox LXC / VM (`minimal` profile)

For a new container or VM (e.g. an AI agent workspace) that should just have Sean's
shell, aliases and git setup:

```sh
# as your normal user inside the guest (not root)
DOTFILES_PROFILE=minimal sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --promptDefaults seanbuckley
```

- `minimal` = shell rc, aliases, git config and the **required** tools. No GUI, fonts, prompt theme or vite-plus.
- Throwaway container and you don't want chezmoi left behind? Add `--one-shot`. chezmoi then applies and removes its own source and state.
- Alpine: install `bash curl git` with `apk` first; the profile uses bash there.
- Running it later from the homelab repo (Ansible/cloud-init) is deferred ([migration-plan.md](migration-plan.md#scope-guard)).

## Safe unattended vs needs confirmation

| Step | Unattended? | Notes |
|---|---|---|
| Write dotfiles into `~` | ✅ | chezmoi overwrites only files it manages. Run `chezmoi diff` first on an existing machine |
| Install packages from the list | ✅ | Needs sudo on Linux. Prompts once unless passwordless sudo is set up |
| Windows `$PROFILE` loaders, Terminal merge | ✅ | Backs up the file before changing it |
| `chsh` to zsh | ⚠️ confirm | Needs a password. The script prints the command instead of running it |
| SSH keys, `gh auth login` | ❌ manual | Personal and interactive. Never automated |
| Anything destructive (deleting files or folders) | ❌ never | Not part of bootstrap |

## Phase 2 dry run (P2.06)

Run this once on WSL and once on Windows. It shows what the shared core would change, and
applies it only if you choose to. Phase 2 manages four files: `~/.gitconfig`,
`~/.config/git/ignore`, `~/.config/gitalias/gitalias.txt` and, on Linux and WSL only,
`~/.config/shell/env.sh`.

**WSL**

```sh
# 1. Install chezmoi (2.73.0 or newer) to ~/.local/bin
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
chezmoi --version   # open a new shell first if it isn't found

# 2. Back up what it will replace
cp ~/.gitconfig ~/.gitconfig.pre-chezmoi
[ -f ~/.config/git/ignore ] && cp ~/.config/git/ignore ~/.config/git/ignore.pre-chezmoi

# 3. Clone into ~/.local/share/chezmoi and answer the questions (no --apply)
chezmoi init seanbuckley
```

**Windows** (PowerShell, normal user, not elevated)

```powershell
# 1. Install chezmoi (2.73.0 or newer)
winget install --id twpayne.chezmoi -e
chezmoi --version   # open a new terminal first if it isn't found

# 2. Back up what it will replace
Copy-Item ~\.gitconfig ~\.gitconfig.pre-chezmoi
if (Test-Path ~\.config\git\ignore) { Copy-Item ~\.config\git\ignore ~\.config\git\ignore.pre-chezmoi }

# 3. Clone into ~\.local\share\chezmoi and answer the questions (no --apply)
chezmoi init seanbuckley
```

Then, on both:

4. Move anything machine-specific out of the old `~/.gitconfig` before reading the diff:
   signing key, editor and other per-machine settings into `~/.gitconfig_local`; work name
   and email into `~/.gitconfig_work`. For a work identity, run `chezmoi edit-config` and add
   `workGitDirs = ["<work repos folder>"]` under `[data]`.
5. Read the diff: `chezmoi diff`. It downloads GitAlias, so it needs network.
6. Expected: only the four files above change, and the new `~/.gitconfig` matches the
   P2.02–P2.05 PRs (noreply email, `includeIf` only if you set `workGitDirs`,
   `~/.gitconfig_local` included last). `chezmoi managed` lists every path it would touch.
7. Optional: `chezmoi apply`, then `chezmoi verify` (silent when everything matches) and
   `git config --show-origin user.email` inside a personal repo and a work repo. Or skip
   applying until Phase 6.
   On Windows, don't re-run the old `Install-Dotfiles.ps1` afterwards: it adds its
   `[include]` back into `~/.gitconfig`.

Stop and tell the agent if the diff changes anything else, or if `chezmoi diff` or
`chezmoi apply` asks a question.

Undo: `chezmoi purge` removes chezmoi's clone, config and state but leaves your files.
If you applied, also restore the backups:
`mv ~/.gitconfig.pre-chezmoi ~/.gitconfig` (and the same for `ignore`).

Gate 2: when both machines look right, tick gate 2 in [status.md](status.md#gates), then tag
`main` from your own checkout:

```sh
git switch main && git pull --ff-only
git tag -a v0.2.0 -m "Shared core"
git push origin v0.2.0
```

## Cutover an existing machine

For Phase 6: moving a machine from the old repos to this one.

1. Make sure the old clone's remote points to `dotfiles-legacy` (P0e.03).
2. Back up what matters: `cp ~/.zshrc ~/.zshrc.pre-chezmoi` and so on, or rely on the old repo.
3. Run `chezmoi init seanbuckley` (**no** `--apply`).
4. Run `chezmoi diff` and read it. Everything shown will change. Anything surprising → stop and ask.
5. Run `chezmoi apply`.
6. Clean up the old wiring:
   - Linux: remove the old symlinks into `~/code/dotfiles-legacy`, if any are left, and the Oh My Zsh folder (`~/.oh-my-zsh`) after the new shell works.
   - Windows: **remove the old `$PROFILE` loaders first**, because the profile's `DotfilesWindowsProfileLoaded` guard lets the first loader win. Then delete the old checkout.
7. Open a new terminal. Run `upgrade --only dotfiles`.
8. Tick the machine off in [tasks.md](tasks.md) (Phase 6).

Rollback: `chezmoi purge`, restore the `*.pre-chezmoi` backups, and re-link from the legacy clone.

## Spike

For P0e.02: try chezmoi before committing to it. Nothing here touches the real repos.

```sh
chezmoi init                    # creates an empty local source dir
chezmoi add ~/.gitconfig        # start managing one file
chezmoi edit ~/.gitconfig       # edit the source copy
chezmoi diff                    # see what would change
chezmoi apply                   # write it
chezmoi cd                      # look around the source dir (it's a git repo)
# when done experimenting:
chezmoi purge                   # removes chezmoi's source and state; ~/.gitconfig stays
```

On Windows, the same commands work in PowerShell.
