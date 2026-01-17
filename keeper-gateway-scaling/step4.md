# Step 4: Configure PAM Records & Test Connections

**Learning Objective**: Configure PAM records in Keeper Vault to enable connections through the scaled gateway.

## What You'll Learn
- How to create a PAM Configuration linking gateway to resources
- How to create PAM User records for administrative credentials
- How to create PAM Database records for MySQL connections
- How to verify gateway status in PAM records

## Why PAM Records Matter?

### **Business Benefits**:
- **Centralized Credential Management**: All credentials stored securely in vault
- **Access Control**: Fine-grained permissions on who can connect
- **Session Recording**: Audit trail of all database connections
- **Compliance**: Meet regulatory requirements (SOX, PCI-DSS, HIPAA)

### **Technical Benefits**:
- **Zero Knowledge**: Credentials encrypted end-to-end
- **Just-in-Time Access**: Temporary credentials for connections
- **Automatic Rotation**: Password rotation without manual intervention
- **Multi-Protocol Support**: SSH, RDP, Database, Kubernetes, etc.

---

## 1. Create PAM Configuration

PAM Configurations link gateways to target resources and define which PAM features are enabled.

### **Steps in Keeper Vault UI**:

1. **Navigate to**: **Secrets Manager** → **PAM Configurations** tab
2. **Click**: **New Configuration** button
3. **Configure**:
   - **Title (Required)**: `Test Gateway Scaling Conf`
   - **Environment**: Select `Local Network` (dropdown)
   - **Gateway (Required)**: Select `Test Gateway Scaling Gateway 1` (dropdown)
   - **Application Folder (Required)**: Select `Test Gateway Scaling` (dropdown)
   - **PAM Features Allowed** (checkboxes):
     - ✅ Rotation
     - ✅ Connection
     - ✅ JIT (Just-in-Time Access)
     - ✅ Tunnel
     - ✅ Keeper AI
4. **Click**: **Save** button

**✅ Expected Result**:
- PAM Configuration created
- Shows in PAM Configurations list
- Type: Local Network
- Gateway: Test Gateway Scaling Gateway 1
- Last Rotated: Never (no resources yet)

**💡 What is a PAM Configuration?**
- Links a gateway to target resources (databases, servers, etc.)
- Defines which PAM features are enabled (rotation, connection, JIT, tunneling)
- Controls session recording settings
- Specifies the application folder containing resources

---

## 2. Create PAM User Record (Administrative Credentials)

PAM User records store administrative credentials for target systems.

### **Steps in Keeper Vault UI**:

1. **Navigate to**: **My Vault** → **Test Gateway Scaling** folder
2. **Click**: **Create New** button
3. **Select**: **PAM User** record type
4. **Configure**:
   - **Title (Required)**: `Test Gateway Scaling - MySQL - User Root`
   - **Login (Required)**: `root`
   - **Password**: `F6TpKyxHX73EldkDx1x9`
     - **⚠️ Note**: This is the MySQL root password from our deployment
   - **Rotation Settings**: Leave as "Not configured" (optional)
5. **Click**: **Save** button

**✅ Expected Result**:
- PAM User record created
- Shows in Test Gateway Scaling folder
- Record type icon: User symbol
- Login: root

**💡 What is a PAM User Record?**
- Stores administrative credentials for target systems
- Used for password rotation and privileged operations
- Can be linked to multiple PAM Database/Server records
- Supports automatic password rotation schedules

**🔒 Security Note**:
- Passwords encrypted with zero-knowledge encryption
- Only authorized users can decrypt credentials
- Access logged in audit trail
- Rotation history tracked

---

## 3. Create PAM Database Record (MySQL Server)

PAM Database records define the target database servers and link to credentials.

### **Steps in Keeper Vault UI**:

1. **Navigate to**: **My Vault** → **Test Gateway Scaling** folder
2. **Click**: **Create New** button
3. **Select**: **PAM Database** record type
4. **Configure Basic Settings**:
   - **Title (Required)**: `Test Gateway Scaling - MySQL - Server`
   - **Hostname or IP Address**: `mysql`
     - **💡 Why just "mysql"?** In Kubernetes, services get DNS names
     - Full DNS: `mysql.keeper-gateway-scaled.svc.cluster.local`
     - Short name works within the same namespace
   - **Port**: `3306` (appears in 3 places: Administrative, Connection, Remote Tunnel)
     - All three should be `3306`

