#!/bin/bash

# Step 4 checks: the PushSecret wrote the Kubernetes value to Keeper

echo "🔍 Verifying the PushSecret..."

if ! kubectl get secret app-api-token >/dev/null 2>&1; then
    echo "❌ Secret app-api-token does not exist"
    exit 1
fi
echo "✅ Secret app-api-token exists"

if ! kubectl wait --for=condition=Ready --timeout=30s pushsecret/ksm-push-api-token >/dev/null 2>&1; then
    echo "❌ PushSecret ksm-push-api-token has not synced to Keeper"
    echo "   Run: kubectl get pushsecret ksm-push-api-token"
    echo "   Details: kubectl logs -n external-secrets deploy/external-secrets | grep ksm-push-api-token"
    echo "   Make sure the KSM application has Can Edit permission on the shared folder"
    exit 1
fi
echo "✅ PushSecret ksm-push-api-token synced to Keeper"

echo "🎉 All Step 4 checks passed! Check your Keeper Vault for the record k8s-generated-api-token."
