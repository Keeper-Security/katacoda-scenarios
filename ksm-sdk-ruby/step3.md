# Step 3: Creating & Updating Records

**Learning Objective**: Master creating new secrets, updating existing records, and working with complex field types.

## What You'll Accomplish

In this step, you'll learn how to:
- Create new secrets programmatically with various field types
- Update existing secret fields
- Work with complex field structures (phone, address, payment card)
- Handle record validation and errors
- Understand folder requirements for creation

## Why CRUD Operations Matter

**Business Benefits:**
- **Automate secret provisioning** for new applications and services
- **Implement credential rotation** without manual vault access
- **Programmatic secret lifecycle** from creation to deletion

**Technical Benefits:**
- **Infrastructure as Code** - secrets managed alongside infrastructure
- **CI/CD integration** - automatically provision secrets for deployments
- **Dynamic credentials** - create temporary secrets on demand

## ⚠️ Prerequisites

**IMPORTANT**: To create secrets, you MUST have a folder UID. Run this first:

```bash
# Get folder UIDs from your vault
ruby -e "
require 'keeper_secrets_manager'
storage = KeeperSecretsManager::Storage::InMemoryStorage.new(ENV['KSM_CONFIG'])
sm = KeeperSecretsManager.new(config: storage)
folders = sm.get_folders
puts 'Available Folders:'
folders.each do |f|
  is_root = f.parent_uid.nil? || f.parent_uid.empty?
  marker = is_root ? '[SHARED ROOT]' : '[Subfolder]'
  puts \"  #{marker} #{f.name}: #{f.uid}\"
end
"
```{{execute}}

Save a **shared folder root** UID (marked [SHARED ROOT]) - you'll need it for creating records!

## 1. Creating a Simple Login Record

Let's create a basic login record with common fields. Create the `create_simple.rb` file:

```
cat > create_simple.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"
FOLDER_UID = ENV['FOLDER_UID'] || "[YOUR_FOLDER_UID_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Creating a New Secret"
puts "=" * 60
puts ""

begin
  # Define the record data
  record_data = {
    'type' => 'login',
    'title' => 'Ruby SDK Demo - Database',
    'fields' => [
      { 'type' => 'login', 'value' => ['demo_user'] },
      { 'type' => 'password', 'value' => ['DemoP@ssw0rd!2024'] },
      { 'type' => 'url', 'value' => ['https://demo-db.example.com:5432'] },
      { 'type' => 'fileRef', 'value' => [] }
    ],
    'notes' => "Created by KSM Ruby SDK\nEnvironment: Demo\nCreated: #{Time.now}"
  }

  # Create options with folder UID
  options = KeeperSecretsManager::Dto::CreateOptions.new
  options.folder_uid = FOLDER_UID

  puts "Creating record in folder: #{FOLDER_UID}"

  # Create the secret
  record_uid = secrets_manager.create_secret(record_data, options)

  puts "Secret created successfully!"
  puts "   UID: #{record_uid}"
  puts ""

  # Verify by retrieving it
  sleep 1  # Give server time to process

  created_secret = secrets_manager.get_secrets([record_uid]).first

  if created_secret
    puts "Verification:"
    puts "   Title: #{created_secret.title}"
    puts "   Login: #{created_secret.login}"
    puts "   Password: #{'*' * 12} (hidden)"
    puts "   URL: #{created_secret.url}"
  else
    puts "WARNING: Could not verify - secret may take a moment to sync"
  end

rescue ArgumentError => e
  puts "ERROR: Validation Error: #{e.message}"
  puts ""
  puts "Make sure you set FOLDER_UID environment variable!"
  puts "Run: export FOLDER_UID='your-folder-uid-here'"

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"

rescue StandardError => e
  puts "ERROR: #{e.class} - #{e.message}"
end

puts ""
puts "=" * 60
puts "Record creation example complete"
EOF
```{{execute}}

Set your folder UID and run:

```bash
export FOLDER_UID="your-folder-uid-here"
ruby create_simple.rb
```{{execute}}

**Expected Output:**
```
Creating a New Secret
============================================================

Creating record in folder: lPxZXk...
Secret created successfully!
   UID: mQyAYl...

Verification:
   Title: Ruby SDK Demo - Database
   Login: demo_user
   Password: ************ (hidden)
   URL: https://demo-db.example.com:5432

============================================================
Record creation example complete
```

## 2. Creating Complex Records with Multiple Field Types

Now let's create a record with advanced field types. Create the `create_complex.rb` file:

