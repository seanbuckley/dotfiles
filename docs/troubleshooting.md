# Troubleshooting

Known gotchas, most from the two old repos. Add new ones as they're found, as short
entries in the form *symptom → cause → fix*.

## Migration

### Renamed repo redirect breaks
- **Symptom:** `git pull` in an old clone fails with `refusing to merge unrelated histories`, or `glall` pulls the wrong repo. Old issue links open the wrong issue.
- **Cause:** after `dotfiles` is renamed to `dotfiles-legacy`, GitHub redirects the old name, **until a new repo takes that name**. From then on, `seanbuckley/dotfiles` means the new repo.
- **Fix:** repoint every old clone *before* creating the new repo: `git remote set-url origin https://github.com/seanbuckley/dotfiles-legacy.git`. Rewrite old issue links to `dotfiles-legacy/issues/N`.

### Transferred issues get new numbers
- **Cause:** GitHub issue transfer renumbers the issue in the target repo. Archived repos can't transfer issues.
- **Fix:** transfer during Phase 6, *before* archiving. The old URL redirects to the new issue.

## Windows

### Profile changes don't show up
- **Cause:** an old `$PROFILE` loader still points at the old checkout. The profile's `DotfilesWindowsProfileLoaded` guard means the **first** loader to run wins.
- **Fix:** check both `$PROFILE` files (PowerShell 7 and 5.1). Remove the old loader lines, then re-run `chezmoi apply`.

### `$PROFILE` is not in `~\Documents`
- **Cause:** Documents is redirected to OneDrive or a network share. This happens on the work PC: [windows#63](https://github.com/seanbuckley/dotfiles-windows/issues/63).
- **Fix:** never hardcode `~/Documents`. Find it at runtime with `[Environment]::GetFolderPath('MyDocuments')`, which the loader script does. Slow startup on a network share is a machine issue: see windows#63.

### Garbled characters or emoji in Windows PowerShell 5.1
- **Cause:** 5.1 reads UTF-8 files **without** a BOM as the system code page.
- **Fix:** save `.ps1` files that contain non-ASCII characters as UTF-8 **with** BOM, or keep them ASCII-only. PowerShell 7 is fine either way.

### `-Encoding utf8NoBOM` error in 5.1
- **Cause:** that encoding name only exists in PowerShell 7.
- **Fix:** branch on `$PSVersionTable.PSVersion.Major`, or use `[System.IO.File]::WriteAllText` with `New-Object System.Text.UTF8Encoding $false`.

### Symlinks fail
- **Cause:** creating symlinks on Windows needs admin rights or Developer Mode.
- **Fix:** don't use them. chezmoi copies files by default, which is what we want.

### A bash script from the repo fails with `bad interpreter` or `$'\r'`
- **Cause:** CRLF line endings.
- **Fix:** `.gitattributes` forces LF. If you see this, check `git config core.autocrlf` (it should be `false` or `input`) and re-checkout.

## Linux

### Omarchy update overwrote my config
- **Cause:** `omarchy-update` / `omarchy-refresh-*` can restore Omarchy's defaults.
- **Fix:** the post-update hook (`~/.config/omarchy/hooks/post-update`) runs `chezmoi apply` afterwards. If it didn't run, run `chezmoi apply` manually and check that the hook is executable.

### `bat` / `fd` not found on Ubuntu
- **Cause:** Debian names them `batcat` and `fdfind`.
- **Fix:** the shell config aliases them. Check that `~/.local/bin` is on PATH.

### Duplicate PATH entries
- **Cause:** the same directory is added in several rc files, which happened in the old repo ([#103](https://github.com/seanbuckley/dotfiles-legacy/issues/103)).
- **Fix:** PATH is built in one place in the new shell config, using an "add if missing" helper.

## chezmoi

### I edited `~/.zshrc` and chezmoi overwrote it
- **Cause:** `~/.zshrc` is the *target*; the source is in the repo.
- **Fix:** use `chezmoi edit ~/.zshrc`, or run `chezmoi re-add` to pull your manual edit into the source. Machine-only tweaks go in `~/.zshrc.local`.

### A `run_once_` script doesn't re-run after I changed it
- **Cause:** that's how `run_once_` behaves.
- **Fix:** we use `run_onchange_` scripts, which re-run when their content, including an embedded hash of `packages.yaml`, changes.

### `chezmoi init` asks questions in CI
- **Fix:** pass `--promptDefaults` and set the `DOTFILES_*` environment variables ([bootstrap.md](bootstrap.md#unattended)).
