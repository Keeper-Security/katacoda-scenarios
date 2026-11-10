#!/bin/bash

# Step 5 checks: rotation without restarts

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=Ready pod/rotation-demo --timeout=30s >/dev/null 2>&1 || fail "Pod rotation-demo is not ready"
[ "$(kubectl get pod rotation-demo -o jsonpath='{.status.containerStatuses[?(@.name=="app")].restartCount}')" = "0" ] \
  || fail "rotation-demo was restarted; rotation should not need a restart"
ok "rotation-demo is still running without restarts"
kubectl logs deployment/demo-app -c app --tail=2 2>/dev/null | grep -q "connected to orders" \
  || fail "demo-app is not connected" "Make sure the password of demo-db in Keeper matches the one set in Postgres, then wait 30 seconds"
ok "demo-app is connected with the rotated password"
echo "🎉 All Step 5 checks passed!"
