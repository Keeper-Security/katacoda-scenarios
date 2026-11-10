# Background Information

## Keeper Secrets Manager (KSM)

Keeper Secrets Manager stores the secrets your applications need (database passwords, API keys, certificates) in your Keeper Vault, protected by Keeper's zero-knowledge encryption. Applications reach them through a **Secrets Manager Application** and its **Client Devices**.

## The Keeper Kubernetes Secrets Injector

The Injector is installed once in a cluster. From then on, any pod that carries the annotation `keeper.security/inject: "true"` gets its secrets from Keeper automatically:

1. When the pod is created, Kubernetes asks the Injector's **mutating admission webhook** to review it.
2. The webhook adds two small containers to the pod: an **init container** that fetches the secrets before your app starts, and a **sidecar** that keeps them up to date while the pod runs.
3. Both write the secrets to a memory-backed volume (**tmpfs**) mounted read-only into your containers at `/keeper/secrets`.
4. Your app simply reads files. When the pod is deleted, the secrets disappear with it.

```
                Kubernetes cluster
 ┌──────────────────────────────────────────────────────┐
 │  Keeper Injector        Your pod                     │
 │  (webhook)        ┌──────────────────────────────┐   │
 │  adds containers  │ init ─┐   sidecar ─┐         │   │
 │  ───────────────▶ │       ▼            ▼         │   │      ┌──────────────────┐
 │                   │  /keeper/secrets (in memory) │◀──┼──────│ Keeper Secrets   │
 │                   │            │                 │   │      │ Manager (cloud)  │
 │                   │            ▼                 │   │      └──────────────────┘
 │                   │       your app reads files   │   │
 │                   └──────────────────────────────┘   │
 └──────────────────────────────────────────────────────┘
```

By default nothing is stored in Kubernetes Secrets or etcd. You can opt into environment variables or Kubernetes Secrets per pod when an application needs them (Step 6).

## Injector or External Secrets Operator?

Keeper also works with the External Secrets Operator (ESO), which copies secrets into Kubernetes Secret objects. Both are covered on the final page of this tutorial; in short, the Injector keeps secrets inside the pod and updates them live, while ESO creates shared Kubernetes Secrets and can also push values back to Keeper.
