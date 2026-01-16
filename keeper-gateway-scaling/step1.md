# Step 1: Create Gateway in Keeper Vault

**Learning Objective**: Learn how to create a KSM Application and provision a Keeper Gateway using the Vault UI.

## What You'll Learn
- How to create a shared folder for organizing PAM resources
- How to create a KSM Application with folder access
- How to provision a Keeper Gateway for Kubernetes deployment
- How to obtain the base64 gateway configuration

## Why Gateway Provisioning Matters?

### **Business Benefits**:
- **Centralized Management**: All gateway configurations managed in Keeper Vault
- **Security**: Configuration encrypted and stored securely
- **Auditability**: Track who created gateways and when

### **Technical Benefits**:
- **One-Time Token**: Secure initialization without storing credentials
- **Configuration Portability**: Same config works across environments
- **Easy Scaling**: Reuse configuration for multiple instances

---

## 1. Create a Shared Folder

First, create a folder to organize your gateway resources:

1. **Log into Keeper Vault**: Navigate to your Keeper Vault web interface
2. **Click**: **Create New** → **Shared Folder**
3. **Configure**:
   - **Folder Name**: `Test Gateway Scaling`
   - **Folder Location**: My Vault
   - **User Permissions**: No User Permissions (leave default)
   - **Record Permissions**: View Only (default)
4. **Click**: **Create**

**✅ Expected Result**: New shared folder appears in your vault.

**Why a Shared Folder?**
- Shared folders allow team collaboration
- KSM Applications can access multiple records in one folder
- Easier organization for PAM configurations and credentials

---

## 2. Create a KSM Application

Now create a Secrets Manager Application that will manage your gateway:

1. **Navigate to**: **Secrets Manager** (left sidebar)
2. **Click**: **My Applications** tab
3. **Click**: **Create Application** button
4. **Configure Application**:
   - **Application Name**: `Test Gateway Scaling App`
   - **Folder Access for Application**: Click dropdown
     - Select: `Test Gateway Scaling` (the folder you just created)
     - Shows: **1 folder(s) selected**
   - **Record Permissions for Application**: `Can Edit`
   - **Lock external WAN IP Address**: Leave unchecked (for testing)
5. **Click**: **Generate Access Token** button

**✅ Expected Result**:
- Application created successfully
- Application appears in the list
- Shows: **1 Device**, **1 Record** (the folder link)

**💡 What is a KSM Application?**
- A KSM Application is a security boundary for accessing secrets
- Each application has its own encryption keys
- Applications can access one or more folders
- Devices (like gateways) authenticate via the application

---

## 3. Provision a Keeper Gateway

Now provision the gateway that will run in Kubernetes:

1. **Open**: **Test Gateway Scaling App** (click on it)
2. **Click**: **Gateways** tab (top navigation)
3. **Click**: **Provision Gateway** button
4. **Configure Gateway**:
   - **Gateway Name**: `Test Gateway Scaling Gateway 1`
   - **Gateway initialization method**: Select **Configuration** (dropdown)
     - ⚠️ Important: Select "Configuration" NOT "One-Time Token"
     - Configuration method provides the base64 config needed for Kubernetes
   - **What operating system will run your gateway?**: Select **Linux**
5. **Click**: **Next** button

**✅ Expected Result**:
- Gateway Created dialog appears
- Shows: "Test Gateway Scaling Gateway 1"
- Configuration options available (Base64 or JSON)

---

## 4. Copy the Base64 Configuration

The vault provides two configuration formats. We need the Base64 version for Kubernetes:

1. **Configuration Type**: Select **Base64** (radio button)
   - Default should be Base64, but verify it's selected
2. **Configuration Display**: You'll see a long base64 encoded string starting with `eyJ...`
3. **Click**: **Copy** icon (clipboard icon next to the config)
4. **Click**: **OK** button to close the dialog

**✅ Expected Result**:
- Base64 configuration copied to clipboard
- Gateway shows in vault with status: **Offline** (waiting for connection)
- Gateway appears in the Gateways list for the application

**📋 Sample Configuration (Base64)**:
```
eyJob3N0bmFtZSI6ImtlZXBlcnNlY3VyaXR5LmNvbSIsImNsaWVudElkIjoiRFho...
```

**⚠️ Important**: Save this configuration - you'll paste it into the Kubernetes manifest in Step 3.

---

## 5. Verify Gateway in Vault

Let's verify the gateway was created successfully:

1. **Navigate to**: **Secrets Manager** → **My Applications**
2. **Find**: **Test Gateway Scaling App**
3. **Verify**:
   - Shows: **1 Device** (the gateway)
   - Gateway name: Test Gateway Scaling Gateway 1
   - Status: Offline (expected - not deployed yet)

**Gateway Details**:
- **Name**: Test Gateway Scaling Gateway 1
- **UID**: (shown in list, looks like `wM6mqZ_hQhWtLU225UNDcw`)
- **Status**: Offline (waiting for deployment)
- **Version**: Will show after connection (e.g., 1.7.6)

---

## 🔍 What We Accomplished

In this step, you've:

✅ **Created a shared folder** to organize gateway resources
✅ **Created a KSM Application** with access to that folder
✅ **Provisioned a Keeper Gateway** ready for Kubernetes deployment
✅ **Obtained the base64 configuration** needed for deployment

**What's Next?**
- The gateway is created but **not running yet** (status: Offline)
- We need to **configure scaling** to allow multiple instances
- Then we'll **deploy to Kubernetes** with 3 replicas

---

## 💡 Key Concepts

**Gateway Configuration Components**:
- `hostname`: Keeper environment (keepersecurity.com, dev.keepersecurity.com, etc.)
- `clientId`: Gateway authentication credentials (encrypted)
- `privateKey`: Gateway's private key for encryption
- `appKey`: Application encryption key
- `appOwnerPublicKey`: Application owner's public key for verification

**Why Base64 Encoding?**
- Kubernetes Secrets accept base64 encoded values
- Protects binary data in YAML manifests
- Standard format for configuration storage
- Easy to copy/paste without formatting issues

---

## Troubleshooting

**Issue: Can't find "Secrets Manager" menu**
- **Solution**: Ensure you have KSM enabled on your account
- Check with admin if Secrets Manager access is enabled

**Issue: "Provision Gateway" button disabled**
- **Solution**: Verify the application has folder access configured
- Check that you have permissions to create gateways

**Issue: Lost the base64 configuration**
- **Solution**: Open the gateway in vault → Click the gear icon → View configuration
- You can re-copy the configuration anytime

---

## Next Steps

In the next step, we'll use **Keeper Commander CLI** to configure this gateway for scaling by setting the maximum number of instances to 3.

This will enable the gateway to accept multiple connections with the same configuration, allowing Kubernetes to run 3 replicas that krouter will load balance across!
