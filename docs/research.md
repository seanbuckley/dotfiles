# Research digest

Task P0c.01 of the [migration plan](migration-plan.md): a one-session review of other
people's dotfiles and write-ups, to find ideas worth copying before the new repo's
layout is built. It starts with the references Sean had already saved.

**Rules**
- Each idea gets a verdict:
  - **adopt**: use it as described;
  - **adapt**: use a simpler or modified version;
  - **reject**: don't use it, with the reason;
  - **backlog**: good, but after v1.0.0.
- *adopt* and *adapt* must fit the [scope guard](migration-plan.md#scope-guard) and name the phase they land in.
- This digest **adds no tools and changes no decisions**. Possible conflicts are listed at the end for Sean.

**Access notes (2026-09-30).** This sandbox blocks some sites. Where a page couldn't be
opened directly, the row says so and the summary comes from search-result snippets or
general knowledge of that source. Those rows are marked *(indirect)*.

## Sean's saved references

### Evan Hahn: three posts *(read in full from copies Sean saved)*

Sources: [A decade of dotfiles](https://evanhahn.com/a-decade-of-dotfiles/) (2022),
[Why "alias" is my last resort for aliases](https://evanhahn.com/why-alias-is-my-last-resort-for-aliases/) (2025),
[Scripts I wrote that I use all the time](https://evanhahn.com/scripts-i-wrote-that-i-use-all-the-time/) (2025).
The two 2025 posts are recent, and the 2022 post's advice still holds.

| Idea | Verdict | Why | Phase |
|---|---|---|---|
| **Scripts over aliases** by default: a script in a `bin` folder on `PATH` needs no shell reload, can be any language, and works in every shell | **adapt** | His own list of exceptions sets the rule we'll use (below) | 3, 4 |
| …but keep an alias or function when it must **change the current folder** (`cd..`, `mkcd`), needs the **previous exit code**, needs **tab completion** (`g=git` keeps git's completions), is **conditional** (defined only on WSL or Linux), or needs to be **easy to bypass** (`\vim`) | **adopt** | This gives a clear, teachable rule for a junior developer: *does it need to touch the shell itself? alias/function. Otherwise, a script* | 3, 4 |
| **"Every computer is different."** He dropped his one-command provisioning script because "these scripts got complicated and rarely worked exactly right". He now pulls in configs piecemeal, keeps per-machine `*_local` files, and adds fallbacks | **adapt** | A fair warning for our unattended bootstrap goal. We keep it, but guard against that failure: bootstrap stays small; profiles (`workstation`/`minimal`) replace "pick and choose"; every step is idempotent and **tested in CI on every PR** (the thing his scripts lacked); `*.local` files for machine quirks | 1–4 |
| `$EDITOR` **fallback chain** (nvim → vim → vi) | **adopt** (confirms) | Same pattern as D10 (micro → nano) | 2 |
| `mksh foo.sh`: create an executable script with a shebang, open it | **adopt** (confirms) | = our existing `newsh`; keep it, maybe renamed `mksh` | 3 |
| Cross-platform **`copy` / `pasta`** clipboard commands, plus `cpwd` (copy the current folder) | **adopt** | One name on every OS: clip.exe and powershell on WSL/Windows, wl-copy on Omarchy, xclip elsewhere. Replaces WSL-only tricks | 3, 4 |
| **`tempe`**: cd into a fresh temp folder; **`scratch`**: open `$EDITOR` on a temp file | **adopt** | Two lines each; handy sandboxes | 3 |
| **`prettypath`**: print `$PATH` one entry per line | **adopt** | Directly helps with the duplicate-PATH problem ([#103](https://github.com/seanbuckley/dotfiles-legacy/issues/103)); ~1 line | 3 |
| **`serveit`**: static web server that falls back when Python is missing | **adapt** | We already have a `server` alias; keep it as is | — |
| `hoy` (today's date as YYYY-MM-DD), `notify` (desktop notification), `running`, `murder` (polite-then-forceful kill), `each`, `tryna`, `bb`, `catbin` | **backlog** | Nice, but each is a new command to maintain; revisit after v1 | post-v1 |
| Tools he likes: `shellcheck`, `entr`, `tig` | shellcheck **adopt** (confirms, CI); others **backlog** | shellcheck is already in the CI plan | 1 |

### Example repos from the archived Homelab TODO

| Source | Idea | Verdict | Why | Phase |
|---|---|---|---|---|
| [tomnomnom/dotfiles](https://github.com/tomnomnom/dotfiles) | Tiny `setup.sh` + plain dotfiles + a `scripts/` folder | **adopt** (confirms) | Small and readable is the goal; nothing new to copy | — |
| [victoriadrake/dotfiles (ubuntu)](https://github.com/victoriadrake/dotfiles/tree/ubuntu) | Split setup into symlink / apt / programs / desktop scripts, run by one `setup.sh` | **reject** | chezmoi replaces the symlink and orchestration scripts; the split-by-concern idea is already in [architecture.md](architecture.md) | — |
| victoriadrake | Save and restore desktop settings with `dconf` | **reject** | GNOME-only; Omarchy owns the desktop in v1 | — |
| [samuelramox/wsl-setup](https://github.com/samuelramox/wsl-setup) | WSL setup split into apps / dotfiles / npm / ssh / user scripts; the old `setup.sh` was based on it | **reject** | Already absorbed, and chezmoi replaces the pattern | — |
| [matchai/dotfiles](https://github.com/matchai/dotfiles) | Nix flakes + nix-darwin for a fully declarative machine | **reject** | Far too complex for the "junior developer" goal; macOS-first; no Windows | — |
| [LukeSmithxyz/voidrice](https://github.com/LukeSmithxyz/voidrice) (lukesmith's dotfiles) | XDG layout: configs in `~/.config`, env vars in `~/.zprofile` to keep `~` clean | **adopt** | Already the target layout (`dot_config/...`); worth stating as a rule | 2–3 |
| voidrice | Personal scripts in `~/.local/bin` | **adopt** | Same as the Evan Hahn row | 3 |
| voidrice | Bookmark files (`bm-dirs`, `bm-files`) that generate shortcuts | **reject** | zoxide covers directory jumping | — |
| [jayharris/dotfiles-windows](https://github.com/jayharris/dotfiles-windows) (also [windows#3](https://github.com/seanbuckley/dotfiles-windows/issues/3)) | Split profile: `components`, `functions`, `aliases`, `exports` | **reject** | The current profile already splits by concern, and is faster (deferred and lazy loading) | — |
| jayharris | `extra.ps1`: an untracked file for private settings | **adopt** (confirms) | Same as our `*.local` override files ([architecture.md](architecture.md#local-overrides)) | 4 |
| jayharris | `windows.ps1`: sets Windows defaults (show hidden files, file extensions, privacy toggles) | **backlog** | Useful for new PCs, but it changes system settings and needs care (some keys need admin, some differ on Windows 10 and 11) | post-v1 |
| jayharris | `deps.ps1`: installs winget/npm packages | **adopt** (confirms) | Our `packages.yaml` + winget installer does this | 4 |
| jayharris | Install without git, by running a downloaded script | **adopt** (confirms) | The chezmoi one-liner does this once the repo is public | 1, 4 |
| [StefanScherer/dotfiles-windows](https://github.com/StefanScherer/dotfiles-windows) | Unix-style navigation aliases (`..`, `...`, `home`) in PowerShell | **adopt** (confirms) | Already in `Aliases.ps1`; keep the names identical on Linux | 4 |

### Links in [dotfiles-legacy#26](https://github.com/seanbuckley/dotfiles-legacy/issues/26) (General dot file ideas)

| Source | Idea | Verdict | Why | Phase |
|---|---|---|---|---|
| [paulirish/dotfiles](https://github.com/paulirish/dotfiles) | An untracked `.extra` file sourced by the shell for private settings | **adopt** (confirms) | = `~/.zshrc.local` | 3 |
| paulirish | `setup-a-new-machine.sh`: a readable checklist script for a new machine | **adapt** | Our [bootstrap.md](bootstrap.md) is the checklist; chezmoi runs the steps | 3 |
| paulirish | fish as the main shell | **reject** | D7: zsh on workstations | — |
| [mislav/dotfiles](https://github.com/mislav/dotfiles) | Bootstrap links only *missing* files and never overwrites existing ones | **adapt** | chezmoi shows a diff before overwriting. The [cutover checklist](bootstrap.md#cutover-an-existing-machine) already says to read `chezmoi diff` first | 6 |
| mislav | A large `bin/` of personal utilities | **adopt** (confirms) | Same as the Evan Hahn row | 3 |
| [grml zsh config](https://grml.org/zsh/) *(read in full from a copy Sean saved)* | `~/.zshrc.pre` (read before) and `~/.zshrc.local` (read after) for personal overrides | **adopt** | We only need the `.local` file; one hook is simpler | 3 |
| grml | A starter list of sensible options: `append_history`, `share_history`, `extended_history`, `hist_ignore_space`, `auto_cd`, `auto_pushd`, `pushd_ignore_dups`, `interactive_comments`, `complete_in_word`, `no_beep`; `HISTSIZE=5000`, `SAVEHIST=10000` | **adopt** | Exactly the "~40 commented lines" that replace Oh My Zsh's `lib/`. Copy the options, not the 4,000-line file | 3 (P3.02) |
| grml | Built-in profiling switch: `ZSH_PROFILE_RC=1 zsh` loads `zprof` so you can see what's slow | **adopt** | Two lines; matches the PowerShell profile's startup timing (DECISIONS.md 15) | 3 |
| grml | Use the whole grml config (Arch even packages it as `grml-zsh-config`) | **reject** | Very capable, but far too big to read or teach; Arch-only package | — |
| HN "managing dotfiles" thread (bare git repo) *(indirect: HN is blocked here)* | `git --bare` repo with `$HOME` as the work tree | **reject** | Covered by D1 ([#27](https://github.com/seanbuckley/dotfiles-legacy/issues/27)): no templates, no Windows story, easy to `git add` secrets by mistake | — |
| Code Review SE "simple Linux upgrade script" *(indirect: site not reachable)* | The usual review points: use `apt-get` in scripts, check each step's exit code instead of one `&&` chain, run with `-y`, log output | **adopt** (confirms) | Exactly the design in [upgrades.md](upgrades.md) | 3 (P3.06) |
| Generic bash tutorials (linuxhint "30 bash script examples", addictivetips, tecmint maintenance scripts) | General scripting examples | **reject** | Nothing specific beyond what shellcheck and our comment standard already require | — |

### [dotfiles-legacy#28](https://github.com/seanbuckley/dotfiles-legacy/issues/28): zsh plugins ([awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins))

| Idea | Verdict | Why | Phase |
|---|---|---|---|
| Use plugins without a framework: source each plugin file directly ("zsh-unplugged": about 20 lines) | **adapt** | We get the same result with **no** plugin manager: chezmoi's `.chezmoiexternal` downloads the three plugins, and `.zshrc` sources them. Nothing extra to learn | 3 (P3.02) |
| Minimal plugin managers (zap, zpico, miniplug) | **reject** | One more tool to update and explain; chezmoi already fetches files | — |
| Keep only zsh-autosuggestions, zsh-syntax-highlighting (loaded last) and zsh-history-substring-search | **adopt** | Matches [decisions.md](decisions.md#oh-my-zsh) | 3 |

### Vault note *Dotfile* (other managers)

| Tool | Verdict | Why |
|---|---|---|
| [Dotbot](https://github.com/anishathalye/dotbot) | **reject** | YAML + git submodule + Python. Built on symlinks, which on Windows need admin or Developer Mode. No templates |
| [Dotter](https://github.com/SuperCuber/dotter) | **reject** | Close second: `global.toml`/`local.toml` machine selection, templates, runs on Windows. But it has no built-in run-on-change scripts, externals or secret support, and a smaller community than chezmoi. D1 stands |

## chezmoi and Omarchy examples

| Source | Idea | Verdict | Why | Phase |
|---|---|---|---|---|
| [twpayne/dotfiles](https://github.com/twpayne/dotfiles) (chezmoi's author) | `.chezmoiroot` → `home/`, which keeps the repo root for README, docs and CI | **adopt** (confirms) | Already the target layout | 2 |
| twpayne | `.chezmoiversion` sets a minimum chezmoi version | **adopt** | One line, and it gives old installs a clear error | 2 (P2.01) |
| twpayne | A root `install.sh` that installs chezmoi and runs `init --apply` | **adapt** | The official one-liner does the same. Add a tiny `install.sh`/`install.ps1` only if the one-liner proves awkward | 3 / 4 |
| twpayne | Secrets from 1Password via its CLI | **reject** | D14: no secrets in the repo; no password-manager CLI in bootstrap | — |
| [bandoyer/dotfiles](https://github.com/bandoyer/dotfiles) (Omarchy + chezmoi) | `.chezmoi.toml.tmpl` asks for a machine profile; heavy inline comments; "review `chezmoi diff` before applying" | **adopt** (confirms) | Same as our `profile` variable and cutover checklist | 2, 6 |
| bandoyer | Manages `~/.config/hypr` and `~/.config/omarchy` too | **backlog** | Desktop config is out of scope for v1 (scope guard) | post-v1 |
| bandoyer | Never `chezmoi re-add` whole folders Omarchy edits live; only re-add files you changed on purpose | **adopt** | Avoids capturing app state; goes in [troubleshooting.md](troubleshooting.md) | 3 |
| [joaodrp/omarchy](https://github.com/joaodrp/omarchy) | `~/.config/omarchy/hooks/post-update` re-runs `chezmoi apply` after `omarchy update` | **adopt** (confirms) | Already D15 | 3 (P3.07) |
| joaodrp | "Merge" scripts that add personal keys to app configs (Claude, opencode) without replacing the whole file | **backlog** | Useful for agent settings later ([dotfiles-legacy#109](https://github.com/seanbuckley/dotfiles-legacy/issues/109)); not v1 | post-v1 |
| [Omarchy manual: dotfiles](https://omarchy.org/manual/dotfiles/) *(indirect: omarchy.org is blocked here; confirmed via search snippets)* | Hooks live in `~/.config/omarchy/hooks/`. `post-update` runs after packages **and migrations**, so it is the right place to re-apply chezmoi. Other hooks exist, e.g. `theme-set` | **adopt** (confirms) | Confirms D15; P0c's check of the manual is done, as far as this sandbox allows. Sean can confirm on the laptop by opening the manual page in a browser there, or looking in `~/.config/omarchy/hooks/` | 3 |

## Community sweep (2025–2026)

Popular repos, blogs and discussions, searched on 2026-09-30. Reddit and X can't be
opened from this sandbox, so those were reached only through search results. Where a
thread couldn't be read, it isn't counted as evidence. Several good blogs were also
blocked (for example rednafi.com and recca0120.github.io on migrating to chezmoi);
they are listed as further reading only.

### Cross-platform chezmoi repos (closest to Sean's setup)

| Source | Idea | Verdict | Why | Phase |
|---|---|---|---|---|
| [pedropaulovc/dotfiles](https://github.com/pedropaulovc/dotfiles) (Windows + WSL, bash + pwsh) | One computed variable, **`platform` = `windows` / `wsl` / `linux`** (WSL detected from the kernel release), used everywhere instead of several checks | **adopt** | Simpler than separate `isWSL` + OS checks; add `darwin` for later. Architecture variables get updated when P2 is detailed | 2 |
| pedropaulovc | A **"second apply does nothing"** check: after `chezmoi apply`, running it again must change nothing | **adopt** | A cheap, strong test of idempotency; add to CI and the cutover checklist | 2–4, 6 |
| pedropaulovc | `.gitattributes` forcing LF so files are byte-identical on Windows and Linux | **adopt** (confirms) | Already planned (P1.02) | 1 |
| pedropaulovc | Secrets in untracked local files (`~/.config/shell/secrets.sh`) | **adopt** (confirms) | Same as our `*.local` files | 3 |
| [michael-gebis/dotfiles-windows](https://github.com/michael-gebis/dotfiles-windows) | Windows packages as a **`winget configure` file (DSC YAML)**, run by a chezmoi `run_onchange_` script when the file changes. Idempotent: installs missing, upgrades old, leaves the rest | **adapt: evaluate in P4** | Built into winget, and Microsoft's own direction for "set up this PC". But it's YAML-heavy and doesn't cover Chocolatey or Scoop (still required, D5). Default: a plain winget list; try DSC only if it proves simpler | 4 |
| [skenmy/dotfiles](https://github.com/skenmy/dotfiles) | **CI renders every template for every OS × profile** on each PR, plus pre-commit with shellcheck | **adopt** | Catches template mistakes before they reach a machine; cheap with `chezmoi execute-template` | 1–4 |
| skenmy | Generated docs listing every package per profile | **backlog** | Nice once the repo is public | post-v1 |
| skenmy | antidote (zsh plugin manager), mise (runtime manager), Bitwarden secrets in bootstrap | **reject** | Extra tools we don't need: chezmoi fetches plugins, vite-plus manages Node, and secrets are kept out of bootstrap (D14) | — |
| [locus313/dotfiles](https://github.com/locus313/dotfiles), [nathanielvarona/dotfiles](https://github.com/nathanielvarona/dotfiles), [rodolfocamara/dotfiles](https://github.com/rodolfocamara/dotfiles), [RomainClem/dotfiles](https://github.com/RomainClem/dotfiles) | More Windows + Linux/WSL chezmoi repos, one with a single Starship prompt across Windows and WSL | **adopt** (confirms) | They validate D1 and D9; useful to look at while building P3–P5 | 3–5 |

### Classic repos and guides

| Source | Idea | Verdict | Why | Phase |
|---|---|---|---|---|
| [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) (31k stars) | `~/.extra` (private, untracked) and `~/.path` (PATH additions, loaded first) | **adopt** (confirms) | Our `.zshrc.local`; PATH is built in one place | 3 |
| mathiasbynens | Bold README warning: *"Don't blindly use my settings… Use at your own risk!"* | **adopt** | Add a short note to the README before going public | 1 (P1.02) |
| [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles) | Curated list: holman's "dotfiles are meant to be forked", thoughtbot's rcm, holman's topic folders, Ansible-based setups | **reject** (for layout) | chezmoi's layout replaces these; the list is kept as a reference | — |
| [chezmoi docs: scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) and [install packages declaratively](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/) | Use scripts **sparingly**; every script (even `run_once`/`run_onchange`) must be **idempotent**; packages = `.chezmoidata/packages.yaml` + a `run_onchange_` script | **adopt** (confirms) | Matches architecture.md design rules 2–3 | 2–4 |

### Shell speed (zsh)

| Idea | Verdict | Why | Phase |
|---|---|---|---|
| Rebuild the completion cache at most **once a day** (`compinit -C` otherwise) | **adopt** | A common, well-tested trick; a few lines | 3 |
| **Cache tool init output** (zoxide, starship, fzf, direnv) and regenerate only when the tool changes | **adopt** | Same idea the Windows profile already uses (DECISIONS.md 13) | 3 |
| Measure: `ZSH_PROFILE_RC=1 zsh` + `zprof`, or `time zsh -i -c exit`; aim for under ~150 ms | **adopt** | Gives the "no Oh My Zsh" change a number to check against | 3 |
| `zcompile` everything, plugin managers with "turbo" loading | **reject** | Extra complexity for small gains once Oh My Zsh is gone | — |

Sources: [ctechols compinit gist](https://gist.github.com/ctechols/ca1035271ad134841284), [From 1.4s to 53ms (dev.to)](https://dev.to/martin_oehlert/from-14s-to-53ms-optimizing-zsh-startup-on-macos-5f09), [Speeding up zsh startup by 81%](https://wicksipedia.com/blog/speeding-up-zsh-startup).

### Git settings (from core git developers)

The [GitButler write-up](https://blog.gitbutler.com/how-git-core-devs-configure-git) of git developers' own settings.

| Idea | Verdict | Why | Phase |
|---|---|---|---|
| Better defaults:<br>• `branch.sort=-committerdate`<br>• `tag.sort=version:refname`<br>• `column.ui=auto`<br>• `diff.algorithm=histogram`<br>• `diff.colorMoved=plain`<br>• `diff.mnemonicPrefix=true`<br>• `diff.renames=true`<br>• `push.autoSetupRemote=true`<br>• `push.followTags=true`<br>• `fetch.prune=true`<br>• `fetch.pruneTags=true`<br>• `help.autocorrect=prompt`<br>• `commit.verbose=true`<br>• `rebase.updateRefs=true` | **adopt** | Safe, widely recommended, one line each with a comment; several (rerere, zdiff3, autoStash) are already in `.gitconfig` | 2 (P2.02) |
| `core.fsmonitor`, `core.untrackedCache` | **backlog** | Speed-ups for huge repos; not needed | post-v1 |

### PowerShell

| Idea | Verdict | Why | Phase |
|---|---|---|---|
| PSReadLine predictions (history-based, list view); keep the profile fast | **adopt** (confirms) | Already in `PSReadLineSettings.ps1`; the deferred loading already keeps it fast | 4 |
| One cross-shell prompt (Starship) on PowerShell too | **adopt** (confirms) | D9 | 5 |

Sources: [Microsoft: using predictors in PSReadLine](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors), [winget configure + DSC (woshub)](https://woshub.com/winget-dsc-configure/).

### "Modern CLI" consensus

Recent posts and repos agree on a small core: starship, zoxide, fzf, eza, bat, fd,
ripgrep, lazygit, atuin
([josean.com](https://www.josean.com/posts/7-amazing-cli-tools),
[alexanderkey.com](https://alexanderkey.com/blog/how-to-set-up-a-modern-terminal-with-ghostty-zsh-and-starship/)).
Our tool tiers in [platforms.md](platforms.md) already cover all of them except atuin,
which is in the backlog. **Verdict: adopt (confirms). No new tools.** Also mentioned:
ghostty, yazi, dust and mise; all are *reject/backlog*, as they're outside the scope guard.

## Adopted ideas by phase

| Phase | Ideas to carry into the phase's task list |
|---|---|
| 1 Baseline | README warning ("review before you apply"). CI: shellcheck, and template rendering for every OS × profile as templates arrive |
| 2 Shared core | `.chezmoiversion`. One `platform` variable (`windows`/`wsl`/`linux`/`darwin`). XDG layout rule. Git core-dev defaults. `$EDITOR` fallback chain. "Second apply changes nothing" check |
| 3 Linux | **Alias-or-script rule** (below). Scripts: `glall`, `copy`/`pasta`, `cpwd`, `tempe`, `scratch`, `prettypath`, `mksh` (today's `newsh`). grml option list + `.zshrc.local`. `ZSH_PROFILE_RC` profiling. Daily `compinit`, cached tool init, startup under ~150 ms. Plugins via `.chezmoiexternal`. `upgrade` as independent steps. Omarchy hook |
| 4 Windows | Same alias-or-script rule for PowerShell; same names as Linux. Plain winget list (Sean); `winget configure` later ([#118](https://github.com/seanbuckley/dotfiles-legacy/issues/118)); Chocolatey and Scoop stay (D5) |
| 6 Cutover | Read `chezmoi diff` first; after apply, a second apply must change nothing |
| Backlog (post-v1) | Evan Hahn's extra scripts (`hoy`, `notify`, `murder`, `running`…), `entr`/`tig`, generated package docs, Windows defaults script, Omarchy/Hyprland config, agent-settings merge scripts |

**The alias-or-script rule**
- Keep an **alias or shell function** when it changes the current shell (e.g. `cd`), needs tab completion of the wrapped command, uses the previous command's result, or only exists on some machines.
- Everything else with real logic becomes a **script** in `~/.local/bin`, or a `.ps1` in the Scripts folder on Windows.
- One-line helpers such as `new*` and `dtail` stay functions.

## Conflicts with decisions

None found. Sean answered the two open points on 2026-09-30:

1. **Scripts vs aliases.** Yes for `glall`: it becomes a small script (bash and PowerShell) in Phase 3/4. The other one-liners stay shell functions:
   - `new*`: create a file, set its permissions, open it in `$EDITOR`;
   - `dtail`: follow a docker container's logs.

   `colormap` (prints the 256-colour palette; currently broken) is dropped unless it's missed.
2. **No `install.sh` / `install.ps1` wrapper.** The chezmoi one-liner is enough. It downloads chezmoi itself, so nothing needs installing first (see [bootstrap.md](bootstrap.md)).

New since the first draft, for Sean at the P4 gate:

3. **`winget configure` (DSC YAML) vs a plain winget package list.** Answered 2026-09-30: **plain list for v1**. `winget configure` is tracked for after the merge in [#118](https://github.com/seanbuckley/dotfiles-legacy/issues/118).
