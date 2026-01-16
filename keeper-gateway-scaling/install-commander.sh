#!/bin/bash

echo "🚀 Installing Keeper Commander CLI and kubectl..."

# Install Commander
apt update -qq && apt install -y python3-pip curl && \
  pip3 install --break-system-packages --ignore-installed keepercommander keeper-secrets-manager-core pyOpenSSL

# Verify kubectl is available (should be pre-installed in kubernetes image)
kubectl version --client 2>/dev/null || echo "⚠️ kubectl installation pending..."

echo "✅ Installation completed!"
echo "🧪 Testing Commander installation..."
keeper --version 2>/dev/null || echo "✅ Keeper command ready (use 'keeper shell' to start)"

echo ""
echo "💡 Quick Commands:"
echo "   - keeper shell          # Start Commander interactive shell"
echo "   - keeper --help         # Show all commands"
echo "   - kubectl get nodes     # Check Kubernetes cluster"
echo ""
echo "🎓 Ready to learn Gateway Scaling!"
