# Step 2: Pick Exactly What You Need

A whole record as JSON is a good start, but most applications want one value per file: a password file, an API key file, a certificate. In this step you'll pull single fields, a custom field and a file attachment, each into its own file.

## 1. One Pod, Five Secrets

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pick-fields
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    # A single field, short form:  RECORD[FIELD]:OUTPUT_FILE
    keeper.security/secret-dbpass: "demo-db[password]:/keeper/secrets/db-password"
    # The same idea using Keeper Notation:  keeper://RECORD/field/FIELD:OUTPUT_FILE
    keeper.security/secret-dbuser: "keeper://demo-db/field/login:/keeper/secrets/db-user"
    # A custom field, by its label:  keeper://RECORD/custom_field/LABEL:OUTPUT_FILE
    keeper.security/secret-apikey: "keeper://demo-api/custom_field/api_key:/keeper/secrets/api-key"
    keeper.security/secret-dbhost: "keeper://demo-db/custom_field/host:/keeper/secrets/db-host"
    # A file attachment:  RECORD:FILE_NAME:OUTPUT_FILE
    keeper.security/file-config: "demo-db:config.json:/keeper/secrets/config.json"
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
EOF
```{{execute}}

How to read these annotations:
- Each one starts with `keeper.security/secret-` or `keeper.security/file-` followed by **any name you like** (`dbpass`, `apikey`, ...). The name only has to be unique within the pod.
- The value says **what** to fetch and, after the last `:`, **where** to write it.
- Records can be referred to by **title** (as here) or by **record UID**.

```bash
kubectl wait --for=condition=Ready pod/pick-fields --timeout=120s
```{{execute}}

Print every file the pod received:

```bash
kubectl exec pick-fields -c app -- sh -c 'for f in /keeper/secrets/*; do echo "== $f"; cat "$f"; echo; done'
```{{execute}}

Each file holds just the raw value (no JSON), which is exactly what most applications expect for a password file or an API key file.

> **Important**: Output files must be **inside `/keeper/secrets`**. That is the only directory shared with your containers. A path elsewhere, such as `/app/secrets/db-pass`, makes the init container fail with `read-only file system` and the pod never starts.

## 2. Several Whole Records at Once

To fetch several records as JSON files, list their titles in one annotation:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: multi
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/secrets: "demo-db, demo-api"   # note: "secrets", plural
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
EOF
```{{execute}}

```bash
kubectl wait --for=condition=Ready pod/multi --timeout=120s && kubectl exec multi -c app -- ls /keeper/secrets
```{{execute}}

You get one file per record: `demo-db.json` and `demo-api.json`.
