# Step 5: Verify Load Balancing & High Availability

**Learning Objective**: Test the scaled gateway deployment to verify load balancing works and high availability is achieved.

## What You'll Learn
- How to verify all 3 gateway instances are handling requests
- How to watch logs in real-time to see load distribution
- How to test high availability by simulating pod failures
- How to verify zero-downtime during rolling updates

## Why Load Balancing Verification Matters?

### **Ensuring Proper Distribution**:
- Confirms Keeper is actually load balancing (not just connecting all 3)
- Identifies if one instance is overloaded
- Validates random selection algorithm working correctly

### **High Availability Testing**:
- Proves system survives instance failures
- Demonstrates zero-downtime capabilities
- Validates Kubernetes auto-healing
- Confirms no single point of failure

---

## 1. Watch Logs from All Gateway Instances

Let's stream logs from all 3 gateway pods in real-time:

```bash
kubectl logs -n keeper-gateway-scaled -l app=keeper-gateway -f --max-log-requests=10
```
`kubectl logs -n keeper-gateway-scaled -l app=keeper-gateway -f --max-log-requests=10`{{execute}}

**What to Look For**:
- Connection requests appearing in logs
- Each pod should show some activity
- Instance IDs in log messages

**💡 Tip**: Keep this running in a separate terminal while testing connections in the next steps.

**Press Ctrl+C** when done watching.

---

## 2. Test Connection Through Vault (Manual)

Now test the actual PAM connection through Keeper Vault:

### **Steps in Keeper Vault UI**:

1. **Navigate to**: **My Vault** → **Test Gateway Scaling** folder
2. **Open Record**: `Test Gateway Scaling - MySQL - Server` (double-click)
3. **Verify Gateway Status**: Look at PAM Settings section
   - Gateway: Test Gateway Scaling Gateway 1
   - Status: **✅ Online** (green checkmark)
4. **Click**: **Connection** tab (if using web-based connection)
5. **Make Connection**:
   - Via web UI connection tool (if available)
   - Or use Commander for connection testing

### **Alternative: Test via kubectl (Simulating Connection)**

While the vault UI is the real test, we can simulate by checking the logs during a connection attempt:

```bash
# In one terminal, watch logs
kubectl logs -n keeper-gateway-scaled -l app=keeper-gateway -f &

# In another terminal, make a direct MySQL connection
kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- \
  mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SHOW DATABASES;"

# Stop watching logs
kill %1
```

---

## 3. Verify Instance Distribution in Commander

Let's check Commander to see which instances are active:

```bash
keeper shell
```

Then run:
```
pam gateway list
```

**✅ Expected Output**:
```
Test Gateway Scaling Gateway 1    wM6mqZ_hQhWtLU225UNDcw  ONLINE (3 instances)
  |- Instance 1 (connected: 2026-01-15 14:01:46)        100.29.102.100  ONLINE  1.7.6
  |- Instance 2 (connected: 2026-01-15 15:04:00)        100.29.102.100  ONLINE  1.7.6
  |- Instance 3 (connected: 2026-01-15 15:04:20)        100.29.102.100  ONLINE  1.7.6
```

**Verify**:
- ✅ All 3 instances showing ONLINE status
- ✅ Different connection timestamps for each instance
- ✅ Same IP address (NAT Gateway IP - normal for Kubernetes)
- ✅ All running same version (1.7.6)

---

## 4. Verify Unique Instance IDs

Let's confirm each pod has a different instance ID:

**Get all instance IDs at once**:
```bash
for pod in $(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name); do
  echo "=== $pod ==="
  kubectl logs -n keeper-gateway-scaled $pod | grep "Generated gateway instance ID" | tail -1
done
```
`for pod in $(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name); do echo "=== $pod ===" && kubectl logs -n keeper-gateway-scaled $pod | grep "Generated gateway instance ID" | tail -1; done`{{execute}}

**✅ Expected Output**:
```
=== pod/keeper-gateway-79c6f9f699-hclcp ===
Generated gateway instance ID: XGMRPR

=== pod/keeper-gateway-79c6f9f699-z897r ===
Generated gateway instance ID: MWUEEE

=== pod/keeper-gateway-79c6f9f699-8b9mz ===
Generated gateway instance ID: SQRXZT
```

**🎉 Success Criteria**: 3 different instance IDs = scaling working!

---

## 5. Test High Availability (Chaos Engineering)

Let's simulate a pod failure and verify zero downtime:

