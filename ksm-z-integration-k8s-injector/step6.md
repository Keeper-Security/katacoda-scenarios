# Step 6: Environment Variables and Kubernetes Secrets

Files in memory are the safest option and the Injector's default. Some applications can only read **environment variables**, and some tools expect a **Kubernetes Secret**. The Injector can produce both, per pod.

## 1. Environment Variables

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: envvars
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/inject-env-vars: "true"     # environment variables instead of files
    keeper.security/env-prefix: "DB_"           # optional prefix for every variable name
    keeper.security/secret: "demo-db"
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "env | grep ^DB_ | sort; sleep 3600"]
EOF
```{{execute}}

```bash
kubectl wait --for=condition=Ready pod/envvars --timeout=120s && kubectl logs envvars -c app
```{{execute}}

Every field of `demo-db` became a variable: `DB_LOGIN`, `DB_PASSWORD`, `DB_HOST` and so on.

Now look at the pod definition itself:

```bash
kubectl get pod envvars -o jsonpath='{range .spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```{{execute}}

> **Warning**: The values are written into the pod specification. Anyone who can read pods in this namespace can see them, and they are stored in etcd with the pod. Environment variables also never rotate: they are fixed when the container starts. Use this mode only for applications that cannot read files.

## 2. Kubernetes Secrets

Some workloads need a regular Kubernetes Secret, for example a third-party Helm chart that only accepts `secretKeyRef`. The Injector can create one, with key names of your choice:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: k8s-secret-mode
  annotations:
    keeper.security/inject: "true"
    keeper.security/ksm-config: "keeper-credentials"
    keeper.security/config: |
      secrets:
        - record: demo-db
          injectAsK8sSecret: true
          k8sSecretName: demo-db-secret
          k8sSecretKeys:
            login: POSTGRES_USER
            password: POSTGRES_PASSWORD
            database: POSTGRES_DB
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
EOF
```{{execute}}

`k8sSecretKeys` maps Keeper field names (left) to the key names you want in the Secret (right).

```bash
kubectl wait --for=condition=Ready pod/k8s-secret-mode --timeout=120s && kubectl describe secret demo-db-secret
```{{execute}}

The Secret `demo-db-secret` now exists with the keys `POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_DB`, and any other pod in the namespace can use it like any Kubernetes Secret.

> **Note**: The Secret is created when the pod is created and **stays after the pod is deleted**. Delete it yourself when it is no longer needed (`kubectl delete secret demo-db-secret`). Like all Kubernetes Secrets it is stored in etcd.

## Which Mode When?

| Mode | Where the secret lives | Rotates live | Use for |
|---|---|---|---|
| Files (default) | Pod memory only | Yes | Almost everything |
| Environment variables | Pod spec (etcd) | No, needs a pod restart | Apps that can only read env vars |
| Kubernetes Secret | Secret object (etcd) | With extra setup (see below) | Tools that require a Secret |

> **Keeping a Kubernetes Secret up to date**: add `keeper.security/k8s-secret-rotation: "true"` to a pod that uses the YAML form shown above (`injectAsK8sSecret` under `secrets:`), and run that pod with a ServiceAccount that is allowed to `get` and `update` that Secret. The sidecar then rewrites the Secret on every refresh. Without that permission the update is refused, and the Secret keeps its first values.
