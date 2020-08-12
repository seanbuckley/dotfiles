#!/bin/bash
#
#
# --- Linux/WSL Setup Scripts ---
# Install global npm packages

source ./install/utils.sh
keep_sudo_alive

e_header "Starting global npm package installation (npm-install.sh)"

# Verify node.js is installed
var="nodejs"
e_header "Verifying that $var is installed..."
if which node &> /dev/null; then
  e_success "$var is installed"
  else
  e_warning "Installing $var..."
  sudo apt -y install $var npm
fi

# Packages
#sudo npm install -g create-react-app
#sudo npm install -g create-react-native-app
#sudo npm install -g eslint
#sudo npm install -g gulp-cli
#sudo npm install -g sass
#sudo npm install -g typescript
#sudo npm install -g tslint

# Finish
e_success "Finished npm packages settings."
