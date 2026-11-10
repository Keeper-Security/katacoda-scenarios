# Step 1: Install and Hello World

## 1. Prepare Two Records in Your Vault

In the shared folder that is shared with your Secrets Manager Application, create these two records. The titles must match exactly, because the rest of the tutorial refers to them by title.

**Record 1: `demo-db`** (record type *Login*)

| Field | Value |
|---|---|
| Login | `app_user` |
| Password | any password |
| Custom field (Text) `host` | `demo-postgres.default.svc.cluster.local` |
| Custom field (Text) `port` | `5432` |
| Custom field (Text) `database` | `orders` |
| File attachment | any small JSON file, named `config.json` |

**Record 2: `demo-api`** (record type *Login*)

| Field | Value |
|---|---|
| Custom field (Hidden Field) `api_key` | any value, for example `sk-demo-12345` |

> **Tip**: The `host` value points at a database we will start inside this cluster in Step 4, so copy it exactly.

## 2. Install the Keeper Injector

The Injector is installed once per cluster with Helm, the Kubernetes package manager:

```bash
helm repo add keeper https://keeper-security.github.io/helm-charts
```{{execute}}

```bash
helm install keeper-injector keeper/keeper-injector \
  --version 0.12.1 \
  --namespace keeper-security \
  --create-namespace \
  --wait
```{{execute}}

What this does:
- `keeper/keeper-injector` is the Injector's official chart, pinned to version `0.12.1` so the tutorial behaves the same every time
- it is installed into its own namespace, `keeper-security`
- `--wait` returns once the Injector is running

Confirm the Injector is up. You should see two `keeper-injector` pods in `Running` state:

```bash
kubectl get pods -n keeper-security
```{{execute}}

## 3. Give the Injector Your Keeper Credentials

The Injector reads your Base64 KSM configuration from a Kubernetes Secret. Create it in the `default` namespace, where our pods will run:

> **Important**: Replace `[KSM CONFIG]` with your Base64 configuration string.

```bash
kubectl create secret generic keeper-credentials \
  --from-literal=config='[KSM CONFIG]'
```{{copy}}

> **Note**: This Secret must exist in **every namespace** whose pods use the Injector. Pods cannot reference a credentials Secret in another namespace.

## 4. Hello World

Here is the smallest possible pod that uses Keeper. Only the three `keeper.security/...` annotations are new; the rest is an ordinary pod:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hello-keeper
  annotations:
    keeper.security/inject: "true"                    # 1. turn the Injector on for this pod
    keeper.security/ksm-config: "keeper-credentials"  # 2. the Kubernetes Secret holding your KSM config (created above)
    keeper.security/secret: "demo-db"                 # 3. which record to fetch (by title)
spec:
  containers:
    - name: app
      image: busybox                                  # a tiny image with a shell
      command: ["sh", "-c", "sleep 3600"]             # just stay running so we can look inside
EOF
```{{execute}}

> **Two kinds of "secret"**: in this tutorial, a capitalised **Kubernetes Secret** is a Kubernetes object, like `keeper-credentials`, which holds the KSM configuration. The annotation `keeper.security/secret` (and `secrets`, `secret-<name>`) refers to a **record in your Keeper Vault**, such as `demo-db`.

Wait for the pod to start:

```bash
kubectl wait --for=condition=Ready pod/hello-keeper --timeout=120s
```{{execute}}

Look inside the pod. The record is waiting for your app as a JSON file:

```bash
kubectl exec hello-keeper -c app -- ls -l /keeper/secrets
```{{execute}}

```bash
kubectl exec hello-keeper -c app -- cat /keeper/secrets/demo-db.json
```{{execute}}

You should see the login, password and custom fields of `demo-db`. (`fileRef` is Keeper's internal ID of the attachment; Step 2 shows how to get the file itself.)

## 5. What Did the Injector Add?

We declared one container, `app`. Let's see what the pod actually contains:

```bash
kubectl get pod hello-keeper -o jsonpath='{range .spec.initContainers[*]}init container: {.name}{"\n"}{end}{range .spec.containers[*]}container:      {.name}{"\n"}{end}'
```{{execute}}

- `keeper-secrets-init` fetched the secret **before** your app started, so the file is there from the first second
- `keeper-secrets-sidecar` keeps it up to date while the pod runs (Step 5)
- `/keeper/secrets` is a **memory-backed** volume: the secret is never written to disk and disappears when the pod is deleted

Nothing about your application changed. It just reads a file.
