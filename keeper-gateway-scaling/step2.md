# Step 2: Configure Gateway Scaling with Commander

**Learning Objective**: Use Keeper Commander CLI to enable gateway scaling by setting the maximum number of instances.

## What You'll Learn
- How to connect to Keeper Vault using Commander CLI
- How to list existing gateways and get their UIDs
- How to configure the maximum number of gateway instances
- How to verify scaling configuration

## Why Configure Max Instances?

### **The Problem Without Scaling**:
- Default: **1 gateway per configuration** (maxInstances=1)
- If you try to run multiple instances, Keeper rejects them with:
  ```
  "Maximum controllers connected"
  ```
- Result: Only 1 gateway can connect, others crash

### **The Solution - Enable Scaling**:
- Set `maxInstances=3` using Commander
- Keeper now accepts **3 instances with same configuration**
- Result: All 3 instances connect successfully and load balance

---

## 1. Start Keeper Commander

First, verify Commander is installed and start an interactive shell:

`keeper --version`{{execute}}

**✅ Expected Output**:
```
Keeper Commander, version 17.2.0 (or higher)
```

**Start Commander Shell**:

`keeper shell`{{execute}}

**✅ Expected Output**:
```
Keeper Commander, version 17.2.0
Using Keeper region: US

This is an interactive Keeper Commander shell.
Press <Ctrl-D> or type 'quit' to exit.

Enter 'help' for a list of available commands

My Vault>
```

**⚠️ Note**: You'll be prompted to login. Use your **test credentials** (not production!).

---

## 2. Login to Keeper Vault

**Login Command**:

At the `My Vault>` prompt, you're automatically logged in if credentials are cached.

If prompted for login:
```
My Vault> login
Email: [your-test-email]
Password: [your-test-password]
```

**For this tutorial**: We assume you're already authenticated in the web vault.

**💡 Multi-Region Support**: If using a different region:
```bash
keeper shell --server keepersecurity.eu      # Europe
keeper shell --server keepersecurity.com.au  # Australia
keeper shell --server keepersecurity.ca      # Canada
keeper shell --server govcloud.keepersecurity.us  # US GovCloud
keeper shell --server keepersecurity.jp      # Japan
```

---

## 3. List Existing Gateways

Now let's find the gateway we created in Step 1:

**Command**:
```bash
pam gateway list
```

At the `My Vault>` prompt, type:
```
pam gateway list
```

**✅ Expected Output**:
```
Test Gateway Scaling App (XLi65XXWgBUkuUhf2ERfeg)
  Test Gateway Scaling Gateway 1    wM6mqZ_hQhWtLU225UNDcw  OFFLINE  1.7.6
```

**Key Information**:
- **Gateway Name**: Test Gateway Scaling Gateway 1
- **Gateway UID**: `wM6mqZ_hQhWtLU225UNDcw` ← **We need this!**
- **Status**: OFFLINE (not deployed yet)
- **Version**: 1.7.6 (gateway version configured)

**💡 What is a Gateway UID?**
- Unique identifier for each gateway
- Used in Commander commands to specify which gateway to configure
- Format: 22-character base64url string (e.g., `wM6mqZ_hQhWtLU225UNDcw`)

---

## 4. Set Maximum Instances to 3

Now configure the gateway to allow 3 instances (instead of default 1):

**Command Syntax**:
```bash
pam gateway set-max-instances -g <GATEWAY_UID> -m <MAX_INSTANCES>
```

**For our gateway** (replace UID with yours from `pam gateway list`):
```bash
pam gateway set-max-instances -g wM6mqZ_hQhWtLU225UNDcw -m 3
```

**⚠️ Important**: Replace `wM6mqZ_hQhWtLU225UNDcw` with **your actual gateway UID** from the previous command!

**✅ Expected Output**:
```
Test Gateway Scaling Gateway 1: max instance count set to 3
```

**🔍 What Just Happened?**
- Commander sent API request to Keeper backend
- Backend stored: `maxInstances=3` for this gateway UID
- Keeper will now accept 3 connections with the same configuration (you can set any number)

---

## 5. Verify Scaling Configuration

Let's verify the max instances were set correctly:

**Command**:
```bash
pam gateway list
```

**✅ Expected Output** (BEFORE deployment):
```
Test Gateway Scaling App (XLi65XXWgBUkuUhf2ERfeg)
  Test Gateway Scaling Gateway 1    wM6mqZ_hQhWtLU225UNDcw  OFFLINE (3 instances)
```

**Notice the change**:
- **Before**: `OFFLINE`
- **After**: `OFFLINE (3 instances)` ← Shows max instances configured!

