#!/bin/bash

# Step 7 checks: whole folder

fail() { echo "❌ $1"; [ -n "$2" ] && echo "   $2"; exit 1; }
ok() { echo "✅ $1"; }

kubectl wait --for=condition=Ready pod/whole-folder --timeout=30s >/dev/null 2>&1 \
  || fail "Pod whole-folder is not ready" "Check the folder name. Details: kubectl logs whole-folder -c keeper-secrets-init"
kubectl exec whole-folder -c app -- ls /keeper/secrets/all/demo-db.json >/dev/null 2>&1 \
  || fail "whole-folder did not receive demo-db.json" "Make sure [FOLDER NAME] is the folder that contains demo-db"
ok "whole-folder received every record in the folder"
echo "🎉 All Step 7 checks passed! You're done."
