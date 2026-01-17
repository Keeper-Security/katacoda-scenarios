# Step 3: Deploy Scaled Gateway to Kubernetes

**Learning Objective**: Deploy 3 Keeper Gateway instances to Kubernetes using a single manifest with the same configuration.

## What You'll Learn
- How to create a Kubernetes deployment manifest for Keeper Gateway
- How to configure gateway scaling in Kubernetes (3 replicas)
- How to deploy MySQL as a test target database
- How to verify all gateway instances connected to Keeper

## Why Kubernetes for Gateway Scaling?

### **Business Benefits**:
- **Auto-Healing**: Kubernetes restarts failed pods automatically
- **Zero Downtime**: Rolling updates don't interrupt service
- **Resource Management**: CPU and memory limits prevent resource exhaustion
- **Cost Optimization**: Scale down during off-peak hours

### **Technical Benefits**:
- **Declarative Configuration**: Infrastructure as code
- **Pod Anti-Affinity**: Spread instances across nodes for better availability
- **Horizontal Pod Autoscaler**: Automatically scale based on CPU/memory
- **Health Checks**: Automatic detection and restart of unhealthy pods

---

## 1. Create the Deployment Manifest

Let's create an all-in-one Kubernetes manifest with everything we need:

```bash
cat > gateway-scaled.yaml <<'EOF'
---
# Namespace for scaled gateway testing
apiVersion: v1
kind: Namespace
metadata:
  name: keeper-gateway-scaled
  labels:
    name: keeper-gateway-scaled
    environment: demo

---
# Secret containing gateway configuration
apiVersion: v1
kind: Secret
metadata:
  name: keeper-gateway-config
  namespace: keeper-gateway-scaled
type: Opaque
stringData:
  # REPLACE THIS with your base64 config from Step 1!
  GATEWAY_CONFIG: PASTE_YOUR_BASE64_CONFIG_HERE
  ACCEPT_EULA: "Y"

---
# Deployment: 3 Gateway replicas with same config
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keeper-gateway
  namespace: keeper-gateway-scaled
  labels:
    app: keeper-gateway
spec:
  replicas: 3  # Run 3 instances!

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Keep at least 2 running during updates

  selector:
    matchLabels:
      app: keeper-gateway

  template:
    metadata:
      labels:
        app: keeper-gateway
    spec:
      # Spread pods across nodes
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - keeper-gateway
              topologyKey: kubernetes.io/hostname

      containers:
      - name: keeper-gateway
        image: keeper/gateway:1.7.6
        imagePullPolicy: Always

        env:
        - name: ACCEPT_EULA
          valueFrom:
            secretKeyRef:
              name: keeper-gateway-config
              key: ACCEPT_EULA
        - name: GATEWAY_CONFIG
          valueFrom:
            secretKeyRef:
              name: keeper-gateway-config
              key: GATEWAY_CONFIG
        - name: KEEPER_GATEWAY_HEALTH_CHECK_ENABLED
          value: "true"
        - name: KEEPER_GATEWAY_HEALTH_CHECK_HOST
          value: "0.0.0.0"
        - name: KEEPER_GATEWAY_HEALTH_CHECK_USE_SSL
          value: "false"
        - name: KEEPER_GATEWAY_HEALTH_CHECK_AUTH_TOKEN
          value: "k8s-health-check-token"
        - name: KEEPER_GATEWAY_LOG_LEVEL
          value: "debug"

        ports:
        - name: health
          containerPort: 8099

        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"

        livenessProbe:
          httpGet:
            path: /health
            port: 8099
            httpHeaders:
            - name: Authorization
              value: Bearer k8s-health-check-token
          initialDelaySeconds: 60
          periodSeconds: 30

        readinessProbe:
          httpGet:
            path: /health
            port: 8099
            httpHeaders:
            - name: Authorization
              value: Bearer k8s-health-check-token
          initialDelaySeconds: 30
          periodSeconds: 10

---
# Service for health checks
apiVersion: v1
kind: Service
metadata:
  name: keeper-gateway
  namespace: keeper-gateway-scaled
spec:
  type: ClusterIP
  selector:
    app: keeper-gateway
  ports:
  - name: health
    port: 8099
    targetPort: 8099

---
# MySQL: Test target database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: keeper-gateway-scaled
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql/mysql-server:8.0
        env:
        - name: MYSQL_ROOT_HOST
          value: "%"
        - name: MYSQL_ROOT_PASSWORD
          value: "F6TpKyxHX73EldkDx1x9"
        - name: MYSQL_DATABASE
          value: "salesdb"
        - name: MYSQL_USER
          value: "sqluser"
        - name: MYSQL_PASSWORD
          value: "MUQtQ7X66OWqZdP2vZ8k"
        ports:
        - containerPort: 3306
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"

---
# MySQL Service
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: keeper-gateway-scaled
spec:
  type: ClusterIP
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
EOF
```

