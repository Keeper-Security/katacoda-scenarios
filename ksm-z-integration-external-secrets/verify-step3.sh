#!/bin/bash

# Step 3 checks: custom field and file attachment synced and used by a pod

echo "🔍 Verifying custom fields and files..."

if ! kubectl wait --for=condition=Ready --timeout=30s externalsecret/ksm-custom-and-files >/dev/null 2>&1; then
    echo "❌ ExternalSecret ksm-custom-and-files has not synced from Keeper"
    echo "   Check the custom field label (api_key) and the file name in the vault"
    echo "   Details: kubectl logs -n external-secrets deploy/external-secrets | grep ksm-custom-and-files"
    exit 1
fi
echo "✅ ExternalSecret ksm-custom-and-files synced"

for key in api-key app-file; do
    if [ -z "$(kubectl get secret my-app-extras -o jsonpath="{.data.$key}" 2>/dev/null)" ]; then
        echo "❌ Secret my-app-extras has no '$key' value"
        exit 1
    fi
done
echo "✅ Secret my-app-extras contains api-key and app-file"

if ! kubectl get pod extras-demo -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Succeeded; then
    echo "❌ Pod extras-demo has not completed"
    echo "   Run: kubectl logs extras-demo"
    exit 1
fi
echo "✅ Pod extras-demo read the custom field and the file"

echo "🎉 All Step 3 checks passed!"