5. **Configure Credentials**:
   - **Administrative Credentials**: Click dropdown
     - Select: `Test Gateway Scaling - MySQL - User Root`
     - Shows: `root` (username from PAM User record)
   - **Launch Credentials (Required)**: Click dropdown
     - Select: `Test Gateway Scaling - MySQL - User Root` (same)

6. **Configure PAM Settings**:
   - **PAM Configuration (Required)**: Click dropdown
     - Select: `Test Gateway Scaling Conf`
   - **Gateway**: Auto-populated after selecting configuration
     - Shows: `Test Gateway Scaling Gateway 1`
     - Status: **✅ Online** (green checkmark)

7. **Click**: **Save** button

**✅ Expected Result**:
- PAM Database record created
- Gateway status shows: **Online**
- Ready for connections

---

## 4. Configure Connection Settings

Now configure the connection tab to enable MySQL connections:

### **Steps in Keeper Vault UI**:

1. **Open**: `Test Gateway Scaling - MySQL - Server` record (double-click)
2. **Click**: **PAM Settings** section (if not already viewing)
3. **Click**: **Connection** tab
4. **Configure**:
   - **Protocol**: Select `MySQL` (dropdown)
   - **Enable Connection**: Toggle **ON** (green)
   - **Session Recording** (checkboxes):
     - ✅ Graphical Session Recording
     - ✅ Key Events
     - ✅ Text Session Recording (Typescript)
   - **Connection Port (Required)**: `3306`
   - **Launch Credentials (Required)**: Select `Test Gateway Scaling - MySQL - User Root`
5. **Click**: **Update** button (bottom right)

**✅ Expected Result**:
- Connection settings saved
- Protocol: MySQL
- Connection enabled (green toggle)
- All session recording types enabled

**💡 What is Session Recording?**
- **Graphical**: Records visual session (for RDP, VNC)
- **Key Events**: Records keyboard/mouse actions
- **Typescript**: Text log of all commands and outputs
- Stored in Keeper for compliance and audit

---

## 5. Verify Gateway Status

Let's verify the gateway is online and ready:

### **Check in Vault UI**:

1. **Open**: `Test Gateway Scaling - MySQL - Server` record
2. **Look at**: **PAM Settings** section
3. **Verify**:
   - **Gateway**: Test Gateway Scaling Gateway 1
   - **Status**: **✅ Online** (green with checkmark)

### **Check in Commander**:

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
    |- Instance 1 (connected: 2026-01-15 14:01:46)        100.29.102.100  ONLINE  1.7.6
    |- Instance 2 (connected: 2026-01-15 15:04:00)        100.29.102.100  ONLINE  1.7.6
    |- Instance 3 (connected: 2026-01-15 15:04:20)        100.29.102.100  ONLINE  1.7.6
```

**🎉 Perfect!** Gateway shows:
- **ONLINE** status
- **(3 instances)** - all connected
- Each instance with unique connection timestamp

---

## 🔍 What We Accomplished

In this step, you've created the complete PAM configuration:

- ✅ **PAM Configuration**: Links gateway to resources
- ✅ **PAM User Record**: Stores MySQL root credentials
- ✅ **PAM Database Record**: Defines MySQL server with connection settings
- ✅ **Verified Gateway**: All 3 instances online and ready

### Summary of Records Created

| Record | Type | Purpose |
|--------|------|---------|
| **Test Gateway Scaling Conf** | PAM Configuration | Links gateway to resources, enables PAM features |
| **Test Gateway Scaling - MySQL - User Root** | PAM User | Administrative credentials (root user) |
| **Test Gateway Scaling - MySQL - Server** | PAM Database | MySQL server definition with connection settings |

### Record Relationships

```
PAM Configuration
  └─ Links to: Gateway (Test Gateway Scaling Gateway 1)
  └─ Links to: Folder (Test Gateway Scaling)