**Note**: Copy the full YAML content above and run it in your terminal, or use the Killercoda editor to create the file.

**✅ Expected Output**: `gateway-scaled.yaml` file created.

---

## 2. Edit the Configuration (REQUIRED!)

**⚠️ CRITICAL**: You must replace the placeholder with your actual base64 config from Step 1!

Open the file in the editor:

```bash
vi gateway-scaled.yaml
```

**Find this line** (around line 22):
```yaml
GATEWAY_CONFIG: PASTE_YOUR_BASE64_CONFIG_HERE
```

**Replace with your actual base64** (from Step 1):
```yaml
GATEWAY_CONFIG: eyJob3N0bmFtZSI6ImtlZXBlcnNlY3VyaXR5LmNvbSIsImNsaWVudElk...
```

**Save and exit**: Press `ESC`, then type `:wq` and press Enter.

**💡 Verification**:

`grep "GATEWAY_CONFIG:" gateway-scaled.yaml`{{execute}}

**✅ Expected**: Should show your actual base64 config (not the placeholder).

---

## 3. Deploy to Kubernetes

Now deploy the manifest to create all resources:

`kubectl apply -f gateway-scaled.yaml`{{execute}}

**✅ Expected Output**:
```
namespace/keeper-gateway-scaled created
secret/keeper-gateway-config created
deployment.apps/keeper-gateway created
service/keeper-gateway created
deployment.apps/mysql created
service/mysql created
```

**🚀 What Just Happened?**
1. Created namespace: `keeper-gateway-scaled`
2. Created secret with gateway config (base64)
3. Created deployment with **3 gateway replicas**
4. Created service for health checks (port 8099)
5. Created MySQL deployment (1 replica) as test target
6. Created MySQL service (port 3306)

---

## 4. Watch Pods Starting Up

Monitor the deployment progress:

`kubectl get pods -n keeper-gateway-scaled -w`{{execute}}

**Expected Pod Lifecycle**:
```
NAME                              READY   STATUS              RESTARTS   AGE
keeper-gateway-79c6f9f699-abcd    0/1     ContainerCreating   0          5s
keeper-gateway-79c6f9f699-efgh    0/1     ContainerCreating   0          5s
keeper-gateway-79c6f9f699-ijkl    0/1     ContainerCreating   0          5s
mysql-9c65ccf57-mnop              0/1     ContainerCreating   0          5s

[After ~30 seconds]
keeper-gateway-79c6f9f699-abcd    1/1     Running             0          40s
keeper-gateway-79c6f9f699-efgh    1/1     Running             0          40s
keeper-gateway-79c6f9f699-ijkl    1/1     Running             0          40s
mysql-9c65ccf57-mnop              1/1     Running             0          40s
```

**Press Ctrl+C** to stop watching.

**✅ Success Indicators**:
- All 3 gateway pods: `Running` status
- MySQL pod: `Running` status
- READY column: `1/1` for all pods

---

## 5. Verify All Pods Are Running

Check the final state:

`kubectl get pods -n keeper-gateway-scaled`{{execute}}

**✅ Expected Output**:
```
NAME                              READY   STATUS    RESTARTS   AGE
keeper-gateway-79c6f9f699-abcd    1/1     Running   0          2m
keeper-gateway-79c6f9f699-efgh    1/1     Running   0          2m
keeper-gateway-79c6f9f699-ijkl    1/1     Running   0          2m
mysql-9c65ccf57-mnop              1/1     Running   0          2m
```

