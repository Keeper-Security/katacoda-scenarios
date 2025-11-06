#!/bin/bash

echo "Installing Keeper Secrets Manager Ruby SDK..."

# Install Ruby and dependencies (simple approach)
apt update -qq && apt install -y -qq software-properties-common

# Add Brightbox Ruby PPA for Ruby 3.2
add-apt-repository -y ppa:brightbox/ruby-ng
apt update -qq

# Install Ruby 3.2
apt install -y ruby3.2 ruby3.2-dev build-essential

# Make Ruby 3.2 the default
update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby3.2 1
update-alternatives --install /usr/bin/gem gem /usr/bin/gem3.2 1

# Install KSM gem
gem install keeper_secrets_manager --version 17.1.0 --no-document

echo "Installation completed!"
echo "Testing installation..."
ruby -e "require 'keeper_secrets_manager'; puts 'KSM Ruby SDK ' + KeeperSecretsManager::VERSION + ' ready!'" || echo "Installation completed but may need manual verification"
echo "Ready to start coding with KSM Ruby SDK!"
