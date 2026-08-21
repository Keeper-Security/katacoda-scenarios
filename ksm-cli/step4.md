# Step 4: Advanced Usage & Automation

**Learning Objective**: Learn automation techniques for CI/CD pipelines, scripts, and production deployments.

## Prerequisites
You'll use these techniques when:
- Building CI/CD pipelines (GitHub Actions, Jenkins, etc.)
- Creating deployment scripts
- Setting up containerized applications
- Automating secret rotation

## Environment Variable Configuration

**Why use environment variables?** In production and CI/CD environments, you can't store config files. Environment variables provide a secure way to pass configuration.

### Export Configuration to Environment Variable

First, export your profile configuration as Base64-encoded data:

```bash
ksm profile export
```
`ksm profile export`{{execute}}

**✅ Expected Output**: A long Base64-encoded string (your encrypted configuration).

### Set Configuration as Environment Variable

Copy the output and set it as an environment variable:

```bash
export KSM_CONFIG='[PASTE_THE_BASE64_OUTPUT_HERE]'
```
`export KSM_CONFIG='[PASTE_THE_BASE64_OUTPUT_HERE]'`{{copy}}

**⚠️ Action Required**: Replace the placeholder with the actual Base64 string from the previous command.

### Test Environment Variable Configuration

Verify that KSM CLI works with the environment variable:

```bash
ksm secret list
```
`ksm secret list`{{execute}}

**🔍 What happened?** KSM CLI used the environment variable instead of the local config file.

## Secret Notation for Automation

**Notation syntax** provides a URL-like way to reference specific secret fields in scripts. Format: `keeper://[UID]/field/[field_name]`

### Get Password Using Notation
Use a UID from your secret list:

```bash
export MY_PASSWORD=$(ksm secret notation keeper://[RECORD_UID]/field/password)
```
`export MY_PASSWORD=$(ksm secret notation keeper://[RECORD_UID]/field/password)`{{copy}}

**⚠️ Action Required**: Replace `[RECORD_UID]` with an actual UID from Step 2.

### Verify the Retrieved Password
```bash
echo "Password retrieved: $MY_PASSWORD"
```
`echo "Password retrieved: $MY_PASSWORD"`{{execute}}

**✅ Expected Output**: Shows the actual password from your secret.

### Get Other Fields Using Notation
Common field types: `login`, `password`, `url`

```bash
export MY_USERNAME=$(ksm secret notation keeper://[RECORD_UID]/field/login)
export MY_URL=$(ksm secret notation keeper://[RECORD_UID]/field/url)
```
`export MY_USERNAME=$(ksm secret notation keeper://[RECORD_UID]/field/login)`{{copy}}

**💡 Pro Tip**: Use `ksm secret get [UID]` first to see all available field names for a record.

### Get Record Notes, Title, and Type Using Notation

`notes`, `title`, and `type` are record-level **selectors**, not fields. They replace the `field/[field_name]` portion of the notation rather than appearing inside it:

```bash
export MY_NOTES=$(ksm secret notation keeper://[RECORD_UID]/notes)
export MY_TITLE=$(ksm secret notation keeper://[RECORD_UID]/title)
```
`export MY_NOTES=$(ksm secret notation keeper://[RECORD_UID]/notes)`{{copy}}

**⚠️ Common Mistake**: `keeper://[UID]/field/notes` does **not** work. Notation looks for a *field* named or typed "notes", which standard record types do not have. Use `keeper://[UID]/notes` instead.

**📝 Note**: The `encryptedNotes` record type also has a genuine field of type `note` (singular), reachable as `keeper://[UID]/field/note`. That is separate from the record-level `notes` property that every record has.

## File Operations

KSM CLI can handle file attachments and downloads:

### Download a File from a Secret
```bash
ksm secret download --uid [RECORD_UID] --name "certificate.pem" --file-output "/tmp/certificate.pem"
```
`ksm secret download --uid [RECORD_UID] --name "certificate.pem" --file-output "/tmp/certificate.pem"`{{copy}}

### Verify Downloaded File
```bash
file /tmp/certificate.pem
ls -la /tmp/certificate.pem
```
`file /tmp/certificate.pem`{{execute}}

### Upload a File to a Secret
```bash
ksm secret upload --uid [RECORD_UID] --file "/path/to/local/file.txt"
```
`ksm secret upload --uid [RECORD_UID] --file "/path/to/local/file.txt"`{{copy}}

## Real-World Automation Examples

### Database Connection Script
Securely connect to databases without hardcoded credentials:

