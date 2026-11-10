# Step 4: A Real App: Postgres and a Client

Now let's use the secrets for real. We'll start a Postgres database whose user and password come from Keeper, and an application that connects to it using the connection string from Step 3. Neither container knows anything about Keeper: they only read files.

## 1. Start the Database

The official Postgres image can read its credentials from files through `POSTGRES_USER_FILE` and `POSTGRES_PASSWORD_FILE`. We point those at files the Injector writes:

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-postgres
spec:
  replicas: 1
  selector:
    matchLabels: { app: demo-postgres }
  template:
    metadata:
      labels: { app: demo-postgres }
      annotations:                                   # annotations go on the POD template
        keeper.security/inject: "true"
        keeper.security/ksm-config: "keeper-credentials"
        keeper.security/init-only: "true"            # fetch once at startup; no sidecar needed
        keeper.security/secret-user: "demo-db[login]:/keeper/secrets/db-user"
        keeper.security/secret-pass: "demo-db[password]:/keeper/secrets/db-password"
    spec:
      containers:
        - name: postgres
          image: postgres:17
          env:
            - name: POSTGRES_USER_FILE               # Postgres reads the user name from this file
              value: /keeper/secrets/db-user
            - name: POSTGRES_PASSWORD_FILE           # ...and the password from this one
              value: /keeper/secrets/db-password
            - name: POSTGRES_DB
              value: orders
---
apiVersion: v1
kind: Service                                        # gives the database a stable name:
metadata:                                            # demo-postgres.default.svc.cluster.local
  name: demo-postgres
spec:
  selector: { app: demo-postgres }
  ports:
    - port: 5432
EOF
```{{execute}}

Notice that with a Deployment the annotations go under `spec.template.metadata`, so every pod the Deployment creates is injected. `init-only: "true"` is right for a database: it reads its password once, when it initializes.

```bash
kubectl rollout status deployment/demo-postgres --timeout=180s
```{{execute}}

## 2. Start the Application

The application reads the connection string from `/keeper/secrets/database-url` and tries to connect every 10 seconds:

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 1
  selector:
    matchLabels: { app: demo-app }
  template:
    metadata:
      labels: { app: demo-app }
      annotations:
        keeper.security/inject: "true"
        keeper.security/ksm-config: "keeper-credentials"
        keeper.security/refresh-interval: "30s"      # re-read Keeper every 30 seconds (used in Step 5)
        keeper.security/config: |
          secrets:
            - record: demo-db
              path: /keeper/secrets/database-url
              template: "postgresql://{{ .login }}:{{ .password | urlquery }}@{{ .host }}:{{ .port }}/{{ .database }}"
    spec:
      containers:
        - name: app
          image: postgres:17                         # used only for its psql client
          command: ["sh", "-c"]
          args:
            - |
              while true; do
                psql "$(cat /keeper/secrets/database-url)" -tAc "select 'connected to ' || current_database() || ' as ' || current_user" 2>&1
                sleep 10
              done
EOF
```{{execute}}

```bash
kubectl rollout status deployment/demo-app --timeout=180s
```{{execute}}

Give it a few seconds, then read the application's log:

```bash
sleep 15; kubectl logs deployment/demo-app -c app --tail=3
```{{execute}}

You should see `connected to orders as app_user`. The database and the application both got their credentials from Keeper, and neither has a password in its configuration, its image or a Kubernetes Secret.
