#!/bin/bash

echo "Installing Keeper Secrets Manager Ruby SDK..."

# Install Ruby 3.2 and dependencies (available in Ubuntu 24.04 default repos)
apt update -qq && apt install -y -qq ruby3.2 ruby3.2-dev build-essential

# Install KSM gem
gem install keeper_secrets_manager --version 17.1.0 --no-document

echo "Installation completed!"
echo "Testing installation..."
ruby -e "require 'keeper_secrets_manager'; puts 'KSM Ruby SDK ' + KeeperSecretsManager::VERSION + ' ready!'" || echo "Installation may need verification"
echo "Ready to start coding with KSM Ruby SDK!"
