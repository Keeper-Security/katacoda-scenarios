# Step 1: Installation & First Connection

**Learning Objective**: Connect to Keeper Secrets Manager and retrieve your first secrets in under 2 minutes.

## What You'll Accomplish

In this step, you'll:
- Install the KSM Ruby SDK gem
- Connect to your Keeper vault using a base64 configuration
- List all accessible secrets
- Understand the basic SDK initialization pattern

## Why This Matters

**Business Benefits:**
- **Eliminate hardcoded credentials** from your Ruby applications
- **Centralize secret management** across teams and applications
- **Audit access** to sensitive credentials automatically

**Technical Benefits:**
- **Zero-knowledge architecture** - secrets encrypted end-to-end
- **Simple Ruby API** - works with any Ruby 3.1+ application
- **No external dependencies** -just OpenSSL (built into Ruby)

## 1. Verify Installation

The KSM gem is already installed in this environment. Let's verify it:

```bash
gem list keeper_secrets_manager
```{{execute}}

**✅ Expected Output:**
```
keeper_secrets_manager (17.1.0)
```

You can also check the Ruby version:

```bash
ruby --version
```{{execute}}

## 2. Understanding KSM Configuration

KSM requires a configuration to authenticate. You have two options:

### Option A: Base64-Encoded Configuration (Recommended for this tutorial)

A base64 string containing your KSM application credentials. This is obtained after binding your one-time token.

### Option B: One-Time Access Token

A token in the format `US:BASE64_STRING` that is bound once to create a persistent configuration.

## 3. Create Your First Connection Script

Let's create a simple Ruby script to connect and list secrets. Create the `connect.rb` file:

```
cat > connect.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

puts "Keeper Secrets Manager - Ruby SDK Demo"
puts "=" * 50
puts ""

# SECURITY WARNING
# Replace [YOUR_BASE64_CONFIG_HERE] with your actual test configuration
# NEVER use production credentials in tutorials!
# NEVER commit this config to version control!

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

begin
  # Step 1: Initialize storage with base64 configuration
  puts "Connecting to Keeper Secrets Manager..."
  storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)

  # Step 2: Create the SecretsManager client
  secrets_manager = KeeperSecretsManager.new(config: storage)

  puts "Successfully connected!"
  puts ""

  # Step 3: Retrieve all secrets
  puts "Fetching secrets..."
  secrets = secrets_manager.get_secrets

  puts "Found #{secrets.length} secret(s)"
  puts ""

  # Step 4: Display basic information
  if secrets.any?
    puts "Your Secrets:"
    puts "-" * 50

    secrets.each_with_index do |secret, index|
      puts "#{index + 1}. #{secret.title}"
      puts "   UID: #{secret.uid}"
      puts "   Type: #{secret.type}"
      puts ""
    end
  else
    puts "WARNING: No secrets found. Create some secrets in Keeper first."
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"
  puts ""
  puts "Troubleshooting:"
  puts "- Verify your base64 config is correct"
  puts "- Check your KSM application has access to secrets"
  puts "- Ensure your configuration hasn't expired"
  exit 1

rescue StandardError => e
  puts "ERROR: Unexpected Error: #{e.class} - #{e.message}"
  exit 1
end

puts "=" * 50
puts "Connection successful! Ready for Step 2."
EOF
```{{execute}}

**Code reference** (for copying/editing):

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

puts "Keeper Secrets Manager - Ruby SDK Demo"
puts "=" * 50
puts ""

# SECURITY WARNING
# Replace [YOUR_BASE64_CONFIG_HERE] with your actual test configuration
# NEVER use production credentials in tutorials!
# NEVER commit this config to version control!

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

begin
  # Step 1: Initialize storage with base64 configuration
  puts "Connecting to Keeper Secrets Manager..."
  storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)

  # Step 2: Create the SecretsManager client
  secrets_manager = KeeperSecretsManager.new(config: storage)

  puts "Successfully connected!"
  puts ""

  # Step 3: Retrieve all secrets
  puts "Fetching secrets..."
  secrets = secrets_manager.get_secrets

  puts "Found #{secrets.length} secret(s)"
  puts ""

  # Step 4: Display basic information
  if secrets.any?
    puts "Your Secrets:"
    puts "-" * 50

    secrets.each_with_index do |secret, index|
      puts "#{index + 1}. #{secret.title}"
      puts "   UID: #{secret.uid}"
      puts "   Type: #{secret.type}"
      puts ""
    end
  else
    puts "WARNING: No secrets found. Create some secrets in Keeper first."
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"
  puts ""
  puts "Troubleshooting:"
  puts "- Verify your base64 config is correct"
  puts "- Check your KSM application has access to secrets"
  puts "- Ensure your configuration hasn't expired"
  exit 1

rescue StandardError => e
  puts "ERROR: Unexpected Error: #{e.class} - #{e.message}"
  exit 1
end