PAM Database
  └─ Links to: PAM Configuration (Test Gateway Scaling Conf)
  └─ Links to: PAM User (MySQL User Root) [Admin Credentials]
  └─ Links to: PAM User (MySQL User Root) [Launch Credentials]

Gateway
  └─ 3 Instances Connected:
      ├─ Instance 1 (XGMRPR)
      ├─ Instance 2 (MWUEEE)
      └─ Instance 3 (SQRXZT)
```

---

## 🔍 Understanding PAM Record Types

### **PAM Configuration**
- **Purpose**: Central configuration for gateway-resource relationships
- **Components**: Gateway selection, folder access, feature flags
- **Required**: Yes - every PAM resource needs a configuration

### **PAM User**
- **Purpose**: Stores administrative credentials
- **Use Cases**: Root users, service accounts, admin credentials
- **Features**: Rotation scheduling, password complexity rules
- **Security**: Encrypted, access controlled, audit logged

### **PAM Database**
- **Purpose**: Defines database server and connection parameters
- **Supported DBs**: MySQL, PostgreSQL, SQL Server, Oracle, MongoDB, etc.
- **Features**: Connection management, session recording, tunneling
- **Credentials**: Links to PAM User records (admin + launch)

---

## 💡 Connection Flow Architecture

**When a user connects to MySQL**:

```
┌─────────┐
│  User   │ Opens PAM Database record, clicks Connect
└────┬────┘
     │
     ▼
┌──────────────────┐
│  Keeper Vault    │ Retrieves credentials, gateway info
│  (Backend)       │ Sends connection request to Keeper
└────┬─────────────┘
     │
     ▼
┌──────────────────┐
│  Keeper         │ Selects 1 of 3 gateway instances (random)
│  (Load Balancer) │ Routes request with InstanceId header
└────┬─────────────┘
     │
     ├─ 33% → Instance 1 (XGMRPR) ──┐
     ├─ 33% → Instance 2 (MWUEEE) ──┼─ One is chosen
     └─ 33% → Instance 3 (SQRXZT) ──┘
           │
           ▼
     ┌─────────────┐
     │ Gateway Pod │ Receives connection request
     └──────┬──────┘
            │
            ▼
     ┌─────────────┐
     │MySQL Server │ Connection established
     │   :3306     │ Session recorded
     └─────────────┘
```

**Load Balancing**:
- Keeper picks **randomly** from available instances
- Each instance has **33% probability** (with 3 instances)
- Over 100 connections: ~33 per instance (statistically)

---

## Troubleshooting

### Issue: Gateway Shows Offline in PAM Record

**Symptom**: Gateway status shows red X or "Offline" in PAM Database record.

**Check**:
1. Verify pods are running: `kubectl get pods -n keeper-gateway-scaled`
2. Check gateway logs: `kubectl logs -n keeper-gateway-scaled deployment/keeper-gateway`
3. Verify in Commander: `pam gateway list` (should show ONLINE)

**Solution**:
- Wait 30-60 seconds for vault to sync gateway status
- Refresh the vault page (hard refresh: Cmd+Shift+R)
- Check network connectivity from gateway pods to Keeper backend

---

### Issue: Can't Select Gateway in PAM Configuration

**Symptom**: Gateway dropdown is empty or doesn't show your gateway.

**Solution**:
- Verify gateway was created successfully (Step 1)
- Check you're in the correct KSM Application
- Ensure the gateway status is not "deleted"
- Try refreshing the page

---

### Issue: MySQL Connection Details Unclear

**Symptom**: Unsure what hostname to use for MySQL.

**Solution**:
- **Within Kubernetes namespace**: Use `mysql` (short name)
- **From different namespace**: Use `mysql.keeper-gateway-scaled.svc.cluster.local`
- **Port**: Always `3306` (standard MySQL port)
- **Database**: `salesdb` (created in our deployment)

**Test from gateway pod**:
```bash
kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- \
  mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SHOW DATABASES;"
```
`kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- mysql -h mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SHOW DATABASES;"`{{execute}}

**Expected**: Shows `salesdb` in the database list.

---

## 🔒 Security Best Practices

### **Credential Storage**

**PAM User Records**:
- ✅ Encrypted with zero-knowledge encryption
- ✅ Access controlled via vault permissions
- ✅ Rotation history tracked
- ✅ Audit log of all credential access