```
cat > create_complex.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"
FOLDER_UID = ENV['FOLDER_UID'] || "[YOUR_FOLDER_UID_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Creating Complex Record with Multiple Field Types"
puts "=" * 60
puts ""

begin
  # Use the KeeperRecord object for better API
  record = KeeperSecretsManager::Dto::KeeperRecord.new(
    'type' => 'login',
    'title' => 'Ruby SDK Demo - Complex Record'
  )

  # Set basic fields
  record.login = 'complex.user@example.com'
  record.password = 'C0mpl3x!P@ssw0rd#2024'
  record.url = ['https://app.example.com', 'https://admin.example.com']

  # Add phone field (structured data)
  record.set_field('phone', {
    'region' => 'US',
    'number' => '555-0199',
    'ext' => '1234',
    'type' => 'Work'
  })

  # Add name field
  record.set_field('name', {
    'first' => 'Demo',
    'middle' => 'Ruby',
    'last' => 'User'
  })

  # Add address field
  record.set_field('address', {
    'street1' => '123 Ruby Lane',
    'street2' => 'Suite 456',
    'city' => 'San Francisco',
    'state' => 'CA',
    'zip' => '94102',
    'country' => 'US'
  })

  # Add payment card field
  record.set_field('paymentCard', {
    'cardNumber' => '4111111111111111',
    'cardExpirationDate' => '12/2025',
    'cardSecurityCode' => '123'
  })

  # Add host field (for server access)
  record.set_field('host', {
    'hostName' => 'demo-server.example.com',
    'port' => '22'
  })

  # Add secret field (API keys, tokens)
  record.set_field('secret', 'sk_test_51234567890abcdefghijklmnop')

  # Add custom fields
  record.custom = [
    {
      'type' => 'text',
      'label' => 'Environment',
      'value' => ['Production']
    },
    {
      'type' => 'text',
      'label' => 'Owner',
      'value' => ['DevOps Team']
    },
    {
      'type' => 'text',
      'label' => 'Created By',
      'value' => ['KSM Ruby SDK']
    }
  ]

  # Add notes
  record.notes = "Complex record demonstration\nCreated: #{Time.now}\n\nContains multiple field types for testing."

  # Create with folder UID
  options = KeeperSecretsManager::Dto::CreateOptions.new
  options.folder_uid = FOLDER_UID

  puts "Creating complex record..."
  record_uid = secrets_manager.create_secret(record, options)

  puts "Complex record created!"
  puts "   UID: #{record_uid}"
  puts ""

  # Verify fields
  sleep 1
  created = secrets_manager.get_secrets([record_uid]).first

  if created
    puts "Verification:"
    puts "   Title: #{created.title}"
    puts "   Login: #{created.login}"
    puts "   Phone: #{created.get_field_value_single('phone')&.dig('number')}"
    puts "   Address City: #{created.get_field_value_single('address')&.dig('city')}"
    puts "   Card Last 4: ****#{created.get_field_value_single('paymentCard')&.dig('cardNumber')&.[](-4..-1)}"
    puts "   Custom Fields: #{created.custom&.length || 0}"
  end

rescue StandardError => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "Complex record creation complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby create_complex.rb
```{{execute}}

## 3. Updating Existing Records

Let's update a secret's fields. Create the `update_record.rb` file:

```
cat > update_record.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Updating Secret Fields"
puts "=" * 60
puts ""

begin
  # Get all secrets and find one to update
  secrets = secrets_manager.get_secrets

  if secrets.empty?
    puts "ERROR: No secrets found to update"
    exit 0
  end

  # Use the first secret (or search by title)
  secret = secrets.first

  puts "Updating: #{secret.title}"
  puts "UID: #{secret.uid}"
  puts ""

  # Display current values
  puts "Current Values:"
  puts "   Login: #{secret.login || '(not set)'}"
  puts "   Password: #{'*' * 12}"
  puts "   URL: #{secret.url || '(not set)'}"
  puts ""

  # Update fields
  puts "Applying updates..."

  secret.login = "updated_#{secret.login || 'user'}"
  secret.password = "NewP@ssw0rd!#{rand(1000..9999)}"
  secret.url = ['https://updated.example.com']

  # Add or update custom field
  secret.custom ||= []

  # Remove old "Last Updated" field if it exists
  secret.custom.reject! { |f| f['label'] == 'Last Updated' }

  # Add new timestamp
  secret.custom << {
    'type' => 'text',
    'label' => 'Last Updated',
    'value' => [Time.now.strftime('%Y-%m-%d %H:%M:%S')]
  }

  # Update notes
  secret.notes = "#{secret.notes}\n\nUpdated by KSM Ruby SDK: #{Time.now}"

  # Perform the update
  secrets_manager.update_secret(secret)

  puts "Update successful!"
  puts ""

  # Verify the update
  sleep 1
  updated_secret = secrets_manager.get_secrets([secret.uid]).first

  puts "New Values:"
  puts "   Login: #{updated_secret.login}"
  puts "   Password: #{'*' * 12} (changed)"
  puts "   URL: #{updated_secret.url}"
  puts "   Last Updated: #{updated_secret.custom&.find { |f| f['label'] == 'Last Updated' }&.dig('value', 0)}"

rescue KeeperSecretsManager::RecordNotFoundError => e
  puts "ERROR: Record not found: #{e.message}"

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"

rescue StandardError => e
  puts "ERROR: #{e.class} - #{e.message}"
end

puts ""
puts "=" * 60
puts "Record update example complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby update_record.rb
```{{execute}}

