# Architecture

This is how the finished repo is laid out and why. It is the target for Phases 1–7.
Built pieces will be marked ✅ as they land.

## Design rules

1. **Plain files first.** A dotfile is stored as a normal file. It becomes a chezmoi template (`.tmpl`) only when it really differs between machines.
2. **Few scripts, each self-contained.**
   - Each script does one job, has a header saying what it does, and can be read top to bottom.
   - There is no shared helper library that scripts depend on. Small duplication is fine.
   - Scripts only touch the user's own config and the packages they install. They never edit system files beyond what a package manager does.
3. **Idempotent.** Running `chezmoi apply` or `upgrade` twice is safe. The second run changes nothing.
4. **Explicit over clever.** No hostname checks. Machine differences come from named variables (below), not `if hostname == ...`.
5. **Escape hatches everywhere.** Every shell and tool reads a local override file that the repo never touches (see [Local overrides](#local-overrides)). A broken repo must never leave a machine unusable.
6. **No secrets, no host-specific values** in tracked files. See [security.md](security.md).

## Separation of concerns

| Concern | Where it lives | Runs when |
|---|---|---|
| **Config** (dotfiles) | `home/` files: `dot_zshrc`, `dot_gitconfig.tmpl`, `dot_config/...` | `chezmoi apply` |
| **Packages** | One list, `home/.chezmoidata/packages.yaml`. One installer per OS family (`run_onchange_` scripts) | When the list changes |
| **Bootstrap** | The chezmoi one-liner plus the `run_onchange_` installers. See [bootstrap.md](bootstrap.md) | Once, on a new machine |
| **Upgrades** | `upgrade` command, one script per OS family ([upgrades.md](upgrades.md)) | When Sean runs `upgrade` |
| **Secrets** | Not in the repo. Machine-only files, or entered at `chezmoi init` | — |
| **Machine overrides** | `~/.config/chezmoi/chezmoi.toml` (answers to init questions) and `*.local` files | Always read if present |

## Target layout

```text
dotfiles/
├── README.md                  # what this is, one-line install per OS
├── AGENTS.md / CLAUDE.md      # agent guidance (CLAUDE.md just imports AGENTS.md)
├── LICENSE                    # MIT
├── .chezmoiroot               # contains "home": chezmoi reads only home/
├── .editorconfig  .gitattributes  .gitignore
├── .github/workflows/         # CI: lint, secret scan, apply tests
├── docs/                      # these docs
├── legacy/                    # frozen snapshot of the old repos (deleted at v1.0.0)
└── home/                      # everything chezmoi deploys into ~
    ├── .chezmoi.toml.tmpl     # init questions → variables (see below)
    ├── .chezmoiignore         # skip files per OS/profile (e.g. no PowerShell on Linux)
    ├── .chezmoiexternal.toml  # things fetched, not copied: zsh plugins, gitalias
    ├── .chezmoidata/
    │   └── packages.yaml      # the tool list, tiered, with a package name per manager
    ├── .chezmoiscripts/       # run_onchange_ install/setup scripts (not deployed as files)
    ├── dot_zshrc.tmpl         # zsh (workstations)
    ├── dot_bashrc             # bash (minimal profile / Alpine / fallback)
    ├── dot_config/
    │   ├── shell/aliases.sh   # aliases shared by zsh and bash
    │   ├── git/config.tmpl    # the one .gitconfig (or dot_gitconfig.tmpl, decided in P2.02)
    │   ├── git/ignore         # small global ignore: OS/editor junk only
    │   ├── starship.toml      # one prompt config for every shell
    │   ├── powershell/        # profile + Scripts (Windows); loaded by thin $PROFILE loaders
    │   └── omarchy/hooks/post-update   # Omarchy only: re-run chezmoi apply after updates
    └── dot_local/bin/
        └── executable_upgrade # Linux/WSL/macOS upgrade command
```

The exact file names are confirmed when each phase is detailed. The shape stays the same.

## How chezmoi works (60-second version)

- The repo is the **source**. Your home directory is the **target**.
- File names encode what to do:
  - `dot_zshrc` → `~/.zshrc`
  - `executable_upgrade` → `upgrade` with `+x` set
  - `*.tmpl` → a template filled in per machine
- `chezmoi diff` shows what would change. `chezmoi apply` does it.
- `chezmoi update` = `git pull` in the source, then `apply`.
- `chezmoi edit ~/.zshrc` opens the *source* file. Always edit the source, not the target.
- `run_onchange_` scripts re-run only when their content changes. The package installer includes a hash of `packages.yaml`, so editing the list re-runs it.
- On Windows chezmoi copies files; no symlinks or admin rights are needed.

## Variables

Asked once at `chezmoi init`, stored in `~/.config/chezmoi/chezmoi.toml`. Every
question has a default and an environment-variable override, so init can run unattended
([bootstrap.md](bootstrap.md#unattended)).

| Variable | Values | Default | Env override | Used for |
|---|---|---|---|---|
| `profile` | `workstation`, `minimal` | `workstation` | `DOTFILES_PROFILE` | `minimal` = shell, aliases, git and required tools only; no GUI, fonts or prompts |
| `name` | text | `Sean Buckley` | `DOTFILES_NAME` | git identity |
| `email` | text | GitHub noreply | `DOTFILES_EMAIL` | git identity |
| `codeDir` | path | `~/code` | `DOTFILES_CODE_DIR` | dev folder |

Derived automatically (never asked):

| Variable | How | Used for |
|---|---|---|
| `.chezmoi.os` | built in | `linux`, `windows`, `darwin` |
| `osID` | `.chezmoi.osRelease.id` (e.g. `arch`, `ubuntu`, `fedora`, `alpine`) | picks the package manager |
| `isWSL` | kernel release contains `microsoft` | WSL-only aliases (`open`, clipboard) |
| `isOmarchy` | `~/.local/share/omarchy` exists | Omarchy hook; `upgrade` calls `omarchy-update` |

## Local overrides

The repo never creates these files; they're yours per machine.

| File | Read by |
|---|---|
| `~/.zshrc.local`, `~/.bashrc.local` | end of zshrc / bashrc |
| `~/.gitconfig_local` | `[include]` in gitconfig (work identity, signing key) |
| `Microsoft.PowerShell_profile.local.ps1` (next to the managed profile) | end of the PowerShell profile |
| `~/.config/dotfiles/upgrade.conf` / `DotfilesUpgradeSettings` | `upgrade` skip lists, blocked packages |

## Windows specifics

- The PowerShell profile lives at `~/.config/powershell/` (a stable path), not in `Documents`.
  - A `run_onchange_` script writes a one-line loader into the real `$PROFILE` for both PowerShell 7 and 5.1. It finds that path at runtime with `[Environment]::GetFolderPath('MyDocuments')`, which handles OneDrive and network-redirected Documents.
  - This keeps the design already proven in `Install-Dotfiles.ps1`.
- Windows Terminal's `settings.json` is owned by the Terminal app. We don't manage the file; a `run_onchange_` script runs the existing merge script against it.

## Omarchy specifics

- Omarchy keeps its defaults under `~/.local/share/omarchy`, and treats `~/.config` as the user's.
- On Omarchy we manage only shell, git and CLI-tool files, plus the `post-update` hook. Hyprland, Waybar and the rest stay Omarchy's in v1.
- Omarchy's own `~/.bashrc` is left alone; Sean's shell is zsh.

## Agent files

`AGENTS.md` (with `CLAUDE.md` containing only `@AGENTS.md`) is short and covers:

- the repo architecture, with a link here;
- supported platforms, with a link to [platforms.md](platforms.md);
- the validation commands (the lint workflow locally, `chezmoi diff`, `chezmoi apply --dry-run`);
- things not to change casually: `.chezmoiroot`, variable names, the `$PROFILE` loader, `packages.yaml` tiers, CI gates;
- secret rules (none in the repo; report any found);
- commits and releases ([decisions.md](decisions.md#commit-convention));
- "park new ideas as issues";
- the shared **Core** section, word for word from Sean's other (private) repos, without naming them.
