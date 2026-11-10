# Keeper Secrets Manager: Kubernetes Secrets Injector

In this tutorial you will inject secrets from your Keeper Vault into Kubernetes pods with nothing more than a few **annotations** on the pod. No application code changes and no Kubernetes Secret objects are needed.

We start with the smallest possible example and add one idea per step:

1. **Install and Hello World**: install the Injector and see a record appear inside a pod
2. **Pick Exactly What You Need**: single fields, custom fields, file attachments, several records
3. **Shape Secrets for Your App**: `.env` and properties files, and a connection string built from a template
4. **A Real App**: a Postgres database and a client that connect using only secrets from Keeper
5. **Rotation Without Restarts**: change a password in Keeper and watch the running pod pick it up
6. **Environment Variables and Kubernetes Secrets**: for applications that need them
7. **Whole Folders, Troubleshooting and Production Tips**

Every step ends with a **Check** that confirms it worked.

## Prerequisites

- A Keeper account with Secrets Manager enabled
- A **Secrets Manager Application** with a **shared folder** shared to it
- A **Client Device** for that application, created with **IP lock disabled** and exported as a **Base64 configuration** (a one-time access token does not work here)
- Two records in that shared folder, created exactly as described in Step 1

No Kubernetes experience beyond running `kubectl` is assumed. Each command is explained.
