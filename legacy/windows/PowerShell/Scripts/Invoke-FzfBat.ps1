# fzf and bat utility integration
# Source: https://github.com/sharkdp/bat?tab=readme-ov-file#fzf
#
# What:     `fzfb`: fuzzy-find a file with a bat preview of its contents.
# Loaded:   lazily, on first use. Needs fzf and bat on PATH.
# Fate:     port, with the same name on Linux (P4).

Function Invoke-FzfBat () {
    Invoke-Expression "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"
}
Set-Alias -Name fzfb -Value Invoke-FzfBat