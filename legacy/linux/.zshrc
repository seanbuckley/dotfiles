# ==============================================================================
# ~/.zshrc: interactive zsh configuration (Linux / WSL)
#
# What:     Loads Oh My Zsh with the plugins listed below, the Powerlevel10k
#           prompt, Homebrew, personal aliases (~/.aliases) and vite-plus.
# Used by:  every interactive zsh. Symlinked to ~/.zshrc by
#           scripts/dotfile-install.sh, so editing ~/.zshrc edits this file.
# Needs:    Oh My Zsh + plugins + p10k (scripts/oh-my-zsh-install.sh).
#           Homebrew and vite-plus are optional; their blocks are guarded.
# Layout:   1. p10k instant prompt (must stay first)
#           2. Oh My Zsh settings (mostly the stock template, commented out)
#           3. plugins=(...) and `source $ZSH/oh-my-zsh.sh`
#           4. "Custom tweaks": editor, Homebrew, PATH, aliases, prompt
#           5. Lines appended by tool installers (vite-plus, Antigravity, opencode)
# Gotchas:  ~/.local/bin is added to PATH more than once (here and in
#           .zprofile); harmless but untidy. Tracked in dotfiles#103.
# Fate:     rewrite as a lean, commented .zshrc without Oh My Zsh
#           (docs/decisions.md, D8).
# ==============================================================================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
#
# What each one gives you, and what the new repo plans to do about it, is in
# docs/decisions.md ("Oh My Zsh"). The three zsh-* plugins at the bottom are
# not part of Oh My Zsh; scripts/oh-my-zsh-install.sh clones them into
# $ZSH_CUSTOM/plugins. Note `z` is still the active directory jumper even
# though zoxide is installed (dotfiles#91).
plugins=(
  alias-finder
  aliases
  ansible
  colored-man-pages
  colorize
  command-not-found
  common-aliases
  docker
  docker-compose
  dotenv
  extract
  #fast-syntax-highlighting # Using zsh-syntax-highlighting
  fzf
  gatsby
  gh
  git
  git-extras
  gitignore
  node
  npm
  ssh-agent
  #thefuck
  #tmux
  vscode
  z
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-navigation-tools
  #zsh-syntax-highlighting should always be last in the list of plugins to avoid conflicts with other plugins.
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#-------------------------
# Custom tweaks
#-------------------------


# Set editor to Neovim
#export EDITOR="nvim"
#export VISUAL="nvim"
#export EDITOR="nano"
#export VISUAL="nano"
# Only the last uncommented line counts. `--wait` makes the terminal pause until
# the VS Code tab is closed, so tools like `crontab -e` see the saved file.
# (git ignores this: .gitconfig sets core.editor = nano, which wins.)
export EDITOR="code --wait"
#export VISUAL="code --wait"

# Homebrew initialization. Also in .zprofile on purpose; see the note there.
# Guarded because `brew shellenv` forks a subprocess: skip it when .zprofile, a
# parent shell, or the ~/.profile fallback from scripts/homebrew-install.sh
# already ran it.
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Add Ansible PATH
# ~/.local/bin holds pip/pipx tools (Ansible) and the bat/fd links made by
# apt-install.sh. It is also added in .zprofile and again at the end of this
# file, so it appears on PATH several times (dotfiles#103).
PATH=$HOME/.local/bin:$PATH

# Source personal aliases
source $HOME/.aliases

# Enable zsh autocompletion & colors
#autoload -Uz compinit && compinit #Oh-my-zsh already calls compinit internally during startup, so this line runs it a second time unnecessarily, slowing down your shell startup.
autoload -U colors && colors

# Set alias-finder-plugin to run automatically before each command
# (Newer Oh My Zsh versions read `zstyle ':omz:plugins:alias-finder' autoload yes`
# instead of this variable, so this line may have no effect.)
ZSH_ALIAS_FINDER_AUTOMATIC=true

# Enable thefuck
#eval "$(thefuck --alias)"
#-------------------------

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Vite+ bin (https://viteplus.dev)
# Guarded: a missing env file must not break shell startup on a fresh machine.
[[ -s "${XDG_CONFIG_HOME:-$HOME/.config}/vite-plus/env" ]] &&
  source "${XDG_CONFIG_HOME:-$HOME/.config}/vite-plus/env"

# pnpm comes from vite-plus's shims (pnpm, pnpx, pn, pnx), versioned per project
# by package.json's packageManager field. Don't run `pnpm setup`: it re-adds a
# PNPM_HOME block that puts a standalone pnpm ahead of vite-plus on PATH.
# Install global packages with `vp install -g`, not `pnpm add -g`.

# Everything below was appended by tool installers. Each puts its own bin
# folder at the front of PATH.
# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=$HOME/.opencode/bin:$PATH