**Why Not Store Passwords in Code?**
```python
# ❌ BAD - Hardcoded password
password = "F6TpKyxHX73EldkDx1x9"

# ✅ GOOD - Retrieved from Keeper PAM
password = keeper_pam.get_credentials("MySQL Root")
```

### **Session Recording Benefits**

**Compliance Value**:
- **Who**: User identity recorded
- **What**: Commands executed recorded
- **When**: Timestamp of every action
- **Where**: Target system recorded
- **Why**: Purpose/ticket reference (optional)

**Use Cases**:
- Forensic investigation after security incident
- Compliance audits (prove who accessed what)
- Training and onboarding (review session recordings)
- Debugging (replay what user did to reproduce issue)

---

## 💡 Advanced PAM Configuration Options

### **Connection Types Available**

The PAM Database record supports multiple connection types:

| Tab | Purpose | Use Case |
|-----|---------|----------|
| **Rotation** | Configure password rotation | Auto-rotate MySQL root password every 90 days |
| **Connection** | Enable interactive sessions | DBA connects via Keeper to run queries |
| **JIT** | Just-in-Time access provisioning | Create temporary MySQL user for support ticket |
| **Tunnel** | Port forwarding | Forward local port 13306 → mysql:3306 |
| **Keeper AI** | AI-assisted operations | Natural language database queries |

**For this tutorial**, we enabled **Connection** to test the scaled gateway.

### **Session Recording Granularity**

You can control what gets recorded:

| Recording Type | What's Captured | Storage Impact |
|----------------|----------------|----------------|
| **Graphical** | Screenshots/video (for RDP/VNC) | High (~50MB/hour) |
| **Key Events** | Keyboard/mouse actions | Low (~1MB/hour) |
| **Text (Typescript)** | Command output logs | Medium (~5MB/hour) |

**💡 Best Practice**: Enable all three for complete audit trail.

---

## 🔍 Verifying Configuration

### **Verify PAM Configuration**

**In Vault UI**:
1. Go to **Secrets Manager** → **PAM Configurations**
2. Find: `Test Gateway Scaling Conf`
3. Verify:
   - Type: Local Network
   - Gateway: Test Gateway Scaling Gateway 1 (with green checkmark)
   - Status: Active

### **Verify PAM User**

**In Vault UI**:
1. Go to **My Vault** → **Test Gateway Scaling** folder
2. Find: `Test Gateway Scaling - MySQL - User Root`
3. Verify:
   - Record type: PAM User
   - Login: root
   - Password: Set (shows as dots)

### **Verify PAM Database**

**In Vault UI**:
1. Go to **My Vault** → **Test Gateway Scaling** folder
2. Find: `Test Gateway Scaling - MySQL - Server`
3. Open the record
4. **Check PAM Settings**:
   - PAM Configuration: `Test Gateway Scaling Conf`
   - Gateway: `Test Gateway Scaling Gateway 1`
   - Gateway Status: **✅ Online** (green checkmark)
5. **Check Connection Tab**:
   - Protocol: MySQL
   - Enable Connection: ✅ (green toggle)
   - Connection Port: 3306
   - Launch Credentials: Test Gateway Scaling - MySQL - User Root

**✅ All Green?** Configuration is correct and ready for testing!

---

## 🔍 Testing Connectivity from Gateway to MySQL

Before testing through the vault, let's verify the gateway pods can reach MySQL:

**Test from any gateway pod**:
```bash
kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- \
  mysql -h mysql -u sqluser -pMUQtQ7X66OWqZdP2vZ8k -e "SELECT 'Gateway can reach MySQL!' AS status;"
```
`kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- mysql -h mysql -u sqluser -pMUQtQ7X66OWqZdP2vZ8k -e "SELECT 'Gateway can reach MySQL!' AS status;"`{{execute}}

**✅ Expected Output**:
```
+----------------------------+
| status                     |
+----------------------------+
| Gateway can reach MySQL!   |
+----------------------------+
```

**✅ Success**: Gateway pods can connect to MySQL!

**💡 This proves**:
- Kubernetes DNS resolution working (mysql → mysql.keeper-gateway-scaled.svc.cluster.local)
- Network connectivity between pods working
- MySQL accepting connections
- Credentials valid

