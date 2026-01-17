# Keeper Gateway: Scaling and High Availability

**Killercoda Interactive Tutorial**

## Overview

This interactive tutorial teaches users how to deploy and configure multiple Keeper Gateway instances for horizontal scaling and high availability using Kubernetes.

**Duration**: 20-25 minutes
**Difficulty**: Intermediate
**Prerequisites**: Basic Kubernetes and PAM knowledge

---

## What Students Will Learn

- Creating and provisioning Keeper Gateways via Vault UI
- Configuring gateway scaling using Commander CLI (`pam gateway set-max-instances`)
- Deploying scaled gateways to Kubernetes (3 replicas)
- Configuring PAM records for database connections
- Verifying load balancing and high availability

---

## Tutorial Structure

| Step | Topic | Duration |
|------|-------|----------|
| **Step 1** | Create Gateway in Keeper Vault | 5 min |
| **Step 2** | Configure Gateway Scaling with Commander | 3 min |
| **Step 3** | Deploy Scaled Gateway to Kubernetes | 5 min |
| **Step 4** | Configure PAM Records & Test Connections | 4 min |
| **Step 5** | Verify Load Balancing & High Availability | 5 min |

**Total**: ~22 minutes (25 min with cleanup)

---

## Technical Requirements

### **Versions**
- Keeper Gateway: 1.7.6+
- Commander CLI: 17.2+
- Kubernetes: 1.19+

### **Killercoda Environment**
- **Backend Image**: `kubernetes-kubeadm-2nodes`
- **UI Layout**: `editor-terminal` (split view)
- **Interface**: `ide` (full IDE with sidebar)
- **Pre-installed**: kubectl, bash, curl

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `index.json` | Scenario metadata and structure |
| `intro.md` | Welcome screen with prerequisites |
| `step1.md` | Create Gateway in Keeper Vault |
| `step2.md` | Configure Gateway Scaling with Commander |
| `step3.md` | Deploy Scaled Gateway to Kubernetes |
| `step4.md` | Configure PAM Records & Test Connections |
| `step5.md` | Verify Load Balancing & High Availability |
| `finish.md` | Completion summary and next steps |
| `install-commander.sh` | Installation script (runs before intro) |
| `README.md` | This file |

---

## Key Learning Outcomes

After completing this tutorial, students will be able to:

1. ✅ Provision Keeper Gateways for Kubernetes deployment
2. ✅ Configure `maxInstances` to enable gateway scaling
3. ✅ Deploy multiple gateway instances with same configuration
4. ✅ Verify load balancing across instances
5. ✅ Test high availability and zero-downtime failover
6. ✅ Configure PAM records for database connections
7. ✅ Monitor gateway instances using Commander and kubectl
8. ✅ Troubleshoot common scaling issues

---

## Architecture Covered

```
User → Keeper (Load Balancer)
         ↓ (random selection)
         ├─ Gateway Instance 1 (33%)
         ├─ Gateway Instance 2 (33%)
         └─ Gateway Instance 3 (33%)
                ↓
         Target Resource (MySQL)
```

**Key Concepts**:
- Instance ID generation (6-character random uppercase)
- Keeper load balancing (random selection algorithm)
- Kubernetes RollingUpdate strategy (zero downtime)
- Pod anti-affinity (spread across nodes)
- HPA auto-scaling (2-3 replicas based on CPU/memory)

---

## Real Deployment Data

This tutorial is based on a **real successful deployment** with:

- **Gateway**: Test Gateway Scaling Gateway 1
- **UID**: wM6mqZ_hQhWtLU225UNDcw
- **Instance IDs**: XGMRPR, MWUEEE, SQRXZT
- **Environment**: Production (keepersecurity.com)
- **Deployment Date**: 2026-01-15
- **Status**: All 3 instances online and load balanced ✅

---

## Testing & Validation

This scenario has been tested with:
- ✅ Kubernetes 1.31 (EKS)
- ✅ Keeper Gateway 1.7.6
- ✅ Commander 17.2+
- ✅ MySQL 8.0
- ✅ Keeper production environment

**Test Results**:
- All 5 steps completed successfully
- All expected outputs verified
- Load balancing confirmed
- High availability validated
- Zero downtime during pod deletion

---

## Contributing

This scenario is part of the Keeper Security Katacoda Scenarios repository.

**Feedback**: If you find issues or have suggestions, please contact the DevOps team.

**Updates**: Check the repository for latest versions and new scenarios.

---

## Related Scenarios

**Prerequisites** (Recommended before this tutorial):
- `commander-cli` - Keeper Commander basics
- `ksm-sdk-python` - KSM fundamentals

**Next Steps** (After completing this tutorial):
- `ksm-z-integration-kubernetes` - Advanced K8s integration patterns
- `ksm-z-integration-ansible` - Automation with Ansible

---

## Version History

- **v1.0.0** (2026-01-15): Initial release
  - 5 steps covering complete gateway scaling workflow
  - Real deployment examples with actual instance IDs
  - Comprehensive troubleshooting sections
  - Production best practices included

---

**Killercoda Platform**: [killercoda.com/keeper-security](https://killercoda.com/keeper-security)