**Expected Output:**
```
Updating Secret Fields
============================================================

Updating: Production Database
UID: lPxZXk...

Current Values:
   Login: db_admin
   Password: ************
   URL: https://db.example.com

Applying updates...
Update successful!

New Values:
   Login: updated_db_admin
   Password: ************ (changed)
   URL: https://updated.example.com
   Last Updated: 2024-11-06 12:45:30

============================================================
Record update example complete
```

## 4. Bulk Update Pattern

For updating multiple secrets efficiently:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Bulk Update Pattern"
puts "=" * 60
puts ""

begin
  # Get all secrets
  secrets = secrets_manager.get_secrets

  # Filter secrets to update (example: all with "Demo" in title)
  demo_secrets = secrets.select { |s| s.title.include?('Demo') }

  puts "Found #{demo_secrets.length} secrets to update"
  puts ""

  demo_secrets.each_with_index do |secret, index|
    puts "#{index + 1}. Updating: #{secret.title}"

    # Add a tag via custom field
    secret.custom ||= []
    secret.custom.reject! { |f| f['label'] == 'Bulk Updated' }
    secret.custom << {
      'type' => 'text',
      'label' => 'Bulk Updated',
      'value' => [Time.now.strftime('%Y-%m-%d')]
    }

    # Update
    secrets_manager.update_secret(secret)
    puts "   Updated"

    sleep 0.5  # Rate limiting - be nice to the API
  end

  puts ""
  puts "Bulk update complete!"

rescue StandardError => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
```{{copy}}

## 🔍 Understanding Field Types

### Common Field Types:
```ruby
# Text fields
{ 'type' => 'login', 'value' => ['username'] }
{ 'type' => 'password', 'value' => ['secret'] }
{ 'type' => 'url', 'value' => ['https://example.com'] }
{ 'type' => 'email', 'value' => ['user@example.com'] }
{ 'type' => 'text', 'value' => ['any text'] }

# Structured fields
{ 'type' => 'phone', 'value' => [{'region' => 'US', 'number' => '555-0100'}] }
{ 'type' => 'name', 'value' => [{'first' => 'John', 'last' => 'Doe'}] }
{ 'type' => 'address', 'value' => [{'city' => 'SF', 'state' => 'CA'}] }

# Special fields
{ 'type' => 'secret', 'value' => ['api-key-value'] }
{ 'type' => 'note', 'value' => ['secure note text'] }
{ 'type' => 'fileRef', 'value' => [] }  # File UIDs added here
```

## 🔒 Security Best Practices

**DO:**
- Validate input before creating/updating secrets
- Use strong password generation (20+ characters)
- Add metadata (owner, environment, created date)
- Implement audit logging for all changes
- Test in dev/staging before production

❌ **DON'T:**
- Store plaintext passwords in code
- Create secrets in wrong folders (access control)
- Skip error handling on create/update
- Update without checking current revision
- Ignore API rate limits (add delays for bulk operations)

## Troubleshooting

### Error: "folder_uid is required to create a record"
- **Cause:** No folder UID provided in CreateOptions
- **Solution:** Get folder UIDs with `secrets_manager.get_folders` and specify one

### Error: "Folder {uid} not found or not accessible"
- **Cause:** Invalid folder UID or no permission
- **Solution:** Verify folder UID and KSM application permissions

### Error: "Record {uid} not found"
- **Cause:** Trying to update a non-existent record
- **Solution:** Verify record UID exists before updating

### Update doesn't reflect changes
- **Cause:** Server sync delay or revision conflict
- **Solution:** Add `sleep 1` after update, refetch to verify

## Next Steps

🎉 **Congratulations!** You can now create and update secrets! You've mastered:
- Creating simple and complex records
- Updating existing secrets
- Working with various field types
- Bulk update patterns

In **Step 4**, you'll learn how to:
- Create and manage folders
- Organize secrets hierarchically
- Understand folder permissions
- Move records between folders

Click **"Continue"** to proceed to Step 4: Folder Management.
