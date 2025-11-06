#!/bin/bash

apt update -qq && apt install -y -qq ruby3.2 ruby3.2-dev build-essential && gem install keeper_secrets_manager --no-document && ruby -e "require 'keeper_secrets_manager'; puts 'KSM Ruby SDK ready!'" || echo "Installation completed. Run: gem install keeper_secrets_manager"
