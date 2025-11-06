# Step 2: Reading Secrets & Fields

**Learning Objective**: Master reading specific fields from secrets, searching by title, and accessing various field types.

## What You'll Accomplish

In this step, you'll learn how to:
- Access common fields (login, password, URL) from secrets
- Search for secrets by title
- Work with custom fields
- Handle different field types programmatically
- Use the notation system for direct field access

## Why Field Access Matters

**Business Benefits:**
- **Automated credential rotation** - programmatically update passwords
- **Dynamic configuration** - inject secrets into applications at runtime
- **Audit trails** - track which fields are accessed and when

**Technical Benefits:**
- **Type-safe field access** - SDK provides helper methods for common types
- **Flexible search** - find secrets by title, UID, or custom attributes
- **Zero-knowledge security** - all decryption happens client-side

## 1. Basic Field Access

Let's create a script to read common fields from a secret:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

# Initialize (using config from Step 1)
KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Reading Secret Fields"
puts "=" * 60
puts ""

begin
  # Get all secrets
  secrets = secrets_manager.get_secrets

  if secrets.empty?
    puts "WARNING: No secrets found. Add secrets to your Keeper vault first."
    exit 0
  end

  # Use the first secret as an example
  secret = secrets.first

  puts "Secret: #{secret.title}"
  puts "-" * 60
  puts ""

  # Access common fields using convenience methods
  puts "Common Fields:"
  puts "  Login:    #{secret.login || '(not set)'}"
  puts "  Password: #{'*' * 12} (hidden)"
  puts "  URL:      #{secret.url&.first || '(not set)'}"
  puts ""

  # Access fields directly
  puts "All Fields:"
  secret.fields.each do |field|
    field_type = field['type']
    field_value = field['value']

    # Don't print passwords in full
    if field_type == 'password'
      puts "  #{field_type}: #{'*' * 12} (hidden)"
    elsif field_value.is_a?(Array)
      field_value.each { |v| puts "  #{field_type}: #{v}" }
    else
      puts "  #{field_type}: #{field_value}"
    end
  end

  # Access custom fields
  if secret.custom && secret.custom.any?
    puts ""
    puts "Custom Fields:"
    secret.custom.each do |custom_field|
      label = custom_field['label']
      value = custom_field['value']
      puts "  #{label}: #{value.is_a?(Array) ? value.first : value}"
    end
  end

  # Access notes
  if secret.notes && !secret.notes.empty?
    puts ""
    puts "Notes:"
    puts "  #{secret.notes[0..100]}#{'...' if secret.notes.length > 100}"
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"
  exit 1
end

puts ""
puts "=" * 60
puts "Field access demonstration complete"
```{{copy}}

Save this as `read_fields.rb` and run it:

```bash
ruby read_fields.rb
```{{execute}}

**✅ Expected Output:**
```
🔍 Reading Secret Fields
============================================================

Secret: Production Database
------------------------------------------------------------

📋 Common Fields:
  Login:    db_admin
  Password: ************ (hidden)
  URL:      https://db.example.com:5432

📦 All Fields:
  login: db_admin
  password: ************ (hidden)
  url: https://db.example.com:5432
  url: https://db-replica.example.com:5432

🔧 Custom Fields:
  Environment: production
  Owner: DevOps Team

📝 Notes:
  Primary PostgreSQL database. Rotate password quarterly...

============================================================
✅ Field access demonstration complete
```

## 2. Searching Secrets by Title

Often you need to find a specific secret by name:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Searching Secrets by Title"
puts "=" * 60
puts ""

# Search for a secret by exact title
secret_title = "Production Database"  # Change this to match your secret
found_secret = secrets_manager.get_secret_by_title(secret_title)

if found_secret
  puts "Found: #{found_secret.title}"
  puts "   UID: #{found_secret.uid}"
  puts "   Login: #{found_secret.login}"
  puts ""
else
  puts "No secret found with title: '#{secret_title}'"
  puts ""
  puts "Available secrets:"
  secrets_manager.get_secrets.each { |s| puts "  - #{s.title}" }
end

# Search for multiple secrets matching a pattern
puts "Searching for secrets containing 'Database':"
puts "-" * 60

all_secrets = secrets_manager.get_secrets
matching = all_secrets.select { |s| s.title.downcase.include?('database') }

if matching.any?
  matching.each_with_index do |secret, index|
    puts "#{index + 1}. #{secret.title}"
    puts "   Login: #{secret.login || '(none)'}"
    puts ""
  end
  puts "Found #{matching.length} matching secret(s)"
else
  puts "WARNING: No secrets found matching 'Database'"
end
```{{copy}}

Save as `search_secrets.rb` and run:

```bash
ruby search_secrets.rb
```{{execute}}

## 3. Working with Different Field Types

The KSM Ruby SDK supports many field types. Here's how to work with them:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Field Type Examples"
puts "=" * 60
puts ""

