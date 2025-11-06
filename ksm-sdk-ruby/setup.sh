#!/bin/bash

set -e  # Exit on error

# Add Ruby 3.2 PPA and install
echo "Installing Ruby 3.2 and dependencies..."
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq software-properties-common >/dev/null 2>&1
add-apt-repository -y ppa:brightbox/ruby-ng >/dev/null 2>&1
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq ruby3.2 ruby3.2-dev build-essential >/dev/null 2>&1

# Make Ruby 3.2 the default
echo "Setting Ruby 3.2 as default..."
update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby3.2 1 >/dev/null 2>&1
update-alternatives --install /usr/bin/gem gem /usr/bin/gem3.2 1 >/dev/null 2>&1
update-alternatives --set ruby /usr/bin/ruby3.2 >/dev/null 2>&1
update-alternatives --set gem /usr/bin/gem3.2 >/dev/null 2>&1

# Set up gem environment
export GEM_HOME="/usr/local/bundle"
export BUNDLE_SILENCE_ROOT_WARNING=1
export PATH="$GEM_HOME/bin:$PATH"

# Create gem directory
mkdir -p "$GEM_HOME"

# Install the Keeper Secrets Manager gem
echo "Installing KSM Ruby SDK 17.1.0..."
gem install keeper_secrets_manager --version 17.1.0 --no-document --install-dir "$GEM_HOME" 2>&1 | grep -v "default gem" || true

# Verify installation
if ruby -e "require 'keeper_secrets_manager'" 2>/dev/null; then
  echo "✅ KSM SDK installed successfully"
else
  echo "❌ KSM SDK installation failed"
  exit 1
fi

# Create working directory
mkdir -p /root/ksm-tutorial
cd /root/ksm-tutorial

# Export paths for runtime
echo "export GEM_HOME='$GEM_HOME'" >> /root/.bashrc
echo "export PATH='$GEM_HOME/bin:$PATH'" >> /root/.bashrc

clear
echo "✅ Environment ready!"
echo "   Ruby: $(ruby --version | awk '{print $2}')"
echo "   KSM SDK: $(ruby -e "require 'keeper_secrets_manager'; puts KeeperSecretsManager::VERSION")"
echo ""
echo "Working directory: /root/ksm-tutorial"
