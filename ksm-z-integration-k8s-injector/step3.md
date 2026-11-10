# Step 3: Shape Secrets for Your App

Applications expect configuration in different shapes: a `.env` file, Java properties, or a single connection string. For anything beyond one value per file, the Injector takes a small YAML configuration in the `keeper.security/config` annotation.

## 1. Four Shapes From One Record

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: shapes
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/config: |
      secrets:
        - record: demo-db
          path: /keeper/secrets/db.env
          format: env
        - record: demo-db
          path: /keeper/secrets/db.properties
          format: properties
        - record: demo-db
          path: /keeper/secrets/login-and-password.json
          fields: [login, password]
        - record: demo-db
          path: /keeper/secrets/database-url
          template: "postgresql://{{ .login }}:{{ .password | urlquery }}@{{ .host }}:{{ .port }}/{{ .database }}"
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
EOF
```{{execute}}

Each entry under `secrets:` writes one file:

| Entry | What it produces |
|---|---|
| `format: env` | `KEY=value` lines, ready for `source` or a `.env` loader |
| `format: properties` | `key=value` lines for Java applications |
| `fields: [login, password]` | JSON with only the fields you list |
| `template: ...` | anything you like, built from the record's fields with Go templates; here a complete Postgres connection string |

In the template, `{{ .login }}`, `{{ .password }}` and so on are the record's fields and custom field labels. `urlquery` escapes special characters in the password so the URL stays valid. Other formats are `yaml`, `ini` and `raw`.

```bash
kubectl wait --for=condition=Ready pod/shapes --timeout=120s
```{{execute}}

```bash
kubectl exec shapes -c app -- sh -c 'for f in /keeper/secrets/*; do echo "== $f"; cat "$f"; echo; done'
```{{execute}}

The `database-url` file is a complete connection string assembled from five Keeper fields. In the next step a real application uses exactly this file to connect to a database.
