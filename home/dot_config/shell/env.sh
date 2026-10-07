# shellcheck shell=sh
# ~/.config/shell/env.sh: environment shared by zsh and bash (POSIX sh).
# Sourced from Phase 3 on. Values already set win, so a line in a local
# override (EDITOR=nvim in ~/.zshrc.local, before this runs) changes the editor
# on one machine (docs/decisions.md, D10).

# Editor: micro if installed, else nano, else vi (on every POSIX system).
# git, crontab and sudoedit all read these; there is no core.editor.
if [ -z "${EDITOR:-}" ]; then
  if command -v micro >/dev/null 2>&1; then
    EDITOR="micro"
  elif command -v nano >/dev/null 2>&1; then
    EDITOR="nano"
  else
    EDITOR="vi"
  fi
fi
: "${VISUAL:=$EDITOR}"
export EDITOR VISUAL
