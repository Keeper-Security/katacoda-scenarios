
### 1. Install Microsoft PowerShell Secret Management Module:

`Install-Module -Name Microsoft.PowerShell.SecretManagement -Force`{{execute}}

### 2. Install Keeper Secrets Manager for PowerShell
`Install-Module -Name SecretManagement.Keeper -Force`{{execute}}

### 3. Install Secrets Management extension

`Install-Module -Name Microsoft.Powershell.SecretStore -Force`{{execute}}

### 4. Register a Vault to use for Configuration Storage

`Register-SecretVault -Name MyLocalStore -ModuleName Microsoft.Powershell.SecretStore`{{execute}}

### 5. Register the Keeper Vault

[Go here](https://docs.keeper.io/secrets-manager/secrets-manager/quick-start-guide#create-a-secrets-manager-client-device) for instructions to generate One-Time Token

_Note: Make sure permission for the new Application is set to "Editable" if you want to modify secrets_

`Register-KeeperVault -Name MyKeeperVault -LocalVaultName MyLocalStore -OneTimeToken [ONE-TIME TOKEN]`{{copy}}
