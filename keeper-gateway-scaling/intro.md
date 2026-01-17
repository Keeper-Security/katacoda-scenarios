# Welcome to Keeper Gateway Scaling and High Availability

## What is Keeper Gateway Scaling?

Keeper Gateway Scaling enables you to run **multiple gateway instances** with the same configuration for horizontal scaling and high availability. This feature distributes PAM workloads across several gateway instances, allowing for greater capacity, better performance, and zero-downtime failover.

**Key Benefits:**
- **Horizontal Scaling**: Run multiple instances per configuration (this tutorial uses 3 as an example)
- **Zero Downtime**: Automatic failover if one instance crashes
- **Load Balancing**: Requests distributed across all instances (currently random, future versions will support round robin and least-loaded algorithms)
- **Easy Setup**: One Commander command to enable scaling
- **Same Configuration**: All instances share identical credentials and settings

## What You'll Learn

In this interactive tutorial, you will:

1. **Create a Gateway** in Keeper Vault and provision it for Kubernetes deployment
2. **Configure Gateway Scaling** using Commander CLI (`pam gateway set-max-instances`) - we'll use 3 instances as an example
3. **Deploy Multiple Gateway Instances** to Kubernetes with a single manifest (3 replicas)
4. **Configure PAM Records** (Configuration, User, Database) for testing connections
5. **Verify Load Balancing** across all gateway instances in real-time (random distribution)

## Prerequisites

Before starting this tutorial, you should have:

- Access to Keeper Vault (production, dev, or QA environment)
- Basic familiarity with Kubernetes concepts (pods, deployments, services)
- Understanding of PAM concepts (gateways, configurations, credentials)
- **Test credentials only** - Never use production credentials in tutorials

## Key Features You'll Explore

- **Instance ID Generation**: Each gateway generates a unique 6-character ID on startup
- **Keeper Load Balancing**: Random request distribution across gateway pool
- **High Availability**: Kubernetes auto-healing and zero-downtime updates
- **Commander CLI**: `pam gateway set-max-instances` command
- **PAM Configuration**: Connecting databases through scaled gateways

## Version Requirements

| Component | Minimum Version |
|-----------|----------------|
| Keeper Gateway | 1.7.6+ |
| Commander CLI | 17.2+ |
| Keeper | 1.6.0+ |
| Kubernetes | 1.19+ |

---

## ⚠️ IMPORTANT SECURITY NOTICE

**DO NOT USE YOUR PRODUCTION CREDENTIALS IN ANY OF THESE EXAMPLES**

This is a learning environment. Always use test accounts and dummy data for educational purposes. Never enter your real production passwords or sensitive information in tutorial environments.

For production deployments:
- Use Kubernetes Secrets (not plain text configs)
- Enable RBAC and network policies
- Use private container registries
- Implement proper monitoring and alerting

---

Let's get started by setting up your Keeper Gateway for scaling!
