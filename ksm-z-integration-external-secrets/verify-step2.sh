#!/bin/bash

# Step 2 checks: the sample application is running and reads the synced secret

echo "🔍 Verifying the sample application..."

if ! kubectl get secret my-external-secrets-values >/dev/null 2>&1; then
    echo "❌ Secret my-external-secrets-values does not exist - complete Step 1 first"
    exit 1
fi
echo "✅ Secret my-external-secrets-values exists"

if ! kubectl wait --for=condition=available --timeout=30s deployment/my-deployment >/dev/null 2>&1; then
    echo "❌ Deployment my-deployment is not available"
    echo "   Run: kubectl get pods -l app=my-app"
    exit 1
fi
echo "✅ Deployment my-deployment is available"

if ! kubectl get service my-service >/dev/null 2>&1; then
    echo "❌ Service my-service does not exist"
    exit 1
fi
echo "✅ Service my-service exists"

echo "🎉 All Step 2 checks passed! The application is reading secrets from Keeper."
