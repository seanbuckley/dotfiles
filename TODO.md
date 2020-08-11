# TODO

- [ ] branches for different machines
- [ ] reconfigure to use [bare git repository method](https://news.ycombinator.com/item?id=11070797)
- [ ] Add profiles:
  - [ ] ComEmu settings file
  - [ ] PowerShell profile
  - [ ] .p10k.zsh
  - [ ] .profile
  - [ ] .bashrc
  - [ ] .gitconfig?
- [ ] Review and integrate ideas from these dot file repos:
  - [ ] https://github.com/paulirish/dotfiles
  - [ ] https://github.com/samuelramox/wsl-setup
  - [ ] https://github.com/victoriadrake/dotfiles/
  - [ ] https://github.com/tomnomnom/dotfiles
- [ ] Review and add more [zsh plugins](https://github.com/unixorn/awesome-zsh-plugins)

## Scripts

- [ ] Finalize symlinks (and update as more dot files are)
- [ ] Setup SSH keys?
- [x] Run all scripts through <www.shellcheck.net>. Used VSCode integration
- [ ] integrate concepts from the re-write on these pages:
  - [ ] <https://codereview.stackexchange.com/questions/146896/simple-linux-upgrade-script-in-bash>
  - [ ] <https://linuxhint.com/30_bash_script_examples/>
  - [ ] <https://www.addictivetips.com/ubuntu-linux-tips/bash-scripts-to-automate-linux/>
  - [ ] <https://www.tecmint.com/using-shell-script-to-automate-linux-system-maintenance-tasks/>

TODO - check all items below are covered...

1. Run `sudo apt update && sudo apt -y upgrade && sudo apt autoremove`
2. Setup [ssh keys](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh). Tutorials [here](https://www.howtogeek.com/424510/how-to-create-and-install-ssh-keys-from-the-linux-shell/) and [here](https://www.cyberciti.biz/faq/how-to-set-up-ssh-keys-on-linux-unix/).
3. Install [build-essential](https://packages.ubuntu.com/bionic/build-essential) with `sudo apt install -y build-essential`.
4. Install [MesloNF fonts for Powerlevel10k](https://github.com/romkatv/powerlevel10k#manual-font-installation). Also consider installing Microsoft's [Cascadia Code](https://github.com/microsoft/cascadia-code) font.
5. Install [zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)
6. Install [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)
7. Install oh-my-zsh dot file and related plugin files:
   1. [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) with `git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use`
   2. [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) with `git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting`
   3. [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) with `git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`
8. Install [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
9. Install [personal dot files](https://github.com/bucks14/dotfiles). _Perhaps use a utility or symlink the files from the repo to the user root?_
10. Install [nvm](https://github.com/nvm-sh/nvm) ([tutorial here](https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-20-04#option-3-%E2%80%94-installing-node-using-the-node-version-manager) and [here](https://www.sitepoint.com/wsl2-windows-terminal/#installingnodejs)).
11. Alternatively, try [n (a node version manager)](https://github.com/tj/n). Use the install script [n-install](https://github.com/mklement0/n-install) with the command `curl -L https://git.io/n-install | bash`. This will install the latest version of [Node.js](https://nodejs.org/en/). Note: when last I tried, `n-install` was not working well with WSL Ubuntu 20.04.
12. Install [node.js](https://nodejs.org/) with `nvm install node` (which is an alias for the latest version).

## Reference

- [Hacker News - managing dot files](https://news.ycombinator.com/item?id=11070797)
