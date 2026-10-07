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
| Machine-only shell settings | `~/.zshrc.local`, `Microsoft.PowerShell_profile.local.ps1` |
| List of private repos to clone | Local chezmoi data or `~/.config/dotfiles/repos.txt`, not the repo |
| Real secrets (if ever needed) | Password manager, or chezmoi's built-in `age` encryption (fits the SOPS + age setup used in the homelab repo). **Not the Bitwarden CLI** |

## Audit checklist (P1.01, before going public)

Run by the agent, then reviewed by Sean.

- [ ] `gitleaks detect --no-git --source .` → no findings
- [ ] `gitleaks detect --source .` (history of the new repo) → no findings
- [ ] Search tracked files for each item; each hit is fixed or explicitly accepted:
  - [ ] private IPs: `rg -n '\b(10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]+\.[0-9]+'`
  - [ ] emails: `rg -n '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}'`, where only `users.noreply.github.com` is allowed
  - [ ] user paths: `rg -n -i 'C:\\\\Users\\\\|/home/[a-z]|/Users/[a-z]'`
  - [ ] token shapes: `rg -n 'ghp_|gho_|github_pat_|sk-|xox[bap]-|AKIA|-----BEGIN'`
  - [ ] names: company/tenant names, the work-machine name, the redirected-folder server name, LAN hostnames. The **list of words is kept outside the repo** by Sean and passed to `rg -f`
- [ ] No `Tabby/`, `.hyper.js`, legacy `Windows Terminal/settings.json` or `.vscode/` in `legacy/`
- [ ] `legacy/linux/scripts/repos-install.sh`: the private repo names are OK to show (they aren't secret), or moved to local data. Sean decides
- [ ] Sean reads the whole `git ls-files` list once

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

To change the list: edit the Bitwarden note, then paste it into the Actions secret.

## Ongoing protection

- The **gitleaks** job runs on every PR ([testing.md](testing.md)). Optionally, a local `pre-commit` hook runs gitleaks too.
- GitHub secret scanning + push protection: turn both on in repo settings once the repo is public (free for public repos).
- Dependabot for GitHub Actions versions only.