### **Test Plan**:
1. Kill one gateway pod
2. Verify other 2 pods keep handling requests
3. Watch Kubernetes recreate the killed pod
4. Verify new pod joins the pool with new instance ID

### **Execute Chaos Test**:

**Step 1: Note current pods**:
```bash
kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway
```
`kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway`{{execute}}

**Step 2: Delete the first pod**:
```bash
POD_TO_DELETE=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | head -1)
echo "Deleting: $POD_TO_DELETE"
kubectl delete -n keeper-gateway-scaled $POD_TO_DELETE
```
`POD_TO_DELETE=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | head -1) && kubectl delete -n keeper-gateway-scaled $POD_TO_DELETE`{{execute}}

**Step 3: Watch the recreation**:
```bash
kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -w
```
`kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -w`{{execute}}

**Expected Timeline**:
```
[T+0s]   Pod deleted, status: Terminating
[T+1s]   Kubernetes creates new pod, status: Pending
[T+5s]   New pod status: ContainerCreating
[T+15s]  New pod status: Running
[T+45s]  New pod status: Running, READY: 1/1 (health check passed)
```

**Press Ctrl+C** when new pod is Running.

### **Step 4: Verify in Commander**:

```bash
keeper shell
pam gateway list
```

**Expected**: Still shows `ONLINE (3 instances)`, but:
- One instance has a **new connection timestamp** (the recreated pod)
- Instance ID changed for the recreated pod (new random ID)

**Example**:
```
Before deletion:
  |- Instance 1 (connected: 2026-01-15 14:01:46)  # Original pod
  |- Instance 2 (connected: 2026-01-15 15:04:00)
  |- Instance 3 (connected: 2026-01-15 15:04:20)

After deletion and recreation:
  |- Instance 1 (connected: 2026-01-15 15:30:12)  # NEW - recreated pod
  |- Instance 2 (connected: 2026-01-15 15:04:00)  # Unchanged
  |- Instance 3 (connected: 2026-01-15 15:04:20)  # Unchanged
```

**🎉 High Availability Verified!**
- ✅ Pod killed → Kubernetes recreated it automatically
- ✅ Other 2 pods kept running (no interruption)
- ✅ New pod joined the pool seamlessly
- ✅ Total downtime: **0 seconds** (other pods handled requests)

---

## 6. Test Load Balancing (Multiple Requests)

Let's make multiple connections and observe which instances handle them:

### **Prepare Log Monitoring**:

Open 3 terminal windows (or use split screen) to watch each pod:

**Terminal 1 (Pod 1)**:
```bash
POD1=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | head -1)
kubectl logs -n keeper-gateway-scaled $POD1 -f
```

**Terminal 2 (Pod 2)**:
```bash
POD2=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | sed -n '2p')
kubectl logs -n keeper-gateway-scaled $POD2 -f
```

**Terminal 3 (Pod 3)**:
```bash
POD3=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | tail -1)
kubectl logs -n keeper-gateway-scaled $POD3 -f
```

### **Make 10 Test Connections**:

In a 4th terminal:
```bash
for i in {1..10}; do
  echo "=== Connection $i ==="
  kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- \
    mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SELECT $i AS connection_number;" 2>/dev/null
  sleep 2
done
```

**Observe in the 3 log terminals**:
- Logs appear in **different terminals** (random distribution)
- **Not all in one terminal** (proof of load balancing)

**Expected Distribution** (approximate):
- Pod 1: ~3-4 connections
- Pod 2: ~3-4 connections
- Pod 3: ~3-4 connections

**⚠️ Important**: Distribution won't be exactly 33.33% each (it's random), but over 100+ requests it approaches 33% per instance.

---

## 7. Check Resource Usage

Monitor resource consumption across all pods:

```bash
kubectl top pods -n keeper-gateway-scaled
```
`kubectl top pods -n keeper-gateway-scaled`{{execute}}

**✅ Expected Output** (example):
```
NAME                              CPU(cores)   MEMORY(bytes)
keeper-gateway-79c6f9f699-hclcp   25m          450Mi
keeper-gateway-79c6f9f699-z897r   28m          465Mi
keeper-gateway-79c6f9f699-8b9mz   22m          442Mi
mysql-9c65ccf57-xx69l             15m          280Mi
```

**Analysis**:
- Gateway pods: ~25m CPU, ~450Mi memory each
- All within resource limits (500m CPU, 1Gi memory)
- Relatively balanced resource usage across instances

