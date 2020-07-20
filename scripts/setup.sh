#!/bin/bash
#
# Linux/WSL setup script
#
# Borrowed from:
# https://github.com/samuelramox/wsl-setup
# https://github.com/victoriadrake/dotfiles/
# https://github.com/tomnomnom/dotfiles
#
# Reminder: Carrage return must be set to LF, not CF

# TODO
# - Finalize symlinks
# - Setup SSH keys?
# - Run all scripts through <www.shellcheck.net>
# - integrate concepts from the re-write on these pages:
# https://codereview.stackexchange.com/questions/146896/simple-linux-upgrade-script-in-bash
# https://linuxhint.com/30_bash_script_examples/
# https://www.addictivetips.com/ubuntu-linux-tips/bash-scripts-to-automate-linux/
# https://www.tecmint.com/using-shell-script-to-automate-linux-system-maintenance-tasks/

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

source ./install/utils.sh
keep_sudo_alive

echo -e "${GREEN}Startng setup script${NOCOLOR}"

echo "Current version info"
lsb_release -a

#./symlink.sh
#./aptinstall.sh

echo -e "${GREEN}Ending Setup script${NOCOLOR}"

# Restart the bash shell
source ~/.bashrc
