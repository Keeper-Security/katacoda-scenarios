#!/bin/bash

# Step 6 checks: environment variables and Kubernetes Secret

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=Ready pod/envvars --timeout=30s >/dev/null 2>&1 || fail "Pod envvars is not ready"
kubectl logs envvars -c app 2>/dev/null | grep -q '^DB_LOGIN=' || fail "envvars did not receive DB_ environment variables"
ok "envvars received DB_ environment variables"
for k in POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB; do
  [ -n "$(kubectl get secret demo-db-secret -o jsonpath="{.data.$k}" 2>/dev/null)" ] || fail "Secret demo-db-secret has no $k key"
done
ok "Secret demo-db-secret has POSTGRES_USER, POSTGRES_PASSWORD and POSTGRES_DB"
kubectl wait --for=condition=Ready pod/k8s-secret-rotation --timeout=30s >/dev/null 2>&1 || fail "Pod k8s-secret-rotation is not ready"
[ -n "$(kubectl get secret demo-api-secret -o jsonpath='{.data.api_key}' 2>/dev/null)" ] \
  || fail "Secret demo-api-secret has no api_key" "Details: kubectl logs k8s-secret-rotation -c keeper-secrets-sidecar"
ok "Secret demo-api-secret is created and kept up to date by the sidecar"
echo "🎉 All Step 6 checks passed!"