**After Deployment** (Step 3), you'll see:
```
Test Gateway Scaling Gateway 1    wM6mqZ_hQhWtLU225UNDcw  ONLINE (3 instances)
  |- Instance 1 (connected: 2026-01-15 14:01:46)        100.29.102.100  ONLINE  1.7.6
  |- Instance 2 (connected: 2026-01-15 15:04:00)        100.29.102.100  ONLINE  1.7.6
  |- Instance 3 (connected: 2026-01-15 15:04:20)        100.29.102.100  ONLINE  1.7.6
```

---

## 6. Understanding the Max Instances Setting

**How It Works**:

| maxInstances | Allowed Connections | What Happens |
|--------------|---------------------|--------------|
| 1 (default) | Single instance | 2nd instance rejected with "Maximum controllers connected" |
| 3 | Up to 3 instances | All 3 connect, Keeper load balances requests |
| 5 | Up to 5 instances | All 5 connect (if Keeper supports it) |

**Load Balancing Strategy**:
- Keeper maintains a **pool** of all connected instances
- Each request is **randomly routed** to one instance in the pool (current version)
- Future versions will support additional algorithms (round robin, least-loaded)
- Distribution: ~33% per instance (with 3 instances in this tutorial)

**Example Request Flow**:
```
Request 1 → Keeper picks: Instance 2 (MWUEEE)
Request 2 → Keeper picks: Instance 1 (XGMRPR)
Request 3 → Keeper picks: Instance 3 (SQRXZT)
Request 4 → Keeper picks: Instance 2 (MWUEEE) [random again]
```

---

## 🔍 What This Command Does

The `pam gateway set-max-instances` command:

1. **Authenticates** with Keeper backend using your session
2. **Encrypts** the request using Keeper's secure encryption
3. **Sends** API call to update the gateway configuration
4. **Updates** the gateway record with new maxInstances value
5. **Returns** confirmation message

**Storage**:
- maxInstances is stored in Keeper's backend database
- Keeper queries this value when gateways connect
- Persists across gateway restarts and redeployments

---

## 🔒 Security Best Practices

**Authentication Flow**:
1. Commander authenticates with your Keeper account
2. Session token generated and cached
3. All API calls signed with your credentials
4. Audit trail: All changes logged in Keeper

**⚠️ Important**:
- Only users with **"Can manage Keeper Gateways"** permission can set maxInstances
- Changes are audited and logged
- Use test credentials in tutorials (not production!)

---

## Troubleshooting

**Issue: "Permission denied" when running command**

**Symptom**: Error message about insufficient permissions.

**Solution**:
- Verify your account has **"Can create, deploy, and manage Keeper Gateways"** enforcement policy
- Contact your Keeper admin to grant permissions
- In test environments, ensure the account has admin rights

---

**Issue: "Gateway not found"**

**Symptom**: Error about gateway UID not existing.

**Solution**:
- Run `pam gateway list` to verify the gateway exists
- Check you copied the UID correctly (22 characters, case-sensitive)
- Ensure you're logged into the correct Keeper environment

---

**Issue: Commander not installed**

**Symptom**: `keeper: command not found`

**Solution**:
```bash
pip3 install --upgrade keepercommander
```
`pip3 install --upgrade keepercommander`{{execute}}

---

## Command Reference

**Key PAM Gateway Commands in Commander**:

```bash
# List all gateways
pam gateway list

# Set max instances
pam gateway set-max-instances -g <GATEWAY_UID> -m <MAX_INSTANCES>
```

**Help Commands**:
```bash
pam gateway --help                    # Show all gateway commands
pam gateway set-max-instances --help  # Show command-specific help
```

---

## 🔍 What Scaling Enables

**Before Setting maxInstances=3**:
```
┌──────────┐
│ Keeper  │
└────┬─────┘
     │
     ▼
┌─────────────┐
│ Gateway (1) │ ← Only 1 instance allowed
└─────────────┘
```

**After Setting maxInstances=3**:
```
┌──────────┐
│ Keeper  │
└────┬─────┘
     │
     ├─ 33% → Gateway Instance 1 ┐
     ├─ 33% → Gateway Instance 2 ├─ Load Balanced!
     └─ 33% → Gateway Instance 3 ┘
```

---

## Next Steps

Configuration complete! In the next step, we'll:

1. **Create a Kubernetes manifest** with 3 gateway replicas
2. **Paste the base64 config** into the manifest
3. **Deploy to Kubernetes** and watch all 3 instances connect
4. **Verify in Commander** that all 3 instances show as ONLINE

Each instance will generate a **unique 6-character instance ID** (e.g., XGMRPR, MWUEEE, SQRXZT) and Keeper will automatically load balance requests across all 3!
