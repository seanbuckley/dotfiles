# Security and public readiness

The new repo is meant to go **public at v0.1.0**. That's only safe if nothing private is
in it. Anything pushed to a public repo can be cached or forked within minutes, so
checking happens *before* the visibility flip, not after.

## Rules

1. **No secrets in the repo, ever.** That covers tokens, passwords, API keys, private SSH/GPG keys, Wi-Fi keys, and even encrypted blobs, for v1.
2. **No host-specific or private details:**
   - private IPs;
   - internal hostnames;
   - usernames other than the public GitHub handle;
   - OneDrive tenant names, company names or work repos;
   - machine IDs and serials;
   - absolute paths such as `C:\Users\...`.
3. **Email:** only the GitHub noreply address in tracked files. Real addresses go in the local chezmoi config.
4. **If a secret was ever committed, rotate it first.** Deleting or rewriting history is second. Assume a pushed secret is compromised.
5. **Found one?** Stop, report to Sean, and don't push. See the Core safety rules in `AGENTS.md`.

## Where private values go instead

| Kind | Put it in |
|---|---|
| Git identity, work email | `chezmoi init` answers → `~/.config/chezmoi/chezmoi.toml` |
| Work git config, signing key | `~/.gitconfig_local` |
| Work repo folders, work identity | `workGitDirs` under `[data]` in `~/.config/chezmoi/chezmoi.toml`; name, email and signing key in `~/.gitconfig_work` |
| Machine-only shell settings | `~/.zshrc.local`, `Microsoft.PowerShell_profile.local.ps1` |
| List of private repos to clone | Local chezmoi data or `~/.config/dotfiles/repos.txt`, not the repo |
| Real secrets (if ever needed) | Password manager, or chezmoi's built-in `age` encryption (fits the SOPS + age setup used in the homelab repo). **Not the Bitwarden CLI** |

## Audit checklist (P1.01, before going public)

Run by the agent, then reviewed by Sean.

Last run 2026-10-07 on `main` (`ed84efb`, 82 files). Every item below is done.

- [x] `gitleaks detect --no-git --source .` → no findings (also every PR, in CI)
- [x] `gitleaks detect --source .` (history of the new repo) → no findings (also every PR, in CI)
- [x] Search tracked files for each item; each hit is fixed or explicitly accepted:
  - [x] private IPs: `rg -n '\b(10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]+\.[0-9]+'` → none
  - [x] emails: `rg -n '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}'`, where only `users.noreply.github.com` is allowed → only `git@github.com` SSH URLs and an `x@y.com` placeholder in `legacy/linux/.p10k.zsh`. Accepted
  - [x] user paths: `rg -n -i 'C:\\\\Users\\\\|/home/[a-z]|/Users/[a-z]'` → only `/home/linuxbrew` (Homebrew's standard prefix), generic `<name>` placeholders, `.p10k.zsh` comments and the `Test-Dotfiles.ps1` detection regex. Accepted
  - [x] token shapes: `rg -n 'ghp_|gho_|github_pat_|sk-|xox[bap]-|AKIA|-----BEGIN'` → only false positives (`task-id`, `task-files`, this line). Accepted
  - [x] names: Sean ran the word list locally (2026-10-05); CI's `private-words` job passed on `main` with the full list (2026-10-07). Private repo names were removed; Sean's own name, noreply email and `buckley.ca` are public on purpose
- [x] No `Tabby/`, `.hyper.js`, legacy `Windows Terminal/settings.json` or `.vscode/` in `legacy/`
- [x] `legacy/linux/scripts/repos-install.sh`: private repo names removed (Sean, 2026-10-05); only `seanbuckley/dotfiles` remains
- [x] Sean reads the whole `git ls-files` list once (paths, to catch any file that shouldn't be here; contents are covered by the scans above). Done 2026-10-07: `legacy/` paths in PR [#1](https://github.com/seanbuckley/dotfiles/pull/1) (legacy snapshot), the other 24 in chat; Sean also skimmed `docs/` and `legacy/`

## Findings to date (2026-09-30)

| Where | Finding | Action |
|---|---|---|
| `dotfiles` history (84 commits) | Scanned for tokens, keys and private IPs. **Clean** | None. History is not imported anyway |
| `dotfiles-windows` history | `Tabby/config.yaml` holds a LAN IP + username (current file and history). The token fields are placeholders, never live tokens | Never import this history. Don't snapshot `Tabby/`. The old repo stays private and archived |
| `dotfiles/.npmrc` | Personal email (not the noreply one) | Replace in the snapshot; move to local config |
| `dotfiles/.gitconfig`, `dotfiles-windows/.gitconfig` | Name + noreply email | Fine |
| `dotfiles/.gitconfig` | Commented `C:\Users\...` and `/mnt/c/...` paths | Remove in the snapshot |
| `dotfiles-windows/DECISIONS.md` | Example path `C:\Users\<name>\...` | Generalise in the snapshot |
| `dotfiles/scripts/repos-install.sh`, README | Names private repos | Sean decides (see checklist) |

Because the new repo starts with **no history**, no history rewriting (`git filter-repo`)
is needed. The old repos keep their history privately and are archived, not made public.

## Private words

Names that must never appear in the repo (company, tenant, machine, host and family names, private
repos) are kept in a word list that is **never committed**, not even encrypted.

| Layer | Where the list lives | What it catches |
|---|---|---|
| Master copy | Bitwarden secure note, "dotfiles audit words" | Survives a lost or rebuilt PC |
| CI check (P1.03) | GitHub Actions secret `AUDIT_WORDS` | Every PR, from any machine or agent. Prints matching file names only, so the public log never shows a word |
| Local hook (Phase 2, parked) | `~/.config/dotfiles/audit-words.txt`, filled from Bitwarden | Blocks the commit before it happens; warns if the file is missing |

To change the list: edit the Bitwarden note, then paste it into the `AUDIT_WORDS` secret under **both** Settings → Secrets → Actions and Settings → Secrets → Dependabot (Dependabot PRs can't read Actions secrets).

## Ongoing protection

- The **gitleaks** job runs on every PR ([testing.md](testing.md)). Optionally, a local `pre-commit` hook runs gitleaks too.
- GitHub secret scanning + push protection: turn both on in repo settings once the repo is public (free for public repos).
- Dependabot for GitHub Actions versions only.
