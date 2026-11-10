# Step 3 (Optional): Push a Secret from Kubernetes to Keeper

So far secrets have flowed from Keeper into Kubernetes. External Secrets can also go the other way: a **PushSecret** copies a value that was created inside the cluster into a Keeper record, so it is stored and audited in your vault.

> **Prerequisite**: The KSM application must have **Can Edit** permission on the shared folder you used as `folderID` in Step 1. New records are created in that folder.

## 1. Create a Value Inside Kubernetes

Let's generate an API token inside the cluster, the way an application or operator might:

```bash
kubectl create secret generic app-api-token \
  --from-literal=api_token="$(openssl rand -hex 16)"
```{{execute}}

## 2. Create the PushSecret

```bash
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1alpha1     # PushSecret is still v1alpha1 in current External Secrets releases
kind: PushSecret
metadata:
  name: ksm-push-api-token                   # name of the PushSecret
spec:
  secretStoreRefs:                           # push through the SecretStore from Step 1
    - name: my-external-secrets-secretstore
      kind: SecretStore
  refreshInterval: 1h                        # how often the value is pushed again
  deletionPolicy: Delete                     # deleting this PushSecret also deletes the Keeper record
  selector:
    secret:
      name: app-api-token                    # the Kubernetes Secret to read from
  data:
    - match:
        secretKey: api_token                 # key inside the Kubernetes Secret
        remoteRef:
          remoteKey: k8s-generated-api-token/api_token   # <record title>/<field> in Keeper
EOF
```{{execute}}

The `remoteKey` format is `<record title>/<field>`, with exactly one `/`. External Secrets looks for a record with that title in the shared folder and creates it if it does not exist. Records created this way have the record type `externalSecrets`. Keys named `login`/`username`, `password` or `url` are written to the matching standard field; any other key becomes a custom field with that label.

## 3. Verify the Push

```bash
kubectl get pushsecret ksm-push-api-token
```{{execute}}

`STATUS` should be `Synced`. Now open your Keeper Vault: a new record titled **k8s-generated-api-token** is in the shared folder, with a custom field `api_token` holding the generated value.

To push a change right away instead of waiting for `refreshInterval`, annotate the PushSecret:

```bash
kubectl annotate pushsecret ksm-push-api-token force-sync=$(date +%s) --overwrite
```{{execute}}

> **Note**: Editing the Kubernetes Secret does not push immediately. The new value reaches Keeper on the next `refreshInterval` or when you force a sync as shown above.

## 4. Important: One Field per New Record

External Secrets writes **one field** when it creates a Keeper record, and afterwards can only update fields that already exist on it. That means pushing two keys (for example a username and a password) into the **same new record** does not work:

- For `login`/`password`/`url` keys, the second key is silently skipped even though the PushSecret shows `Synced`.
- For any other key, the PushSecret fails with `does not contain any custom field with label <key>`.

Two ways to push several values:

- **Push each value to its own record**, as this step does.
- **Pre-create the record** in Keeper, titled as in `remoteKey`, with record type `externalSecrets` and every field you will push. External Secrets then only updates the existing fields.
