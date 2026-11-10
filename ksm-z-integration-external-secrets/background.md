# Background Information

## Keeper Secrets Manager (KSM)

Keeper Secrets Manager is an enterprise-grade secrets management solution that provides:
- Centralized secrets management
- Role-based access control
- Audit logging
- Compliance reporting
- Secure secret rotation

## External Secrets Operator

External Secrets Operator is a Kubernetes operator that integrates external secret management systems like KSM with Kubernetes. It:
- Automatically syncs secrets from external sources to Kubernetes
- Supports multiple secret backends
- Provides secret rotation capabilities
- Maintains secret versioning

## How it works together

1. External Secrets Operator is installed in your Kubernetes cluster
2. KSM credentials are stored in a Kubernetes secret
3. External Secrets Operator uses these credentials to authenticate with KSM
4. Secrets are automatically synced from KSM to Kubernetes
5. Applications can access the secrets through standard Kubernetes mechanisms

This integration provides a secure way to manage secrets in Kubernetes while leveraging KSM's enterprise-grade security features. 