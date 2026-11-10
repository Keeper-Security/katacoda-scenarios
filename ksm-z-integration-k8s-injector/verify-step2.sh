#!/bin/bash

# Step 2 checks: single fields, custom field, file attachment, multiple records

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=Ready pod/pick-fields --timeout=30s >/dev/null 2>&1 \
  || fail "Pod pick-fields is not ready" "Details: kubectl logs pick-fields -c keeper-secrets-init"
for f in db-password db-user api-key db-host config.json; do
  [ -n "$(kubectl exec pick-fields -c app -- cat /keeper/secrets/$f 2>/dev/null)" ] \
    || fail "/keeper/secrets/$f is missing or empty in pick-fields" "Check the custom field labels and the attachment name config.json"
done
ok "pick-fields received db-password, db-user, api-key, db-host and config.json"
kubectl wait --for=condition=Ready pod/multi --timeout=30s >/dev/null 2>&1 || fail "Pod multi is not ready"
kubectl exec multi -c app -- ls /keeper/secrets/demo-db.json /keeper/secrets/demo-api.json >/dev/null 2>&1 \
  || fail "Pod multi did not receive both demo-db.json and demo-api.json"
ok "multi received demo-db.json and demo-api.json"
echo "🎉 All Step 2 checks passed!"
