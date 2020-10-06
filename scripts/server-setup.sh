#!/bin/bash

#
# Windows reminder: Carrage returns must be set to LF, not CF
#
## Referenced from: https://github.com/samuelramox/wsl-setup/blob/master/install/utils.sh

declare _PROGNAME

_PROGNAME=$(basename -- "$0")

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_DIR/utils.sh

e_header "Startng main setup script"

e_header "System version info"
lsb_release -a

_APT-INSTALL() {
e_header "Starting application install"

# Add repos
e_header "Adding Repositories"
sudo add-apt-repository -y ppa:aacebedo/fasd
sudo add-apt-repository -y ppa:git-core/ppa

# Add gh (Github CLI repository)
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository https://cli.github.com/packages

e_header "Updating Ubuntu"
sudo apt -y update
sudo apt -y upgrade
sudo apt autoremove
# sudo apt full-upgrade

# Install command line utils
e_header "Installing command line utilities:"
installPackage git
installPackage build-essential
installPackage curl
installPackage fasd
installPackage zsh
installPackage gh
#installPackage zsh-antigen # Problems with this version

# Install Antigen manually instead
e_header "Installing Antigen with curl"
sudo curl -L git.io/antigen > ~/.antigen.zsh

# Install WSL items
seek_confirmation "Warning: Is this a WSL installation?"
if is_confirmed; then
  e_header "Installing WSL utilities"
  installPackage ubuntu-wsl # See https://github.com/wslutilities/wslu

  # Install VSCode prerequisites
  #installPackage shellcheck

else
  e_warning "Skipped WSL utilities install"
fi

# Install oh-my-zsh
# Not required. Currently installed by Antigen.
#e_header "Installing Oh My Zsh"
#sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Make zsh the default shell
e_header "Making zsh the default shell"
chsh -s $(which zsh)
#chsh -s /bin/zsh

# zsh version info
zsh --version

e_header "Default shell is now: {$SHELL}"

e_success "Completed apt-install.sh"

}

_UPDATE() {
	echo -e "Checking for updates..."
	sudo apt update
	sudo apt -y upgrade
}

while [ ! $# -eq 0 ]; do
	case "$1" in
	--all | -a)
        keep_sudo_alive
		_UPDATE
        _APT-INSTALL
		;;
    --apt | -i)
        keep_sudo_alive
        _APT-INSTALL
        ;;    
	--update | -u)
        keep_sudo_alive
		_UPDATE
		;;
	esac
	shift
done

usage() {
	cat <<EOF

Usage: $_PROGNAME <options>
Options:
    -a, --all       Install complete list
    -i, --apt       Install apt package list
    -u, --update    Update system and upgrade packages
EOF
}

if [[ "$1" == "" ]]; then
	usage
	exit 0
fi

exit 0