---

## Troubleshooting

### Issue: Gateway Shows Offline in PAM Database Record

**Symptom**: Red X or "Offline" status in PAM Settings.

**Check gateway in Commander**:
```bash
keeper shell
pam gateway list
```

**Expected**: Should show `ONLINE (3 instances)`

**Solutions**:
1. **Refresh vault page**: Hard refresh (Cmd+Shift+R or Ctrl+Shift+R)
2. **Wait 30-60 seconds**: Vault syncs gateway status periodically
3. **Check pods are running**: `kubectl get pods -n keeper-gateway-scaled`
4. **Check logs for errors**: `kubectl logs -n keeper-gateway-scaled deployment/keeper-gateway`

---

### Issue: Can't Connect to MySQL from Gateway Pod

**Symptom**: `kubectl exec ... mysql` command fails.

**Check MySQL is running**:
```bash
kubectl get pods -n keeper-gateway-scaled -l app=mysql
```
`kubectl get pods -n keeper-gateway-scaled -l app=mysql`{{execute}}

**Expected**: Shows `Running` status.

**Test DNS resolution**:
```bash
kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- nslookup mysql
```
`kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- nslookup mysql`{{execute}}

**Expected**: Resolves to ClusterIP address (e.g., 172.20.169.56).

**Test port connectivity**:
```bash
kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- nc -zv mysql 3306
```
`kubectl exec -n keeper-gateway-scaled deployment/keeper-gateway -- nc -zv mysql 3306`{{execute}}

**Expected**: `Connection to mysql 3306 port [tcp/mysql] succeeded!`

---

### Issue: Wrong Credentials for MySQL

**Symptom**: "Access denied for user 'root'" error.

**Verify credentials match deployment**:

From Step 3, our MySQL deployment uses:
- **Root Password**: `F6TpKyxHX73EldkDx1x9`
- **User**: `sqluser`
- **User Password**: `MUQtQ7X66OWqZdP2vZ8k`

**Check what's in MySQL**:
```bash
kubectl exec -n keeper-gateway-scaled deployment/mysql -- \
  mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SELECT user, host FROM mysql.user;"
```
`kubectl exec -n keeper-gateway-scaled deployment/mysql -- mysql -u root -pF6TpKyxHX73EldkDx1x9 -e "SELECT user, host FROM mysql.user;"`{{execute}}

**Expected**: Shows `root` and `sqluser` in the user list.

---

## 🔍 Understanding the Complete Architecture

**PAM Record Hierarchy**:

```
Test Gateway Scaling (Folder)
  │
  ├─ PAM Configuration: Test Gateway Scaling Conf
  │    ├─ Environment: Local Network
  │    ├─ Gateway: Test Gateway Scaling Gateway 1 (3 instances)
  │    └─ Features: Rotation, Connection, JIT, Tunnel, AI
  │
  ├─ PAM User: Test Gateway Scaling - MySQL - User Root
  │    ├─ Login: root
  │    └─ Password: F6TpKyxHX73EldkDx1x9
  │
  └─ PAM Database: Test Gateway Scaling - MySQL - Server
       ├─ Hostname: mysql
       ├─ Port: 3306
       ├─ Protocol: MySQL
       ├─ Admin Credentials: → PAM User (root)
       ├─ Launch Credentials: → PAM User (root)
       └─ PAM Configuration: → Test Gateway Scaling Conf
```

**Data Flow**:
1. User opens PAM Database record
2. Vault retrieves credentials from PAM User record
3. Vault retrieves gateway info from PAM Configuration
4. Connection request sent to Keeper
5. Keeper selects 1 of 3 gateway instances (random)
6. Gateway establishes connection to MySQL
7. Session recorded and encrypted
8. Credentials returned to user (if JIT) or connection established

---

## Next Steps

Configuration complete! In the next step, we'll:

1. **Test the MySQL connection** through the vault
2. **Verify load balancing** by watching which instance handles requests
3. **Test high availability** by deleting a pod and confirming zero downtime
4. **Analyze instance distribution** to see random load balancing in action

Get ready to see the scaled gateway in action! 🚀
