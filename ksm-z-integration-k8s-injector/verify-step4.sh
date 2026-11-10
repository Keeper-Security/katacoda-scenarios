#!/bin/bash

# Step 4 checks: Postgres and the client app connect with credentials from Keeper

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=available --timeout=30s deployment/demo-postgres >/dev/null 2>&1 \
  || fail "Deployment demo-postgres is not available" "Run: kubectl get pods -l app=demo-postgres"
ok "Postgres is running"
kubectl wait --for=condition=available --timeout=30s deployment/demo-app >/dev/null 2>&1 || fail "Deployment demo-app is not available"
kubectl logs deployment/demo-app -c app --tail=3 2>/dev/null | grep -q "connected to orders" \
  || fail "demo-app has not connected to the database yet" "Run: kubectl logs deployment/demo-app -c app --tail=5 (check the host custom field of demo-db)"
ok "demo-app is connected to the database"
echo "🎉 All Step 4 checks passed!"
