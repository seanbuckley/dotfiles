# TODO

## Urgent

- [ ] Errors: Script with `nvm install node latest` doesn't work. Then the npm install checks for node, doesn't see it, and installs node via apt.
- [ ] Review and remove one instance of the git config set username and email. Completed via scripting (setup.sh) and also explicitly set in .gitconfig file.
- [ ] Add to scripts: install [MesloNF fonts for Powerlevel10k](https://github.com/romkatv/powerlevel10k#manual-font-installation). Also consider installing Microsoft's [Cascadia Code](https://github.com/microsoft/cascadia-code) font.
- [ ] Add to scripts: complete setup of [ssh keys](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh). Tutorials [here](https://www.howtogeek.com/424510/how-to-create-and-install-ssh-keys-from-the-linux-shell/) and [here](https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix/).
- [ ] Add [zsh-wakatime](https://github.com/wbingli/zsh-wakatime), dependencies, and setup files.
- [ ] Add a check and execute function (via [this dot file](https://github.com/hamsternik/dotfiles/blob/master/.zshrc):

```shell
  check_and_exec () {
      if [[ -e $1 ]]; then source $1; fi
  }
```

- [ ] Add [.npmrc](https://node.dev/post/configuring-your-npmrc-for-an-optimal-node-js-environment) file.
- [ ] Add [github CLI](https://cli.github.com/) to install script.
- [ ] Add [croc](https://github.com/schollz/croc) (CLI file transfers) to install script.

## Someday

- [ ] [Homebrew for Linux/WSL](https://docs.brew.sh/Homebrew-on-Linux)
- [ ] Investigate switch to [Antibody](https://getantibody.github.io/), [zgen](https://github.com/tarjoilija/zgen), [Zinit](https://github.com/zdharma/zinit), [zplug](https://github.com/zplug/zplug), etc. Comparisons [here](https://www.reddit.com/r/zsh/comments/ak0vgi/a_comparison_of_all_the_zsh_plugin_mangers_i_used/) and [here](https://jdhao.github.io/2019/10/08/zsh_plugin_managers_compare/)
- [ ] Run all scripts through <www.shellcheck.net>. Or use VSCode integration.
- [ ] Add profiles:
  - [ ] ComEmu settings file
  - [ ] PowerShell profile
  - [x] .p10k.zsh
  - [ ] .profile
  - [ ] .bashrc
  - [ ] .gitconfig?
- [ ] Review and integrate ideas from these dot file repos:
  - [ ] https://github.com/paulirish/dotfiles
  - [ ] https://github.com/samuelramox/wsl-setup
  - [ ] https://github.com/victoriadrake/dotfiles/
  - [ ] https://github.com/tomnomnom/dotfiles
  - [ ] https://github.com/mislav/dotfiles
- [ ] Review and add more [zsh plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [ ] Integrate concepts from the re-write on these pages:
  - [ ] https://www.reddit.com/r/zsh/comments/hyoy6x/understanding_and_configuring_zsh/
  - [ ] https://codereview.stackexchange.com/questions/146896/simple-linux-upgrade-script-in-bash
  - [ ] https://linuxhint.com/30_bash_script_examples/
  - [ ] https://www.addictivetips.com/ubuntu-linux-tips/bash-scripts-to-automate-linux/
  - [ ] https://www.tecmint.com/using-shell-script-to-automate-linux-system-maintenance-tasks/
  - [ ] https://codereview.stackexchange.com/questions/146896/simple-linux-upgrade-script-in-bash
- [ ] branches for different machines
- [ ] find best method for sourcing files an the PATH issues that arise. See [here](http://mywiki.wooledge.org/BashFAQ/028) and [here](https://stackoverflow.com/questions/6659689/referring-to-a-file-relative-to-executing-script) for more info.
- [ ] reconfigure to use [bare git repository method](https://news.ycombinator.com/item?id=11070797)

## Complete

- [x] Test if `nvm install --lts1` and `nvm use --lts` (npm-install.sh) actually work in a full script run (without terminal reload). Spoiler: they don't.
- [x] antigen install didn't work. Corrected.
- [x] Finalize symlinks (and update as more dot files are). Using copy instead.
- [x] Run `sudo apt update && sudo apt -y upgrade && sudo apt autoremove`

## Reference

- [Hacker News - managing dot files](https://news.ycombinator.com/item?id=11070797)
