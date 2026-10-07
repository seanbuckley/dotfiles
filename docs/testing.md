# Testing

Two layers:

1. **GitHub Actions**, on every PR. Cheap, automatic, and required before merge.
2. **Real machines**, in a safe order: container → throwaway VM/LXC or spare user → daily machine.

Keep the toolchain light: everything below is a standard, well-known tool with a
maintained GitHub Action or a one-line install.

## Quality gates

Added in P1.03 and extended as code lands.

| Check | Tool | Runs on |
|---|---|---|
| Shell lint | `shellcheck` | `*.sh`, `*.sh.tmpl` (rendered first), `executable_*` |
| Shell format | `shfmt -d -i 2 -ci` | same |
| PowerShell lint | `PSScriptAnalyzer` (`Invoke-ScriptAnalyzer -Recurse -Severity Warning,Error`) | `*.ps1` |
| Secret scan | `gitleaks` | whole repo, including `legacy/` |
| Private words | `rg -l -i -w -f` with the `AUDIT_WORDS` Actions secret ([security.md](security.md#private-words)) | whole repo, including `legacy/`; prints file names only |
| JSON / YAML / TOML parse | `jq`, `yq`, `taplo` (or a small Python check) | config files |
| Markdown links | `lychee` (offline mode for relative links, plus external links weekly) | `*.md` |
| Line endings | `editorconfig-checker` (indent-size check off: Markdown list continuations) | everything outside `legacy/` |

Tool versions are pinned in `lint.yml`'s `env`; only `actions/checkout` is a third-party action, pinned by SHA and updated by Dependabot.

`legacy/` is excluded from lint (it's frozen) but **not** from gitleaks or the private-words check.

## Apply tests

Added in Phases 2–4. Each job runs chezmoi against the checked-out source, with no prompts:

```sh
chezmoi init --apply --promptDefaults --source "$GITHUB_WORKSPACE" \
  # env: DOTFILES_PROFILE=<profile>, CI=1
chezmoi verify     # nothing left to apply
```

| Job | Image / runner | Profile | Required to pass |
|---|---|---|---|
| Ubuntu | `ubuntu-latest` | workstation | ✅ |
| Ubuntu minimal | `ubuntu:24.04` container | minimal | ✅ |
| Arch | `archlinux:latest` container | workstation | ✅ |
| Fedora | `fedora:latest` container | workstation | ✅ (best effort; may be relaxed if flaky) |
| Alpine | `alpine:latest` container | minimal | ✅ |
| Windows | `windows-latest` | workstation | ✅ |
| macOS | `macos-latest` | workstation | ❌ allowed to fail (untested platform) |

Each job then runs a smoke test:

- the shell starts cleanly (`zsh -i -c exit`, `bash -i -c exit`, `pwsh -NoProfile -Command ". $PROFILE"`);
- `upgrade --help` works;
- the required tools are on PATH.

CI can't test Omarchy itself (desktop), real `$PROFILE` redirection, or Windows
Terminal. Those are Sean's manual checks.

## Manual test order

1. **Container** on any machine: `docker run --rm -it ubuntu:24.04`, then the [minimal one-liner](bootstrap.md#proxmox-lxc--vm-minimal-profile).
2. **Throwaway Proxmox LXC/VM**: a full `workstation` bootstrap, then `upgrade`. Snapshot first, and destroy it afterwards.
3. **Spare user account** (Omarchy/Windows): `chezmoi init --apply` as a second local user, so nothing of Sean's real profile is touched.
4. **Daily machine:** only via the [cutover checklist](bootstrap.md#cutover-an-existing-machine), with `chezmoi diff` read first.

## Local checks for agents

Before pushing, run what's available locally and say which checks you couldn't run:

```sh
git diff --check
shellcheck <changed .sh files>
shfmt -d -i 2 -ci <changed .sh files>
pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path <file> -Severity Warning,Error"
gitleaks detect --no-git --source .
chezmoi apply --dry-run --verbose --source .   # from Phase 2 on
```