**Get Pod Names** (we'll need these for checking logs):

`kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name`{{execute}}

**Expected**: List of 3 pod names.

---

## 6. Check Instance IDs

Each gateway pod generates a unique 6-character instance ID on startup. Let's find them:

**Check Pod 1**:
```bash
POD1=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | head -1)
kubectl logs -n keeper-gateway-scaled $POD1 | grep "Generated gateway instance ID"
```

**Check Pod 2**:
```bash
POD2=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | sed -n '2p')
kubectl logs -n keeper-gateway-scaled $POD2 | grep "Generated gateway instance ID"
```

**Check Pod 3**:
```bash
POD3=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | tail -1)
kubectl logs -n keeper-gateway-scaled $POD3 | grep "Generated gateway instance ID"
```

**✅ Expected Output** (example):
```
2026-01-15 22:01:46,800  drconnection  DEBUG: Generated gateway instance ID: XGMRPR
2026-01-15 23:01:59,647  drconnection  DEBUG: Generated gateway instance ID: MWUEEE
2026-01-15 23:03:20,192  drconnection  DEBUG: Generated gateway instance ID: SQRXZT
```

**🎉 Success**: 3 different instance IDs means scaling is working!

---

## 7. Verify Connection to Keeper

Check that all pods connected to Keeper successfully:

**Quick check all pods**:

`kubectl logs -n keeper-gateway-scaled -l app=keeper-gateway --tail=100 | grep "Gateway is online"`{{execute}}

**✅ Expected**: Should see "Gateway is online" messages from all 3 pods.

---

## 8. Verify in Commander (IMPORTANT!)

Switch back to Commander and check the gateway status:

```bash
keeper shell
```

Then run:
```
pam gateway list
```

**✅ Expected Output**:
```
Test Gateway Scaling App (XLi65XXWgBUkuUhf2ERfeg)
  Test Gateway Scaling Gateway 1    wM6mqZ_hQhWtLU225UNDcw  ONLINE (3 instances)
    |- Instance 1 (connected: 2026-01-15 14:01:46)        [NAT_IP]  ONLINE  1.7.6
    |- Instance 2 (connected: 2026-01-15 15:04:00)        [NAT_IP]  ONLINE  1.7.6
    |- Instance 3 (connected: 2026-01-15 15:04:20)        [NAT_IP]  ONLINE  1.7.6
```

**🎉 Perfect!** All 3 instances are **ONLINE** and connected to Keeper!

---

## 🔍 What This Deployment Does

### **Kubernetes Resources Created**

| Resource | Count | Purpose |
|----------|-------|---------|
| Namespace | 1 | Isolated environment: `keeper-gateway-scaled` |
| Secret | 1 | Gateway config (base64) + EULA acceptance |
| Deployment (Gateway) | 1 | Manages 3 gateway pod replicas |
| Deployment (MySQL) | 1 | Test database target (1 replica) |
| Service (Gateway) | 1 | Health check endpoint (ClusterIP :8099) |
| Service (MySQL) | 1 | Database access (ClusterIP :3306) |

### **Gateway Pod Configuration**

Each of the 3 gateway pods:
- **Image**: `keeper/gateway:1.7.6`
- **Instance ID**: Auto-generated on startup (6 chars, e.g., XGMRPR)
- **Memory**: 512Mi request, 1Gi limit
- **CPU**: 250m request, 500m limit
- **Health Checks**: HTTP GET /health on port 8099
- **Configuration**: Same GATEWAY_CONFIG secret (shared)

### **How Instance IDs Work**

**On Pod Startup**:
1. Gateway container starts
2. Gateway code runs: `generate_instance_id()` (Python)
   ```python
   def generate_instance_id(length=6):
       alphabet = string.ascii_uppercase
       return ''.join(secrets.choice(alphabet) for _ in range(length))
   ```
3. Result: Random 6-character ID (e.g., **XGMRPR**)
4. Gateway sends `InstanceId: XGMRPR` header in all Keeper API calls
5. Keeper tracks this instance in the gateway pool

**Example Instance IDs**:
- Pod 1: `XGMRPR`
- Pod 2: `MWUEEE`
- Pod 3: `SQRXZT`

**🔒 Why Random IDs?**
- Prevents collisions if pods restart
- No database coordination needed
- Simple and stateless
- Keeper handles duplicate detection

---

## 🔍 Understanding the Architecture

### **Before Deployment (Step 2)**:
```
┌──────────────────┐
│ Keeper Backend   │
│ (API Database)   │
│                  │
│ Gateway UID: ... │
│ maxInstances: 3  │ ← Configured in Step 2
└──────────────────┘
```

### **After Deployment (Step 3)**:
```
┌──────────────────────────────────────────────┐
│            Keeper (Load Balancer)           │
│  Gateway Pool: wM6mqZ_hQhWtLU225UNDcw        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐     │
│  │ XGMRPR  │  │ MWUEEE  │  │ SQRXZT  │     │
│  │ ✅ ONLINE│  │ ✅ ONLINE│  │ ✅ ONLINE│     │
│  └────┬────┘  └────┬────┘  └────┬────┘     │
└───────┼───────────┼───────────┼────────────┘
        │           │           │
┌───────▼───────────▼───────────▼─────────────┐
│      Kubernetes Cluster (3 Nodes)           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Pod 1    │  │ Pod 2    │  │ Pod 3    │  │
│  │ XGMRPR   │  │ MWUEEE   │  │ SQRXZT   │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       └─────────────┼─────────────┘         │
│                     │                       │
│            ┌────────▼────────┐              │
│            │  MySQL Server   │              │
│            │  mysql:3306     │              │
│            └─────────────────┘              │
└──────────────────────────────────────────────┘
```

---

## 🔒 Security Best Practices

### **Configuration Security**

**What's in GATEWAY_CONFIG?**
```json
{
  "hostname": "keepersecurity.com",
  "clientId": "[ENCRYPTED_CLIENT_ID]",
  "privateKey": "[ENCRYPTED_PRIVATE_KEY]",
  "appKey": "[ENCRYPTED_APP_KEY]",
  "appOwnerPublicKey": "[PUBLIC_KEY]"
}
```

**Security Layers**:
1. **Base64 Encoding**: Configuration is base64 encoded
2. **Kubernetes Secret**: Stored in etcd (encrypted at rest)
3. **Private Keys**: Never leave the gateway pod
4. **TLS**: All communication with Keeper over HTTPS
5. **Authentication**: Each request signed with gateway credentials

**⚠️ Production Best Practices**:
- Use **external secret stores** (AWS Secrets Manager, HashiCorp Vault)
- Enable **Kubernetes RBAC** to restrict secret access
- Implement **Network Policies** to limit pod communication
- Use **private container registries** for gateway images
- Enable **Pod Security Standards** (restricted mode)

---

## Troubleshooting

### Issue: Pods in CrashLoopBackOff

**Symptom**: Pods keep restarting with errors.

**Check logs**:

`kubectl logs -n keeper-gateway-scaled deployment/keeper-gateway --tail=50`{{execute}}

**Common Causes**:
1. **Invalid GATEWAY_CONFIG**: Verify you pasted the correct base64 config
2. **Missing maxInstances**: Run `pam gateway set-max-instances` (Step 2)
3. **Network Issues**: Check firewall allows access to keepersecurity.com:443

**Solution for "Maximum controllers connected"**:
```bash
# Go back to Step 2 and set maxInstances=3
keeper shell
pam gateway set-max-instances -g <YOUR_GATEWAY_UID> -m 3
```

---

### Issue: MySQL Not Starting

**Check MySQL logs**:

`kubectl logs -n keeper-gateway-scaled deployment/mysql`{{execute}}

**Common Causes**:
- Resource limits too low
- Image pull errors

**Solution**:
```bash
# Check pod events
kubectl describe pod -n keeper-gateway-scaled -l app=mysql
```

---

## 🔍 Deployment Architecture Details

### **Replica Strategy: RollingUpdate**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1         # Allow 1 extra pod during update (total: 4)
    maxUnavailable: 0   # Keep all 3 pods running during update
```

**Why RollingUpdate?**
- **Zero Downtime**: At least 2-3 pods always running
- **Gradual Rollout**: Updates 1 pod at a time
- **Automatic Rollback**: Kubernetes stops if new pods fail health checks

**Update Timeline**:
```
[T+0s]   Start update
[T+10s]  Create 4th pod (maxSurge=1)
[T+40s]  4th pod ready, kill 1st old pod
[T+70s]  Create 5th pod, kill 2nd old pod
[T+100s] All 3 new pods running, update complete
```

**User Impact**: **Zero downtime** - requests always handled.

---

### **Pod Anti-Affinity: Spread Across Nodes**

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
```

**Why Pod Anti-Affinity?**
- **Node Failure Protection**: If one node dies, other gateways keep running
- **Better Resource Distribution**: Spreads CPU/memory load across cluster
- **Network Isolation**: Reduces blast radius of network issues

**Example Distribution**:
- Node 1: keeper-gateway-abcd
- Node 2: keeper-gateway-efgh
- Node 3: keeper-gateway-ijkl

**Result**: Losing 1 node doesn't lose all gateways!

---

## 💡 Key Concepts

### **Shared Configuration, Unique Instances**

All 3 pods use the **same** GATEWAY_CONFIG, but Keeper sees them as **different instances** because:

| Property | Shared or Unique | Value |
|----------|------------------|-------|
| `controllerUid` | ✅ Shared | wM6mqZ_hQhWtLU225UNDcw |
| `clientId` | ✅ Shared | (from GATEWAY_CONFIG) |
| `privateKey` | ✅ Shared | (from GATEWAY_CONFIG) |
| `instanceId` | ❌ Unique | XGMRPR, MWUEEE, SQRXZT |
| `connectedOn` | ❌ Unique | Timestamp of each connection |
| `ipAddress` | ✅ Shared | NAT Gateway IP (same for all) |

### **MySQL Test Target**

The MySQL deployment provides a test database for verifying gateway connections:

**Connection Details**:
- **Hostname**: `mysql` (DNS name within namespace)
- **FQDN**: `mysql.keeper-gateway-scaled.svc.cluster.local`
- **Port**: `3306`
- **Database**: `salesdb`
- **Root Password**: `F6TpKyxHX73EldkDx1x9`
- **User**: `sqluser` / `MUQtQ7X66OWqZdP2vZ8k`

**⚠️ Test Credentials Only**: Never use these passwords in production!

---

## Next Steps

Deployment complete! In the next step, we'll:

1. **Create PAM Configuration** in the vault
2. **Create PAM User record** with MySQL root credentials
3. **Create PAM Database record** pointing to our MySQL server
4. **Test connections** through the scaled gateway

This will allow us to verify that Keeper is load balancing requests across all 3 gateway instances!