```bash
#!/bin/bash
# Get database credentials from Keeper
DB_HOST=$(ksm secret notation keeper://[DB_RECORD_UID]/field/url)
DB_USER=$(ksm secret notation keeper://[DB_RECORD_UID]/field/login)
DB_PASS=$(ksm secret notation keeper://[DB_RECORD_UID]/field/password)

# Connect to database
psql "postgresql://$DB_USER:$DB_PASS@$DB_HOST/myapp"
```

**⚠️ Replace**: `[DB_RECORD_UID]` with a database record UID from your vault.

### API Integration Script
Securely use API keys in automated requests:

```bash
#!/bin/bash
# Get API key from Keeper
API_KEY=$(ksm secret notation keeper://[API_RECORD_UID]/field/password)

# Make authenticated API request
curl -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     https://api.example.com/v1/data
```

**🔒 Security Benefit**: API keys are never stored in code or config files.

## CI/CD Integration Examples

### GitHub Actions Integration
Add KSM_CONFIG as a repository secret, then use it in workflows:

```yaml
steps:
  - name: Install KSM CLI
    run: pip install keeper-secrets-manager-cli
    
  - name: Get secrets from Keeper
    env:
      KSM_CONFIG: ${{ secrets.KSM_CONFIG }}
    run: |
      export DB_PASSWORD=$(ksm secret notation keeper://[DB_UID]/field/password)
      export API_KEY=$(ksm secret notation keeper://[API_UID]/field/password)
      # Use secrets in deployment
      ./deploy.sh
```

### Docker Integration
Inject secrets into containers without Dockerfiles containing credentials:

```bash
# Get secret and pass to container
DB_PASS=$(ksm secret notation keeper://[UID]/field/password)
docker run -e DATABASE_PASSWORD="$DB_PASS" myapp:latest
```

**🔒 Security Benefit**: Secrets never appear in Docker images or container definitions.

## Advanced Configuration

### Multiple Environment Profiles
Manage different environments (dev, staging, prod) with separate profiles:

```bash
# Create environment-specific profiles
ksm profile init --token [PROD_TOKEN] --profile-name production
ksm profile init --token [STAGING_TOKEN] --profile-name staging
```
`ksm profile init --token [TOKEN] --profile-name production`{{copy}}

```bash
# Use specific profile for commands
ksm --profile-name production secret list
```
`ksm --profile-name production secret list`{{copy}}

**💡 Use Case**: Different teams can access different vaults (prod vs staging) with the same CLI.

### Configuration Management
Useful commands for managing profiles and troubleshooting:

```bash
# Show current configuration
ksm config show
```
`ksm config show`{{execute}}

```bash
# List all available profiles
ksm profile list
```
`ksm profile list`{{execute}}

```bash
# Export profile for CI/CD use
ksm profile export
```
`ksm profile export`{{execute}}

## Security Best Practices for Production

### 🔒 Essential Security Rules
1. **Environment Variables**: Store `KSM_CONFIG` in secure CI/CD secret storage (never in code)
2. **Token Rotation**: Regularly generate new One-Time Access Tokens
3. **Least Privilege**: Grant applications access only to secrets they actually need
4. **No Logging**: Ensure secrets never appear in application logs or console output
5. **Error Handling**: Always handle cases where secret retrieval might fail

### ❌ Common Mistakes to Avoid
- Storing secrets in environment variables in production (use notation instead)
- Committing KSM_CONFIG to version control
- Using the same profile for all environments
- Not clearing terminal history after working with secrets

### ✅ Production-Ready Pattern
```bash
#!/bin/bash
set -e  # Exit on any error

# Verify KSM CLI is available
if ! command -v ksm &> /dev/null; then
    echo "Error: KSM CLI not installed"
    exit 1
fi

# Get secret with error handling
if DB_PASS=$(ksm secret notation keeper://[UID]/field/password 2>/dev/null); then
    # Use secret securely
    ./deploy-app.sh
else
    echo "Error: Could not retrieve database password"
    exit 1
fi
```

## Next Steps & Resources

**🎉 Congratulations!** You now know how to:
- Set up secure CLI access to your Keeper vault
- Retrieve and search secrets safely
- Use caching for performance
- Integrate secrets into automation and CI/CD pipelines
- Follow security best practices

### Getting Help
- Built-in help: `ksm --help`
- Command-specific help: `ksm secret --help`
- [Official KSM CLI Documentation](https://docs.keeper.io/en/keeperpam/secrets-manager/secrets-manager-command-line-interface)

### Real-World Applications
Now you can eliminate hardcoded secrets from:
- 💻 Application deployments
- 🚀 CI/CD pipelines  
- 📦 Docker containers
- 📄 Infrastructure scripts
- ☁️ Cloud configurations

**💡 Pro Tip**: Start with one application and gradually migrate all your secrets to Keeper for centralized, secure secret management.
