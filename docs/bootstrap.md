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