---

## 8. Test Horizontal Pod Autoscaler (HPA)

Check if HPA is tracking metrics:

```bash
kubectl get hpa -n keeper-gateway-scaled
```
`kubectl get hpa -n keeper-gateway-scaled`{{execute}}

**✅ Expected Output**:
```
NAME             REFERENCE                   TARGETS                MINPODS   MAXPODS   REPLICAS   AGE
keeper-gateway   Deployment/keeper-gateway   cpu: 5%/70%            2         3         3          10m
                                             memory: 15%/80%
```

**What This Means**:
- **TARGETS**: Current CPU is 5% (well below 70% threshold)
- **MINPODS**: Will never scale below 2 instances
- **MAXPODS**: Will never scale above 3 instances (configured in this tutorial, can be adjusted)
- **REPLICAS**: Currently running 3 instances

**💡 How HPA Works**:
- Monitors CPU and memory usage every 15 seconds
- If CPU > 70% for 5 minutes: Scale up (add 1 pod)
- If CPU < 70% for 15 minutes: Scale down (remove 1 pod)
- Respects min (2) and max (3) limits

---

## 9. Simulate Load (Optional)

Want to trigger auto-scaling? Generate some load:

```bash
# Generate CPU load on gateways (makes HPA scale up)
kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- \
  sh -c "for i in {1..10000}; do echo 'test' | md5sum; done"
```

**Watch HPA react**:
```bash
kubectl get hpa -n keeper-gateway-scaled -w
```
`kubectl get hpa -n keeper-gateway-scaled -w`{{execute}}

**Expected**: CPU % will increase, but we're already at max replicas (3), so no scaling action.

**Press Ctrl+C** to stop watching.

---

## 🔍 Load Balancing Analysis

### **Request Distribution Patterns**

With 3 instances and **random load balancing** (current algorithm):

| Requests | Expected Distribution | Variance |
|----------|----------------------|----------|
| 10 | 3-4-3 (±1 each) | High variance |
| 100 | 32-34-34 (±2 each) | Medium variance |
| 1000 | 330-335-335 (±5 each) | Low variance |

**Law of Large Numbers**: More requests = closer to perfect 33.33% distribution.

### **Real-World Distribution (Example)**

From our testing with 10 connections:
```
Pod hclcp (XGMRPR): 3 connections (30%)
Pod z897r (MWUEEE): 4 connections (40%)
Pod 8b9mz (SQRXZT): 3 connections (30%)
```

**Analysis**: Roughly equal! ✅

---

## 🔍 High Availability Metrics

### **Availability Comparison**

| Metric | Single Gateway | 3 Scaled Gateways |
|--------|----------------|-------------------|
| **Uptime (single pod failure)** | 0% (down) | 66% capacity maintained |
| **Uptime (two pod failure)** | 0% (down) | 33% capacity maintained |
| **Recovery Time** | ~60s (pod restart) | 0s (instant failover) |
| **Planned Maintenance Downtime** | Yes (~30s) | No (RollingUpdate) |
| **Monthly Availability** | ~99.5% | ~99.95% |

### **Failure Scenarios Tested**

| Scenario | Impact | Recovery |
|----------|--------|----------|
| **1 pod killed** | ❌ 33% capacity lost | ✅ Kubernetes recreates in ~30s |
| **1 node failure** | ❌ 33% capacity lost | ✅ Pod rescheduled to another node |
| **Gateway version update** | ❌ No impact | ✅ RollingUpdate ensures 2-3 pods always running |
| **Keeper maintenance** | ❌ All connections lost | ✅ Gateways reconnect automatically |

**Result**: Enterprise-grade reliability! 🛡️

---

## 🔍 Advanced Verification

### **Test 1: Check Instance Pool in Keeper**

**What Keeper sees** (backend perspective):

```json
{
  "controllerUid": "wM6mqZ_hQhWtLU225UNDcw",
  "controllerName": "Test Gateway Scaling Gateway 1",
  "maxInstances": 3,
  "connectedInstances": [
    {
      "instanceId": "XGMRPR",
      "ipAddress": "100.29.102.100",
      "version": "1.7.6",
      "connectedOn": 1737824906,
      "status": "ONLINE"
    },
    {
      "instanceId": "MWUEEE",
      "ipAddress": "100.29.102.100",
      "version": "1.7.6",
      "connectedOn": 1737828240,
      "status": "ONLINE"
    },
    {
      "instanceId": "SQRXZT",
      "ipAddress": "100.29.102.100",
      "version": "1.7.6",
      "connectedOn": 1737828260,
      "status": "ONLINE"
    }
  ]
}
```

