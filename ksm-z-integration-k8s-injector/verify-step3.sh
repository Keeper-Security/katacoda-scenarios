#!/bin/bash

# Step 3 checks: formats and template

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=Ready pod/shapes --timeout=30s >/dev/null 2>&1 \
  || fail "Pod shapes is not ready" "Details: kubectl logs shapes -c keeper-secrets-init"
kubectl exec shapes -c app -- grep -q '^LOGIN=' /keeper/secrets/db.env 2>/dev/null || fail "db.env is missing or not in env format"
kubectl exec shapes -c app -- grep -q '^login=' /keeper/secrets/db.properties 2>/dev/null || fail "db.properties is missing or not in properties format"
kubectl exec shapes -c app -- grep -q '^postgresql://' /keeper/secrets/database-url 2>/dev/null || fail "database-url was not built from the template"
ok "shapes has db.env, db.properties, login-and-password.json and database-url"
echo "🎉 All Step 3 checks passed!"
