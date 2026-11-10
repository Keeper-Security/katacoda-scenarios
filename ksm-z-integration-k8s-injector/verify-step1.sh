#!/bin/bash

# Step 1 checks: Injector installed, credentials present, hello-keeper pod received demo-db

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=available --timeout=30s deployment -l app.kubernetes.io/name=keeper-injector -n keeper-security >/dev/null 2>&1 \
  || kubectl get pods -n keeper-security 2>/dev/null | grep -q "Running" \
  || fail "The Keeper Injector is not running" "Run: kubectl get pods -n keeper-security"
ok "Keeper Injector is running"
kubectl get secret keeper-credentials >/dev/null 2>&1 || fail "Secret keeper-credentials does not exist in the default namespace"
ok "Secret keeper-credentials exists"
kubectl wait --for=condition=Ready pod/hello-keeper --timeout=30s >/dev/null 2>&1 \
  || fail "Pod hello-keeper is not ready" "Details: kubectl logs hello-keeper -c keeper-secrets-init"
kubectl exec hello-keeper -c app -- grep -q '"login"' /keeper/secrets/demo-db.json 2>/dev/null \
  || fail "/keeper/secrets/demo-db.json is missing or empty" "Check the record title is exactly demo-db"
ok "Pod hello-keeper received demo-db from Keeper"
echo "🎉 All Step 1 checks passed!"