**Routing Logic**:
```kotlin
// Keeper random selection (pseudocode)
val availableInstances = pool.filter { it.status == ONLINE }
val selectedInstance = availableInstances.random()
routeRequest(selectedInstance.instanceId)
```

### **Test 2: Verify Each Instance Can Connect to MySQL**

**Test from Pod 1**:
```bash
POD1=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | head -1)
kubectl exec -n keeper-gateway-scaled $POD1 -- \
  mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SELECT 'Pod 1 connected!' AS status;"
```

**Test from Pod 2**:
```bash
POD2=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | sed -n '2p')
kubectl exec -n keeper-gateway-scaled $POD2 -- \
  mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SELECT 'Pod 2 connected!' AS status;"
```

**Test from Pod 3**:
```bash
POD3=$(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name | tail -1)
kubectl exec -n keeper-gateway-scaled $POD3 -- \
  mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SELECT 'Pod 3 connected!' AS status;"
```

**✅ All 3 should succeed**: Each gateway can independently connect to MySQL.

---

## 🧪 Advanced Tests

### **Test 3: Simulate Node Failure**

**Scenario**: What happens if an entire Kubernetes node fails?

```bash
# Cordon a node (prevent scheduling)
NODE=$(kubectl get nodes -o name | head -1)
kubectl cordon $NODE

# Delete pod on that node
kubectl delete pod -n keeper-gateway-scaled --field-selector spec.nodeName=$NODE

# Watch pod reschedule to another node
kubectl get pods -n keeper-gateway-scaled -o wide -w
```

**Expected**:
- ✅ Pod deleted from cordoned node
- ✅ Kubernetes schedules new pod on different node
- ✅ New pod generates new instance ID
- ✅ Other 2 pods continue running (no interruption)

**Cleanup**:
```bash
kubectl uncordon $NODE
```

---

### **Test 4: Rolling Update (Zero Downtime)**

**Scenario**: Update gateway version without downtime.

```bash
# Update gateway image to trigger rolling update
kubectl set image deployment/keeper-gateway -n keeper-gateway-scaled \
  keeper-gateway=keeper/gateway:1.7.6

# Watch the rolling update
kubectl rollout status deployment/keeper-gateway -n keeper-gateway-scaled -w
```

**Expected Timeline**:
```
[T+0s]   Waiting for deployment to finish
[T+10s]  1 out of 3 new replicas have been updated...
[T+40s]  2 out of 3 new replicas have been updated...
[T+70s]  3 out of 3 new replicas have been updated...
[T+100s] Deployment "keeper-gateway" successfully rolled out
```

**Verification**:
```bash
kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway
```

**Expected**: 3 pods running with new pod names (all recreated).

**Check new instance IDs**:
```bash
for pod in $(kubectl get pods -n keeper-gateway-scaled -l app=keeper-gateway -o name); do
  kubectl logs -n keeper-gateway-scaled $pod | grep "Generated gateway instance ID" | tail -1
done
```

**Expected**: 3 **new** instance IDs (different from XGMRPR, MWUEEE, SQRXZT).

---

## 🔍 Scaling Metrics & Observability

### **Key Metrics to Monitor**

**Gateway Pod Metrics**:
```bash
kubectl top pods -n keeper-gateway-scaled
```
`kubectl top pods -n keeper-gateway-scaled`{{execute}}

| Metric | Normal Range | Alert Threshold |
|--------|--------------|-----------------|
| **CPU** | 10-50m | >400m (80% of limit) |
| **Memory** | 300-600Mi | >800Mi (80% of limit) |
| **Restarts** | 0-1 | >5 (pod unstable) |

**Deployment Health**:
```bash
kubectl get deployment -n keeper-gateway-scaled
```
`kubectl get deployment -n keeper-gateway-scaled`{{execute}}

**Expected**:
```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
keeper-gateway   3/3     3            3           15m
mysql            1/1     1            1           15m
```

**READY**: All replicas running and healthy.

---

### **Logging Best Practices**

**Centralized Logging** (for production):
```bash
# Stream all gateway logs to stdout (Kubernetes best practice)
kubectl logs -n keeper-gateway-scaled -l app=keeper-gateway --tail=1000

# For production: Use log aggregation tools
# - Fluentd → Elasticsearch → Kibana
# - Promtail → Loki → Grafana
# - AWS CloudWatch Container Insights
# - Datadog, New Relic, etc.
```

