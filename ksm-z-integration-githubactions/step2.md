### Step 2: Configure and Use KSM in GitHub Action

Now that you have your KSM Application Configuration stored as a GitHub secret, you can use the `Keeper-Security/ksm-action` in your GitHub Actions workflow to fetch secrets from your Keeper Vault.

**1. Add the Keeper Secrets Manager Action to Your Workflow**

In your new or existing GitHub Action workflow file (e.g., `.github/workflows/main.yml`), add the following step. This step will retrieve specified secrets and make them available to subsequent steps in your job.

```yaml
      - name: Retrieve secrets from KSM
        id: ksmsecrets
        uses: Keeper-Security/ksm-action@master
        with:
          keeper-secret-config: ${{ secrets.KSM_CONFIG }}
          secrets: |
            # Map a record field to a step output (default behavior)
            BediNKCMG21ztm5xGYgNww/field/password > API_KEY

            # Map a custom field to an environment variable
            Atu0bVMOZLlkX63sKqGzUQ/custom_field/signing.keyId > env:SIGNING_KEY_ID

            # Download a file attachment from a record
            f7g8H9jK0lMnOpQ1rStUvW/file/private-key.asc > file:/tmp/signing_key.asc

            # You can also reference records by title instead of UID
            Production Database/field/login > env:DB_USERNAME
            Production Database/field/password > env:DB_PASSWORD

      # Use the fetched secrets in subsequent steps
      - name: Use Fetched Secrets
        run: |
          echo "API Key (masked): ${{ steps.ksmsecrets.outputs.API_KEY }}"
          echo "Signing Key ID: $SIGNING_KEY_ID"
          echo "DB Username: $DB_USERNAME"
          if [ -f /tmp/signing_key.asc ]; then
            echo "Signing key file written successfully"
          fi
```{{copy}}

> **Tip:** You can also pin to a specific version tag (e.g., `@v1` or `@v1.2.0`) instead of `@master` for additional stability.

**2. Understanding the `secrets` Mapping**

The `secrets` input is a multi-line string where each line defines a secret to fetch using [Keeper Notation](https://docs.keeper.io/secrets-manager/secrets-manager/about/keeper-notation) and its destination within the GitHub Actions runner:

-   **`KEEPER_NOTATION > SECRET_NAME` (Default - Step Output)**: Fetches the secret value and makes it available as an output of the `ksmsecrets` step. Reference it in subsequent steps using `${{ steps.ksmsecrets.outputs.SECRET_NAME }}`.
    -   Example: `BediNKCMG21ztm5xGYgNww/field/password > API_KEY`

-   **`KEEPER_NOTATION > env:ENV_VARIABLE_NAME` (Environment Variable)**: Fetches the secret value and sets it as an environment variable for subsequent steps in the current job.
    -   Example: `Atu0bVMOZLlkX63sKqGzUQ/custom_field/signing.keyId > env:SIGNING_KEY_ID`

-   **`KEEPER_NOTATION > file:FILEPATH` (File)**: For `field` or `custom_field` types, this saves the secret's value into the specified file. For `file` notation (e.g., `UID/file/FILENAME`), it downloads the file attachment from the Keeper record and saves it to `FILEPATH` on the runner.
    -   Example: `f7g8H9jK0lMnOpQ1rStUvW/file/private-key.asc > file:/tmp/signing_key.asc`

**3. Record Identification**

You can reference records in two ways:
-   **By UID** (22-character Base64 identifier): `BediNKCMG21ztm5xGYgNww/field/password`
-   **By Title** (human-readable record name): `Production Database/field/password`

Using titles makes workflows more readable, but UIDs are more precise when multiple records share the same name.

**4. Real-World Examples**

Here are patterns used in production by the Keeper Secrets Manager team:

**Retrieve an NPM token for publishing:**

```yaml
      - name: Retrieve NPM token from KSM
        id: ksmsecrets
        uses: Keeper-Security/ksm-action@master
        with:
          keeper-secret-config: ${{ secrets.KSM_CONFIG }}
          secrets: |
            NScQiZwrHJFCPv1gL8TX6Q/field/password > env:NPM_TOKEN
```{{copy}}

**Download a certificate file and retrieve its passphrase:**

```yaml
      - name: Retrieve signing certificate from KSM
        id: ksmsecrets
        uses: Keeper-Security/ksm-action@master
        with:
          keeper-secret-config: ${{ secrets.KSM_CONFIG }}
          secrets: |
            9QY3bC2MXN-HaMMfpUHbGQ/file/keepersecurity.pfx > file:/tmp/keepersecurity.pfx
            9QY3bC2MXN-HaMMfpUHbGQ/custom_field/PFX Password > PASSPHRASE
```{{copy}}

**5. Full Workflow Example**

Here is a complete workflow file that retrieves secrets and uses them in a deployment:

```yaml
name: Deploy with KSM Secrets
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Retrieve secrets from Keeper
        id: ksmsecrets
        uses: Keeper-Security/ksm-action@master
        with:
          keeper-secret-config: ${{ secrets.KSM_CONFIG }}
          secrets: |
            Production Database/field/login > env:DB_USER
            Production Database/field/password > env:DB_PASS
            Deploy SSH Key/file/id_rsa > file:~/.ssh/deploy_key

      - name: Deploy application
        run: |
          chmod 600 ~/.ssh/deploy_key
          ./scripts/deploy.sh
```{{copy}}

**Important:**
-   **Replace Placeholders**: Replace the example UIDs and record titles with those from your own Keeper Vault.
-   **Case Sensitivity**: Output names (e.g., `API_KEY`) are case-sensitive when referenced via `steps.ksmsecrets.outputs.API_KEY`.
-   **Automatic Masking**: All fetched secret values are automatically masked in GitHub Actions logs — you do not need to manually add masking.
-   **Official Documentation**: For comprehensive details on notation options and advanced usage, refer to the [official Keeper Secrets Manager GitHub Action documentation](https://docs.keeper.io/secrets-manager/secrets-manager/integrations/github-actions) and the [GitHub Marketplace page](https://github.com/marketplace/actions/keeper-secrets-manager).

After adding this step to your workflow and committing the changes, your GitHub Action will securely fetch the defined secrets from Keeper Secrets Manager each time it runs.
