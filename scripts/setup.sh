#!/bin/bash
#
# Linux/WSL setup script
#
# Windows reminder: Carrage returns must be set to LF, not CF

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

source ./install/utils.sh
keep_sudo_alive

echo -e "${GREEN}Startng setup script${NOCOLOR}"

echo "Current version info"
lsb_release -a

# Symlink dot files from this repo
#./symlink.sh

# Update and install programs
#./apt-install.sh

echo -e "${GREEN}Ending Setup script${NOCOLOR}"

# Restart the bash shell
source ~/.bashrc