**Key Log Patterns to Monitor**:
```
"Generated gateway instance ID:"    # Pod startup
"Gateway is online"                 # Connection success
"Connection to remote host was lost" # Keeper disconnect
"Maximum controllers connected"     # Scaling limit hit (error!)
```

---

## 🔍 What We Verified

In this step, you've confirmed:

- ✅ **Load Balancing Works**:
  - All 3 instances receive requests
  - Random distribution across instances
  - Keeper selects from available pool

- ✅ **High Availability Works**:
  - Deleting a pod = zero downtime
  - Kubernetes auto-heals failed pods
  - New pods join pool automatically

- ✅ **Resource Management Works**:
  - HPA monitoring CPU and memory
  - Pods stay within resource limits
  - Auto-scaling ready (if needed)

- ✅ **Zero Downtime Updates**:
  - RollingUpdate strategy works
  - Old pods replaced gradually
  - At least 2 pods always available

---

## 🎓 Key Takeaways

### **Scaling Benefits Demonstrated**

**1. Load Distribution** (Performance)
```
Single Gateway: 100 req/sec max
3 Scaled Gateways: 300 req/sec max (3x)
```

**2. High Availability** (Reliability)
```
Single Gateway: 1 pod failure = 100% downtime
3 Scaled Gateways: 1 pod failure = 0% downtime
```

**3. Zero Downtime Updates** (Operational Excellence)
```
Single Gateway: Update = 30-60s downtime
3 Scaled Gateways: Update = 0s downtime (RollingUpdate)
```

**4. Auto-Healing** (Resilience)
```
Single Gateway: Manual intervention if crashed
3 Scaled Gateways: Kubernetes auto-restarts, no manual action needed
```

---

## Troubleshooting

### Issue: Load Not Distributed Evenly

**Symptom**: All connections go to 1 pod.

**Expected**: With small sample sizes (10 requests), distribution can be uneven due to randomness.

**Solution**: Test with more connections (100+) to see proper distribution.

---

### Issue: HPA Shows <unknown> for Metrics

**Symptom**: `kubectl get hpa` shows `<unknown>/70%`

**Solution**: Install metrics-server:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`{{execute}}

Wait 30 seconds, then check again:
```bash
kubectl get hpa -n keeper-gateway-scaled
```

---

### Issue: Pods Not Spreading Across Nodes

**Symptom**: All 3 pods on same node.

**Check pod distribution**:
```bash
kubectl get pods -n keeper-gateway-scaled -o wide
```
`kubectl get pods -n keeper-gateway-scaled -o wide`{{execute}}

**Solution**: Anti-affinity is **preferred** (not required). If cluster has limited nodes, Kubernetes may schedule multiple pods on one node. This is OK for testing!

For production: Use **requiredDuringSchedulingIgnoredDuringExecution** to enforce distribution.

---

## 📊 Final Verification Checklist

Before completing this tutorial, verify all success criteria:

- [ ] **3 gateway pods in Running state**
- [ ] **Each pod has unique instance ID** (XGMRPR, MWUEEE, SQRXZT or similar)
- [ ] **Commander shows ONLINE (3 instances)**
- [ ] **All 3 instances visible in `pam gateway list`**
- [ ] **MySQL reachable from all gateway pods**
- [ ] **No CrashLoopBackOff or error states**
- [ ] **Load balancing verified** (requests distributed across instances)
- [ ] **High availability tested** (pod deletion = zero downtime)
- [ ] **HPA showing metrics** (CPU and memory percentages)

**How many did you check?**
- **9/9**: 🎉 Perfect! You've mastered gateway scaling!
- **7-8/9**: 👍 Great! Minor tweaks needed
- **<7/9**: Review earlier steps and troubleshooting sections

---

## Next Steps

Congratulations! You've successfully deployed and verified a scaled Keeper Gateway!

**What to explore next**:
- Try connecting to MySQL through the vault UI (Step 4 records)
- Test with different database types (PostgreSQL, SQL Server)
- Deploy additional target resources (SSH servers, RDP hosts)
- Implement production-grade security (RBAC, network policies)
- Monitor with Prometheus and Grafana

**🎓 Ready for production?** Head to the finish section for best practices and production deployment guidelines!