begin
  secret = secrets_manager.get_secrets.first

  # Text fields (login, password, url)
  puts "Text Fields:"
  puts "  Login: #{secret.login}"
  puts "  URL: #{secret.url&.first}"
  puts ""

  # Get field value using helper method
  phone = secret.get_field_value_single('phone')
  if phone
    puts "Phone Field:"
    puts "  Number: #{phone['number']}"
    puts "  Region: #{phone['region']}"
    puts "  Type: #{phone['type']}"
    puts ""
  end

  # Name field
  name = secret.get_field_value_single('name')
  if name
    puts "Name Field:"
    puts "  First: #{name['first']}"
    puts "  Last: #{name['last']}"
    puts ""
  end

  # Address field
  address = secret.get_field_value_single('address')
  if address
    puts "Address Field:"
    puts "  Street: #{address['street1']}"
    puts "  City: #{address['city']}, #{address['state']} #{address['zip']}"
    puts "  Country: #{address['country']}"
    puts ""
  end

  # Payment card field
  card = secret.get_field_value_single('paymentCard')
  if card
    puts "Payment Card Field:"
    puts "  Last 4: ****-#{card['cardNumber'][-4..-1]}"
    puts "  Expiry: #{card['cardExpirationDate']}"
    puts ""
  end

  # File references
  if secret.files && secret.files.any?
    puts "Attached Files:"
    secret.files.each do |file|
      puts "  - #{file['name']} (#{file['size']} bytes)"
    end
    puts ""
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: #{e.message}"
end

puts "=" * 60
puts "Field type examples complete"
```{{copy}}

Save as `field_types.rb` and run:

```bash
ruby field_types.rb
```{{execute}}

## 4. Using Notation for Direct Access

KSM provides a notation system for accessing specific fields directly:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Notation System Examples"
puts "=" * 60
puts ""

# Get the first secret's UID
secret = secrets_manager.get_secrets.first
uid = secret.uid

puts "Working with secret: #{secret.title}"
puts "UID: #{uid}"
puts ""

# Access fields using notation
puts "Notation Examples:"
puts "-" * 60

# Title notation
title = secrets_manager.get_notation("keeper://#{uid}/title")
puts "Title: #{title}"

# Field notation
login = secrets_manager.get_notation("keeper://#{uid}/field/login")
puts "Login: #{login}"

# Password notation (use carefully!)
password = secrets_manager.get_notation("keeper://#{uid}/field/password")
puts "Password: #{'*' * password.to_s.length} (hidden, length: #{password.to_s.length})"

# URL notation
url = secrets_manager.get_notation("keeper://#{uid}/field/url")
puts "URL: #{url}"

# Custom field notation
begin
  env = secrets_manager.get_notation("keeper://#{uid}/custom_field/Environment")
  puts "Environment: #{env}" if env
rescue => e
  puts "Custom field 'Environment': (not found)"
end

puts ""
puts "=" * 60
puts "Notation examples complete"
```{{copy}}

Save as `notation_demo.rb` and run:

```bash
ruby notation_demo.rb
```{{execute}}

## 🔍 Understanding Field Access Patterns

### Direct Property Access
```ruby
secret.login      # Returns first login field value
secret.password   # Returns first password field value
secret.url        # Returns array of URL values
```

### Using get_field_value_single
```ruby
# Returns the first field of the specified type as a hash
phone = secret.get_field_value_single('phone')
# => {"region" => "US", "number" => "555-0123", "type" => "Mobile"}
```

### Using fields Array
```ruby
# Access all fields directly
secret.fields.each do |field|
  type = field['type']
  value = field['value']  # Usually an array
end
```

### Using Notation
```ruby
# Notation format: keeper://UID/field/FIELD_TYPE[INDEX]
value = secrets_manager.get_notation("keeper://abc123/field/url[0]")
```

## 🔒 Security Best Practices for Field Access

✅ **DO:**
- Use notation for single-field retrieval in production
- Access passwords only when needed, clear from memory after use
- Log field access events (but not values!)
- Use environment-specific secrets (dev/staging/prod)

❌ **DON'T:**
- Print passwords to console in production
- Store decrypted values in logs or databases
- Cache sensitive fields longer than necessary
- Return raw password values from APIs

## Troubleshooting

### Error: "undefined method 'login' for KeeperRecord"
- **Cause:** The secret doesn't have a login field
- **Solution:** Check `secret.fields` to see available fields

### Notation returns nil
- **Cause:** Field doesn't exist or notation syntax is incorrect
- **Solution:** Verify UID and field name are correct

### get_field_value_single returns nil
- **Cause:** No field of that type exists
- **Solution:** Use `secret.fields` to list all available field types

## Next Steps

🎉 **Congratulations!** You've mastered reading and searching secrets! You can now:
- Access any field from secrets
- Search for specific secrets
- Work with various field types
- Use notation for direct access

In **Step 3**, you'll learn how to:
- Create new secrets programmatically
- Update existing secrets
- Work with complex field types
- Handle field validation

Click **"Continue"** to proceed to Step 3: Creating & Updating Records.
