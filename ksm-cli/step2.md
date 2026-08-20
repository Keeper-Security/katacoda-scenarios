# Step 2: Secret Management Operations

**Learning Objective**: Learn to retrieve, search, and manage secrets securely from the command line.

## Understanding Secret Types

Keeper stores different types of secrets:
- **login**: Username/password combinations
- **databaseCredentials**: Database connection info
- **bankCard**: Credit card details
- **file**: Secure file attachments
- **custom types**: Organization-specific record types

## List All Available Secrets

Start by viewing all secrets accessible to your KSM CLI:

```bash
ksm secret list
```
`ksm secret list`{{execute}}

**✅ Expected Output**: A table with three columns:
- **UID**: Unique identifier (like `qcXHCwsYTeCRSmIUD29o9g`)
- **Record Type**: Type of secret (login, database, etc.)
- **Title**: Human-readable name

**🔍 What you're seeing**: Each row represents a secret record in your vault that this application can access.

## Get Detailed Secret Information

To view detailed information about a specific secret, use its UID (the long string from the first column):

```bash
ksm secret get [UID]
```
`ksm secret get [UID]`{{copy}}

**⚠️ Action Required**: Replace `[UID]` with an actual UID from your secret list above.

**✅ Expected Output**: Shows all fields in the record including passwords, usernames, URLs, and custom fields.

**🔒 Security Note**: Sensitive data is displayed in plaintext. Ensure your terminal is secure.

**💡 Pro Tip**: Use `--unmask` to show passwords in table views: `ksm secret get [UID] --unmask`

## Retrieve Specific Fields

You can retrieve specific fields from a secret:

### Get Password Only
```bash
ksm secret get [UID] --field password
```
`ksm secret get [UID] --field password`{{copy}}

### Get Username Only
```bash
ksm secret get [UID] --field login
```
`ksm secret get [UID] --field login`{{copy}}

### Get Custom Fields
```bash
ksm secret get [UID] --field [FIELD_NAME]
```
`ksm secret get [UID] --field [FIELD_NAME]`{{copy}}

### Get Record Notes

Record notes are **not** a field. They are a record-level property, so `--field notes` fails with `Cannot find the field notes in record ...`. Use a JSONPath query instead:

```bash
ksm secret get [UID] --query notes --raw
```
`ksm secret get [UID] --query notes --raw`{{copy}}

**💡 Why `--raw`?**: Without it the value is returned JSON-encoded, wrapped in double quotes, which is awkward when assigning it to a variable.

**⚠️ Watch Out**: `--field` matches field labels first, then field types. If a record happens to have a custom field *labeled* "notes", then `--field notes` returns that custom field's value instead of the record notes, with no error to warn you.

## Search for Secrets

Search for secrets by title using regex pattern matching:

```bash
ksm secret list --title "database"
```
`ksm secret list --title "database"`{{copy}}

**✅ Expected Output**: Only secrets with "database" in the title.

**💡 Tip**: Use patterns like `"test"`, `"prod"`, or `"api"` to find specific types of secrets quickly.

## Update Secret Fields

You can update secret fields directly from the CLI:

### Update Password
```bash
ksm secret update --uid [UID] --field password=MyNewPassword123!
```
`ksm secret update --uid [UID] --field password=MyNewPassword123!`{{copy}}

### Update Username
```bash
ksm secret update --uid [UID] --field login=newusername
```
`ksm secret update --uid [UID] --field login=newusername`{{copy}}

### Update Custom Fields
```bash
ksm secret update --uid [UID] --custom-field [FIELD_NAME]=[NEW_VALUE]
```
`ksm secret update --uid [UID] --custom-field [FIELD_NAME]=[NEW_VALUE]`{{copy}}

## Additional Secret Operations

You can perform various operations with your secrets. The KSM CLI provides comprehensive access to secret data and metadata.

## Record Caching for Performance

**Why use caching?** 
- Improves performance for repeated secret access
- Provides offline access if network fails
- Reduces API calls in scripts and automation

### Enable Caching
```bash
ksm config cache --enable
```
`ksm config cache --enable`{{execute}}

**✅ Expected Output**: No output means success.

### Verify Caching is Enabled
```bash
ksm config show
```
`ksm config show`{{execute}}

**✅ Look for**: `Cache Enabled: True`

### Test Cached Access
Compare performance between first and second retrieval:

```bash
# First retrieval - fetches from server and caches
ksm --cache secret list
```
`ksm --cache secret list`{{execute}}

```bash
# Second retrieval - uses cached data (faster)
ksm --cache secret list
```
`ksm --cache secret list`{{execute}}

**🔍 What happened?** The second command should be noticeably faster.

### Cache Location Control
By default, cache is stored as `ksm_cache.bin` in the current directory. You can customize the location:

```bash
mkdir /tmp/ksm_cache
export KSM_CACHE_DIR="/tmp/ksm_cache"
ksm --cache secret list
```

`mkdir /tmp/ksm_cache && \ 
export KSM_CACHE_DIR="/tmp/ksm_cache" && \
ksm --cache secret list`{{execute}}

### Disable Caching
```bash
ksm config cache --disable
```
`ksm config cache --disable`{{execute}}

**💡 Real-world use case**: Enable caching in CI/CD pipelines to avoid repeated API calls and improve build performance.

## Working with Secret Data

The KSM CLI provides flexible ways to retrieve and work with your secret data. You can get specific fields, search by title, and use the data in scripts and automation.

**⚠️ Security Best Practices**:
- Never log secrets to files or console output
- Use secrets directly in memory when possible
- Avoid storing secrets in environment variables in production
- Clear terminal history after working with secrets

**💡 Next Steps**: In Step 3, you'll learn how to work with file attachments, and in Step 4, you'll learn automation techniques for using these secrets in scripts and CI/CD pipelines.

**📚 Official Documentation**: [KSM CLI Reference Guide](https://docs.keeper.io/en/keeperpam/secrets-manager/secrets-manager-command-line-interface)