puts "=" * 50
puts "Connection successful! Ready for Step 2."
```{{copy}}

## 4. Set Your Configuration

Before running the script, set your KSM configuration as an environment variable:

```bash
export KSM_CONFIG="YOUR_BASE64_CONFIG_HERE"
```{{copy}}

**🔒 Security Note:** Replace `YOUR_BASE64_CONFIG_HERE` with your actual base64-encoded KSM configuration.

## 5. Run the Connection Script

Execute the script to connect and list your secrets:

```bash
ruby connect.rb
```{{execute}}

**✅ Expected Output:**

```
🔐 Keeper Secrets Manager - Ruby SDK Demo
==================================================

📡 Connecting to Keeper Secrets Manager...
✅ Successfully connected!

📋 Fetching secrets...
✅ Found 3 secret(s)

Your Secrets:
--------------------------------------------------
1. Production Database
   UID: lPxZXk...
   Type: login

2. AWS API Keys
   UID: mQyAYl...
   Type: login

3. Stripe Webhook Secret
   UID: nRzBZm...
   Type: login

==================================================
✅ Connection successful! Ready for Step 2.
```

## 🔍 Understanding the Code

Let's break down what happened:

### 1. **InMemoryStorage Initialization**
```ruby
storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
```
- Creates an in-memory storage backend with your configuration
- No files are created - everything stays in memory
- Perfect for serverless functions and containers

### 2. **SecretsManager Client Creation**
```ruby
secrets_manager = KeeperSecretsManager.new(config: storage)
```
- Initializes the main KSM client
- Validates your configuration
- Establishes connection parameters

### 3. **Fetching Secrets**
```ruby
secrets = secrets_manager.get_secrets
```
- Retrieves ALL secrets your KSM application can access
- Returns an array of `KeeperRecord` objects
- Automatically decrypts secrets client-side

### 4. **Accessing Secret Properties**
```ruby
secret.title  # Human-readable name
secret.uid    # Unique identifier
secret.type   # Record type (login, password, etc.)
```

## Alternative: Using a One-Time Token

If you have a one-time token instead of a base64 config, you can initialize like this:

```ruby
# Using a one-time token (binds automatically)
token = "US:BASE64_TOKEN_HERE"

# Option 1: Create file-based storage (persists config)
storage = KeeperSecretsManager::Storage::FileStorage.new('config.json')
secrets_manager = KeeperSecretsManager.new(
  config: storage,
  token: token
)

# The token is bound and config.json is created automatically
secrets = secrets_manager.get_secrets
```{{copy}}

**Note:** After the first run, you can omit the `token` parameter and just use the stored configuration.

## 🛠️ Common Configuration Methods

The SDK supports multiple initialization patterns:

### Method 1: In-Memory Storage (Stateless)
```ruby
storage = KeeperSecretsManager::Storage::InMemoryStorage.new(base64_config)
sm = KeeperSecretsManager.new(config: storage)
```
**Use when:** Serverless functions, containers, temporary scripts

### Method 2: File-Based Storage (Persistent)
```ruby
storage = KeeperSecretsManager::Storage::FileStorage.new('ksm_config.json')
sm = KeeperSecretsManager.new(config: storage)
```
**Use when:** Long-running applications, local development

### Method 3: Convenience Method
```ruby
sm = KeeperSecretsManager.from_token(one_time_token)
```
**Use when:** First-time setup with a one-time token

## Troubleshooting

### Error: "Either token or initialized config must be provided"
- **Cause:** No configuration or token provided
- **Solution:** Set `KSM_CONFIG` environment variable or provide token

### Error: "Failed to bind one-time token"
- **Cause:** Invalid or expired token
- **Solution:** Generate a new one-time token from Keeper Vault

### Error: "No secrets found"
- **Cause:** Your KSM application has no secrets shared with it
- **Solution:** Share secrets with your KSM application in Keeper Vault

### Error: "KSM SDK requires Ruby 2.6 or greater"
- **Cause:** Ruby version too old
- **Solution:** Upgrade to Ruby 3.1+ (required for production use)

## 🔒 Security Best Practices

✅ **DO:**
- Use environment variables for configuration (`ENV['KSM_CONFIG']`)
- Create separate KSM applications for dev/staging/prod
- Rotate one-time tokens regularly
- Use file-based storage with proper permissions (0600)

❌ **DON'T:**
- Hardcode base64 configs in source code
- Commit configuration files to git (add to `.gitignore`)
- Share configurations between applications
- Log the full configuration string

## Next Steps

🎉 **Congratulations!** You've successfully:
- Installed the KSM Ruby SDK
- Connected to your Keeper vault
- Retrieved and listed your secrets

In **Step 2**, you'll learn how to:
- Access specific fields (login, password, URL)
- Search for secrets by title
- Work with custom fields
- Handle different field types

Click **"Continue"** to proceed to Step 2: Reading Secrets & Fields.
