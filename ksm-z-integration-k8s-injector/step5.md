# Step 5: Rotation Without Restarts

The sidecar the Injector adds re-reads Keeper on a schedule (`keeper.security/refresh-interval`, 5 minutes by default) and updates the files **in place**. Applications that re-read their secret files pick up a new value without restarting.

## 1. Watch a Value Change Live

This pod prints its API key every 5 seconds, and its sidecar checks Keeper every 30 seconds:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: rotation-demo
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/refresh-interval: "30s"          # check Keeper every 30 seconds
    keeper.security/secret-apikey: "keeper://demo-api/custom_field/api_key:/keeper/secrets/api-key"
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "while true; do echo \"$(date +%T) api_key=$(cat /keeper/secrets/api-key)\"; sleep 5; done"]
EOF
```{{execute}}

```bash
kubectl wait --for=condition=Ready pod/rotation-demo --timeout=120s && kubectl logs rotation-demo -c app --tail=3
```{{execute}}

Now, in your Keeper Vault, **edit the `api_key` custom field of `demo-api`** to a new value and save. Within about 30 seconds the running pod prints the new value. Run this a few times to watch:

```bash
kubectl logs rotation-demo -c app --tail=4
```{{execute}}

Check that the container was never restarted (`RESTARTS` stays `0`):

```bash
kubectl get pod rotation-demo
```{{execute}}

## 2. Rotate the Database Password

Rotating a real database password means changing it in **two** places: the database itself and the Keeper record. In production, **KeeperPAM password rotation** does both for you. Here we do it by hand.

First choose a new password (letters and digits keep the shell quoting simple) and set it in Postgres:

```bash
export NEW_PASSWORD='Rotated2026demo'
kubectl exec deploy/demo-postgres -c postgres -- psql -U app_user -d orders -c "ALTER USER app_user PASSWORD '$NEW_PASSWORD'"
```{{execute}}

Now, in your Keeper Vault, **set the password of `demo-db` to `Rotated2026demo`** and save.

Watch the application. It may fail to connect for up to one refresh interval (it still has the old password), then it reconnects on its own:

```bash
sleep 40; kubectl logs deployment/demo-app -c app --tail=6
```{{execute}}

```bash
kubectl get pods -l app=demo-app
```{{execute}}

Same pod, `RESTARTS` still `0`: the application picked up the new password from the updated file.

> **Note**: Between the database change and the next refresh, the application uses the old password. Keep `refresh-interval` short for credentials that rotate, and let your application retry failed connections.
>
> **Note**: Rotation updates **files**. Environment variables (Step 6) are fixed when the container starts and only change when the pod is restarted.
