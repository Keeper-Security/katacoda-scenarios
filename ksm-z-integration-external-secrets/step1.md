
### Install External Secrets Helm Chart

#### 1. Add external-secrets Helm repository
```
helm repo add external-secrets https://charts.external-secrets.io
```{{execute}}

#### 2. Install external-secrets Helm Chart
```
helm install external-secrets \
external-secrets/external-secrets \
-n external-secrets \
--create-namespace
```{{execute}}

### Create Secret to store KSM Config Base64
 
Create regular Kubernetes Secret to store KSM Config Base64 
that will be used by External Secrets to authenticate against Keeper Security.

> Replace [KSM CONFIG] with the Base64 encoded KSM Config

```shell
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ksm-config-secret                 # name of the k8s Secret where KSM config is stored
type: Opaque
data:
  ksm_config: "[KSM CONFIG]"                # Base64 encoded KSM Config
EOF
```{{copy}}


### Create SecretStore and ExternalSecret

> Replace [SHARED FOLDER UID] with the UID of the shared folder in Keeper Security where the records are stored.

```shell
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1   
kind: SecretStore
metadata:
  name: my-external-secrets-secretstore   # name of the SecretStore where retrieved secrets will be stored once fetched from Keeper Secrets Manager (KSM)
spec:
  provider:
    keepersecurity:                       # name of the SecretStore provider, in this case KeeperSecurity
      authRef:
        name: ksm-config-secret           # name of the k8s Secret where KSM config is stored
        key: ksm_config                   # key in the k8s Secret where KSM config is stored
      folderID: "[SHARED FOLDER UID]"     # UID of the shared folder in KeeperSecurity where the records 
                                          #   are stored. Make sure the folder is shared into the KSM Application
EOF
```{{copy}}

> Replace [RECORD UID] with the UID of the record in Keeper Security where the secrets are stored.

```shell
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
 name: ksm-external-secret
spec:
 refreshInterval: 30s                     # rate how often SecretManager pulls KeeperSecurity. 
                                          #   In this case every 30 seconds, for the example. 
                                          #   We recommend this value to be 12 hours or more.
 secretStoreRef:                          # reference to the SecretStore defined above to authenticate against Keeper Security
   kind: SecretStore                      # tells External Secrets the type of the secret store, should be same as the one defined above
   name: my-external-secrets-secretstore  

 dataFrom:                                # tells External Secrets which record to use to fetch from Keeper Secrets Manager (KSM)
   - extract:
       key: "[RECORD UID]"                # UID of the record in Keeper where the secrets are going to be fetched from
 target:                                  # tells External Secrets the target location where to store the secrets once fetched from Keeper Security
   name: my-external-secrets-values       # name of the k8s Secret to be created
   creationPolicy: Owner                  # tells External Secrets to create the k8s Secret if it doesn't exist
   template:
     engineVersion: v2          
     data:
       username: "{{ .login }}"           # tells External Secrets to store the value of 
                                          #   the login field in Keeper Security into the k8s Secret under the key username
       password: "{{ .password }}"        # tells External Secrets to store the value of 
                                          #   the password field in Keeper Security into the k8s Secret under the key password
EOF
```{{copy}}


