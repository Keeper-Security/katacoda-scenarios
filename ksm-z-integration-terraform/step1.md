
<pre class="file" data-filename="main.tf" data-target="replace">
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = ">= 1.0.0"
    }
  }
}

provider "secretsmanager" {
  credential = "[CONFIG JSON or BASE64]"
  # credential = file("~/.keeper/config.json")
}

data "secretsmanager_login" "kc-secret" {
  path       = "[UID TO LOGIN TYPE RECORD]"
}

output "kc_secret_login" {
  value = data.secretsmanager_login.kc-secret.login
}

output "kc_secret_password" {
  value = data.secretsmanager_login.kc-secret.password
  sensitive = true
}
</pre>

### Replace credentials in main.tf file

- Replace `[CONFIG JSON or BASE64]` that was obtained via Commander
- Replace `[UID TO LOGIN TYPE RECORD]` with your UID

### Navigate to the example folder

`cd terraform-example`{{execute}}

## Initialize Terraform
`terraform init`{{execute}}

Execute Terraform steps
`terraform apply -auto-approve`{{execute}}

View terraform state file.
`terraform.tfstate`{{open}}

