# Step 7: Whole Folders, Troubleshooting and Production Tips

## 1. Every Record in a Folder

Instead of naming records one by one, a pod can receive every record in a Keeper folder, one JSON file per record:

> **Important**: Replace `[FOLDER NAME]` with the name of the shared folder you shared with your Secrets Manager Application.

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: whole-folder
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/folder: "[FOLDER NAME]"            # folder path, e.g. "Production/Databases"
    keeper.security/folder-path: "/keeper/secrets/all"  # where to write the files
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
EOF
```{{copy}}

```bash
kubectl wait --for=condition=Ready pod/whole-folder --timeout=120s && kubectl exec whole-folder -c app -- ls /keeper/secrets/all
```{{execute}}

You should see `demo-db.json`, `demo-api.json` and any other record in that folder. Folder names are case-sensitive; nested folders are written as `Parent/Child`. You can also use `keeper.security/folder-uid` with the folder's UID.

## 2. When Something Goes Wrong

By default, if the Injector cannot fetch a secret, **the pod does not start**. That is deliberate: your application never runs with missing credentials. Let's make a mistake on purpose, a record title that does not exist:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: broken
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/secret: "this-record-does-not-exist"
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
EOF
```{{execute}}

After a few seconds the pod is stuck in `Init:Error`:

```bash
sleep 30; kubectl get pod broken
```{{execute}}

The reason is always in the **init container's log**:

```bash
kubectl logs broken -c keeper-secrets-init | grep -o '"error":"[^"]*"' | head -1
```{{execute}}

(If nothing is printed, the init container was just restarting; run the command again.) It says exactly what is wrong: `no record found with title: this-record-does-not-exist`. The same command shows other common mistakes in plain words, for example `KSM config is neither valid JSON nor base64` when the credentials Secret holds something other than a Base64 configuration. Some mistakes are caught even earlier: a pod whose output path is outside `/keeper/secrets` is rejected by `kubectl apply` itself, with a message saying which path is wrong.

Clean up the broken pod:

```bash
kubectl delete pod broken
```{{execute}}

## 3. Production Tips

| Topic | Recommendation |
|---|---|
| Credentials per namespace | The `keeper-credentials` Secret must exist in every namespace that uses the Injector. On EKS, GKE and AKS the Injector can instead read the KSM configuration from AWS Secrets Manager, GCP Secret Manager or Azure Key Vault with workload identity, so no credentials are stored in the cluster. |
| One application per team | Give each team or environment its own Secrets Manager Application and shared folder, so a namespace can only read the records it needs. |
| `init-only: "true"` | For workloads that read secrets once at startup (like the database in Step 4). Saves the sidecar's resources. |
| `refresh-interval` | Short (30s to 5m) for credentials that rotate; longer for static configuration. Every refresh is a request to Keeper. |
| `fail-on-error` | Keep the default (`true`): a pod whose secrets cannot be fetched does not start. A running pod keeps using its last values if Keeper is briefly unreachable. `"false"` lets a pod start **without** its secrets, so use it only for non-critical applications. |
| Output paths | Always under `/keeper/secrets`. |
| Corporate proxies | Behind SSL inspection (Zscaler and similar), add the proxy's CA with `keeper.security/ca-cert-configmap`. |
