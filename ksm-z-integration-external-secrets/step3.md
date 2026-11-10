# Step 3: Custom Fields and Files

Real records usually hold more than a login and a password: API keys in custom fields, certificates or config files as attachments. In this step you'll pull both into Kubernetes and hand them to a pod as an environment variable and a mounted file.

## 1. Add a Custom Field and a File to Your Record

In your Keeper Vault, edit the record you used in Step 1 (`[RECORD UID]`):

1. Add a **custom field** (for example type *Text* or *Hidden Field*) with the label **`api_key`** and any value.
2. **Attach a small file**, for example a `.json`, `.pem` or `.txt` file. Note the file name exactly as the vault shows it on the record.
3. Save the record.

> **Important**: Replace `[FILE NAME]` below with the attachment's name as shown in the vault (for example `config.json`). External Secrets matches attachments by the name shown in the vault, which is the file's title. If you renamed the attachment in the vault, use the new name, not the original filename.

## 2. Create the ExternalSecret

No JSON parsing is needed: `property` takes the custom field's **label** or the attachment's **name** directly.

```bash
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: ksm-custom-and-files
spec:
  refreshInterval: 1h                     # how often to re-read the record from Keeper
  secretStoreRef:                         # same SecretStore as Step 1
    kind: SecretStore
    name: my-external-secrets-secretstore
  target:
    name: my-app-extras                   # Kubernetes Secret to create
  data:
    - secretKey: api-key                  # key name in the Kubernetes Secret
      remoteRef:
        key: "[RECORD UID]"               # the Keeper record
        property: "api_key"               # custom field: use its label
    - secretKey: app-file                 # key name in the Kubernetes Secret
      remoteRef:
        key: "[RECORD UID]"
        property: "[FILE NAME]"           # attachment: use its name as shown in the vault
EOF
```{{copy}}

Check that it synced (`STATUS` should be `SecretSynced`):

```bash
kubectl get externalsecret ksm-custom-and-files
```{{execute}}

## 3. Use Them in a Pod

The custom field becomes an environment variable and the attachment becomes a file under `/etc/keeper`:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: extras-demo
spec:
  restartPolicy: Never
  containers:
    - name: demo
      image: busybox
      command: ["sh", "-c", "echo API key is \$API_KEY; echo; echo File from Keeper:; cat /etc/keeper/app-file"]
      env:
        - name: API_KEY                   # environment variable for the app...
          valueFrom:
            secretKeyRef:
              name: my-app-extras         # ...from the Secret External Secrets created
              key: api-key
      volumeMounts:
        - name: keeper-files              # mount the Secret as files
          mountPath: /etc/keeper
          readOnly: true
  volumes:
    - name: keeper-files
      secret:
        secretName: my-app-extras
        items:
          - key: app-file                 # only mount the attachment...
            path: app-file                # ...as /etc/keeper/app-file
EOF
```{{execute}}

Wait a few seconds for the pod to finish, then read its output:

```bash
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/extras-demo --timeout=120s && kubectl logs extras-demo
```{{execute}}

You should see your custom field value and the contents of the attached file. Binary attachments (keystores, certificates in DER format) come through byte for byte as well.

## 4. Or Take the Whole Record

If you want everything at once, use `dataFrom.extract`. Every standard field, custom field and attachment becomes its own key:

```bash
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: ksm-whole-record
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: my-external-secrets-secretstore
  target:
    name: my-whole-record
  dataFrom:
    - extract:
        key: "[RECORD UID]"               # all fields, custom fields and files of this record
EOF
```{{copy}}

List the keys it created (sizes only, values stay hidden):

```bash
kubectl describe secret my-whole-record
```{{execute}}

Characters that are not allowed in Kubernetes Secret keys, such as spaces, are replaced with `_` (a custom field labelled `API Token` becomes the key `API_Token`). You will also see a `fileRef` key: it holds Keeper's internal IDs of the attachments and can be ignored.

## 5. Watch Out for Duplicate Names

External Secrets requires every field label, custom field label and attachment name in a record to be unique, **including** the names of standard fields such as `login`, `password` and `url`. If two of them collide, for example a custom field labelled `password` on a login record or two attachments with the same name, **the whole record fails** with `invalid Secret. Following keys are duplicated`, even for the fields you did not ask for. Rename one of them in the vault to fix it.

If an ExternalSecret does not sync, the detailed reason is in the operator logs:

```bash
kubectl logs -n external-secrets deploy/external-secrets | grep ksm-custom-and-files
```{{execute}}
