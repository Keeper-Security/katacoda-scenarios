# Congratulations! 🎉

You've injected secrets from Keeper into Kubernetes, step by step:

1. Installed the Keeper Injector and injected a whole record with three annotations
2. Picked single fields, custom fields and file attachments into their own files
3. Shaped secrets as `.env` and properties files and built a connection string with a template
4. Ran a Postgres database and an application on credentials from Keeper only
5. Rotated an API key and a database password while the pods kept running
6. Produced environment variables and a Kubernetes Secret for applications that need them
7. Fetched a whole folder, diagnosed a broken pod and reviewed production settings

## Clean Up

```bash
kubectl delete deployment demo-app demo-postgres
kubectl delete service demo-postgres
kubectl delete pod hello-keeper pick-fields multi shapes rotation-demo envvars k8s-secret-mode k8s-secret-rotation whole-folder --ignore-not-found
kubectl delete secret demo-db-secret demo-api-secret --ignore-not-found
kubectl delete rolebinding demo-secret-writer --ignore-not-found
kubectl delete role update-demo-api-secret --ignore-not-found
kubectl delete serviceaccount demo-secret-writer --ignore-not-found
```{{execute}}

## Keeper Injector or External Secrets Operator?

Keeper supports both. They solve the same problem at different layers:

| | Keeper Injector | External Secrets Operator (ESO) |
|---|---|---|
| Where secrets live | In the pod's memory (default) | Kubernetes Secret objects in etcd |
| How you configure it | Annotations on the pod | Custom resources (SecretStore, ExternalSecret) |
| Rotation | Files update in the running pod | Secret updates; pods typically restart to pick it up |
| Fields, custom fields, files, templates | Yes | Yes |
| Keeper Notation and folder paths | Yes | No |
| Push values from Kubernetes to Keeper | No | Yes (PushSecret) |
| One Keeper connection for the whole cluster | No: credentials Secret per namespace, or cloud secret store | Yes (ClusterSecretStore) |
| Secrets for things that are not pods (Ingress TLS, image pull) | Possible with Kubernetes Secret mode | Yes, its main use |
| When a fetch fails | Pod stays in `Init:Error` with a clear log message | Error only in the operator's logs |

**Choose the Injector** when secrets should stay out of etcd, rotate without restarts, or be configured right next to the workload. **Choose ESO** when many workloads share the same Secret, when non-pod resources need it, or when you need to push values back to Keeper. Try ESO in the [External Secrets tutorial](https://killercoda.com/keeper/scenario/ksm-z-integration-external-secrets).

## Additional Resources

- [Keeper Kubernetes Secrets Injector documentation](https://docs.keeper.io/keeperpam/secrets-manager/integrations/kubernetes-secrets-injector)
- [Injector source and examples on GitHub](https://github.com/Keeper-Security/keeper-k8s-injector)
- [Keeper Notation](https://docs.keeper.io/keeperpam/secrets-manager/about/keeper-notation)
