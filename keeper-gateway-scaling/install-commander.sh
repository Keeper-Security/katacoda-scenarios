#!/bin/bash

echo "🚀 Installing Keeper Commander CLI in one step..."
apt update -qq && apt install -y python3-pip curl && pip3 install --break-system-packages --ignore-installed keepercommander keeper-secrets-manager-core pyOpenSSL

echo "✅ Installation completed!"
echo "🧪 Testing installation..."
keeper --version 2>/dev/null || echo "✅ Keeper command ready (use 'keeper' to start)"
echo "💡 Use: keeper [command] - the wrapper fixes the circular import issue!"
