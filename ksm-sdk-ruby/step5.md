# Step 5: File Operations

**Learning Objective**: Master uploading, downloading, and managing files attached to secrets.

## What You'll Accomplish

In this step, you'll learn how to:
- Upload files to secrets
- Download files from secrets
- List files attached to records
- Manage file metadata
- Handle multiple files per record

## Why File Management Matters

**Business Benefits:**
- **Certificate management** - store SSL/TLS certs with private keys
- **Configuration files** - attach config files to application secrets
- **SSH keys** - store private keys alongside credentials
- **Documentation** - attach setup guides to secrets

**Technical Benefits:**
- **End-to-end encryption** - files encrypted client-side
- **Secure storage** - files never stored unencrypted
- **Version control** - track file uploads and changes

## 1. Viewing Files Attached to Secrets

First, let's see what files are already attached. Create the `list_files.rb` file:

```
cat > list_files.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

# Helper method to format file sizes
def format_bytes(bytes)
  return "0 B" if bytes == 0

  units = ['B', 'KB', 'MB', 'GB']
  exp = (Math.log(bytes) / Math.log(1024)).floor
  exp = [exp, units.length - 1].min

  "%.2f %s" % [bytes.to_f / (1024 ** exp), units[exp]]
end

puts "Listing Files in Secrets"
puts "=" * 60
puts ""

begin
  # Get all secrets
  secrets = secrets_manager.get_secrets

  secrets_with_files = secrets.select { |s| s.files && s.files.any? }

  puts "Found #{secrets_with_files.length} secret(s) with attached files"
  puts ""

  if secrets_with_files.any?
    secrets_with_files.each do |secret|
      puts "Secret: #{secret.title}"
      puts "  UID: #{secret.uid}"
      puts "  Files:"

      secret.files.each do |file|
        puts "    [File] #{file['name'] || file['title']}"
        puts "       File UID: #{file['fileUid']}"
        puts "       Size: #{format_bytes(file['size'] || 0)}"
        puts "       Type: #{file['type'] || 'unknown'}"
      end

      puts ""
    end
  else
    puts "WARNING: No secrets with attached files found"
    puts "Upload some files first!"
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "File listing complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby list_files.rb
```{{execute}}

**Expected Output:**
```
Listing Files in Secrets
============================================================

Found 2 secret(s) with attached files

Secret: Production SSL Certificate
  UID: lPxZXk...
  Files:
    server.crt
       File UID: mQyAYl...
       Size: 1.45 KB
       Type: application/x-pem-file

    server.key
       File UID: nRzBZm...
       Size: 1.68 KB
       Type: application/x-pem-file

Secret: SSH Keys
  UID: oSaBCn...
  Files:
    id_rsa
       File UID: pTbCDo...
       Size: 2.37 KB
       Type: application/octet-stream

============================================================
File listing complete
```

## 2. Uploading Files to Secrets

Upload files and attach them to records. Create the `upload_file.rb` file:

```
cat > upload_file.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Uploading File to Secret"
puts "=" * 60
puts ""

begin
  # Get secrets
  secrets = secrets_manager.get_secrets

  if secrets.empty?
    puts "ERROR: No secrets found. Create a secret first."
    exit 1
  end

  # Use the first secret as owner
  owner_secret = secrets.first

  puts "Owner Secret: #{owner_secret.title}"
  puts "Owner UID: #{owner_secret.uid}"
  puts ""

  # Create a sample file to upload
  file_name = "demo_config.txt"
  file_content = <<~CONTENT
    # Demo Configuration File
    # Created: #{Time.now}
    # Purpose: KSM Ruby SDK File Upload Demo

    database:
      host: localhost
      port: 5432
      name: production_db

    api:
      endpoint: https://api.example.com
      timeout: 30
      retry_count: 3

    security:
      encryption: enabled
      tls_version: 1.3
  CONTENT

  file_data = file_content.encode('UTF-8')

  puts "Uploading file: #{file_name}"
  puts "Size: #{file_data.bytesize} bytes"
  puts ""

  # Upload the file
  file_uid = secrets_manager.upload_file(
    owner_secret.uid,
    file_data,
    file_name,
    "Demo Configuration"  # File title
  )

  puts "File uploaded successfully!"
  puts "   File UID: #{file_uid}"
  puts ""

  # Verify by fetching the secret again
  sleep 2
  updated_secret = secrets_manager.get_secrets([owner_secret.uid]).first

  if updated_secret.files && updated_secret.files.any?
    new_file = updated_secret.files.find { |f| f['fileUid'] == file_uid }

    if new_file
      puts "Verification:"
      puts "   File Name: #{new_file['name']}"
      puts "   File Title: #{new_file['title']}"
      puts "   File Size: #{new_file['size']} bytes"
      puts "   File Type: #{new_file['type']}"
    end
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: #{e.message}"
  puts ""
  puts "Common issues:"
  puts "- Ensure secret UID is valid"
  puts "- Check file size (max 100MB)"
  puts "- Verify KSM app has write permissions"
end

puts ""
puts "=" * 60
puts "File upload complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby upload_file.rb
```{{execute}}

## 3. Downloading Files from Secrets

Download and save files locally. Create the `download_files.rb` file:

```
cat > download_files.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'
require 'fileutils'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Downloading Files from Secret"
puts "=" * 60
puts ""

begin
  # Get all secrets
  secrets = secrets_manager.get_secrets

  # Find secrets with files
  secrets_with_files = secrets.select { |s| s.files && s.files.any? }

  if secrets_with_files.empty?
    puts "WARNING: No files found to download"
    puts "Upload some files first with upload_file.rb"
    exit 0
  end

  # Use the first secret with files
  secret = secrets_with_files.first

  puts "Secret: #{secret.title}"
  puts "Files: #{secret.files.length}"
  puts ""

  # Create download directory
  download_dir = "/tmp/ksm_downloads"
  FileUtils.mkdir_p(download_dir)

  # Download each file
  secret.files.each_with_index do |file_data, index|
    puts "#{index + 1}. Downloading: #{file_data['name']}"

    # Download the file
    downloaded = secrets_manager.download_file(file_data)

    # Save to disk
    file_path = File.join(download_dir, downloaded['name'])

    File.open(file_path, 'wb') do |f|
      f.write(downloaded['data'])
    end

    puts "   Saved to: #{file_path}"
    puts "   Size: #{downloaded['data'].bytesize} bytes"
    puts "   Type: #{downloaded['type']}"
    puts ""

    # Show first few lines if it's a text file
    if downloaded['type']&.include?('text') || downloaded['name'].end_with?('.txt', '.conf', '.cfg')
      content = downloaded['data'].force_encoding('UTF-8')
      lines = content.lines.first(5)

      puts "   Preview:"
      lines.each { |line| puts "      #{line.chomp}" }
      puts "      ..." if content.lines.count > 5
      puts ""
    end
  end

  puts "All files downloaded to: #{download_dir}"

rescue KeeperSecretsManager::Error => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "File download complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby download_files.rb
```{{execute}}

**Expected Output:**
```
📥 Downloading Files from Secret
============================================================

Secret: Production SSL Certificate
Files: 2

1. Downloading: server.crt
   Saved to: /tmp/ksm_downloads/server.crt
   Size: 1485 bytes
   Type: application/x-pem-file

   Preview:
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKZ...
      -----END CERTIFICATE-----

2. Downloading: server.key
   Saved to: /tmp/ksm_downloads/server.key
   Size: 1720 bytes
   Type: application/x-pem-file

All files downloaded to: /tmp/ksm_downloads

============================================================
File download complete
```

## 4. Managing Multiple Files

Handle secrets with multiple attached files. Create the `manage_multiple_files.rb` file:

```
cat > manage_multiple_files.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Managing Multiple Files"
puts "=" * 60
puts ""

begin
  # Get secrets
  secrets = secrets_manager.get_secrets

  if secrets.empty?
    puts "ERROR: No secrets found"
    exit 1
  end

  owner_secret = secrets.first

  puts "Secret: #{owner_secret.title}"
  puts "Current files: #{owner_secret.files&.length || 0}"
  puts ""

  # Upload multiple files
  files_to_upload = [
    {
      name: 'certificate.pem',
      content: "-----BEGIN CERTIFICATE-----\nDemo Certificate Content\n-----END CERTIFICATE-----",
      title: 'SSL Certificate'
    },
    {
      name: 'private_key.pem',
      content: "-----BEGIN PRIVATE KEY-----\nDemo Private Key Content\n-----END PRIVATE KEY-----",
      title: 'SSL Private Key'
    },
    {
      name: 'ca_bundle.pem',
      content: "-----BEGIN CERTIFICATE-----\nDemo CA Bundle Content\n-----END CERTIFICATE-----",
      title: 'CA Bundle'
    }
  ]

  puts "Uploading #{files_to_upload.length} files..."
  puts ""

  uploaded_uids = []

  files_to_upload.each_with_index do |file_info, index|
    puts "#{index + 1}. Uploading: #{file_info[:name]}"

    file_uid = secrets_manager.upload_file(
      owner_secret.uid,
      file_info[:content].encode('UTF-8'),
      file_info[:name],
      file_info[:title]
    )

    uploaded_uids << file_uid
    puts "   Uploaded (#{file_uid})"

    sleep 0.5  # Rate limiting
  end

  puts ""
  puts "All files uploaded!"
  puts ""

  # Verify
  sleep 2
  updated_secret = secrets_manager.get_secrets([owner_secret.uid]).first

  puts "Verification:"
  puts "Total files: #{updated_secret.files&.length || 0}"
  puts ""

  if updated_secret.files && updated_secret.files.any?
    updated_secret.files.each do |file|
      status = uploaded_uids.include?(file['fileUid']) ? "[NEW]" : "[File]"
      puts "#{status} #{file['name']} (#{file['size']} bytes)"
    end
  end

rescue StandardError => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
EOF
```{{execute}}

Now run the script:

```bash
ruby manage_multiple_files.rb
```{{execute}}

## 5. Complete File Workflow Example

A real-world example: SSL certificate management. Create the `ssl_workflow.rb` file:

```
cat > ssl_workflow.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'
require 'openssl'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"
FOLDER_UID = ENV['FOLDER_UID'] || "[YOUR_FOLDER_UID]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "SSL Certificate Management Workflow"
puts "=" * 60
puts ""

begin
  # Step 1: Create a secret for the SSL certificate
  puts "1. Creating secret for SSL certificate..."

  cert_record = {
    'type' => 'login',
    'title' => "SSL Cert - demo.example.com - #{Time.now.strftime('%Y%m%d')}",
    'fields' => [
      { 'type' => 'url', 'value' => ['https://demo.example.com'] }
    ],
    'notes' => "SSL Certificate and Private Key\nExpiry: 2025-12-31\nIssuer: Let's Encrypt"
  }

  options = KeeperSecretsManager::Dto::CreateOptions.new
  options.folder_uid = FOLDER_UID

  record_uid = secrets_manager.create_secret(cert_record, options)
  puts "   Secret created: #{record_uid}"
  puts ""

  sleep 1

  # Step 2: Upload certificate file
  puts "2. Uploading certificate..."

  cert_content = <<~CERT
    -----BEGIN CERTIFICATE-----
    MIIDXTCCAkWgAwIBAgIJAKZDemo...
    -----END CERTIFICATE-----
  CERT

  cert_uid = secrets_manager.upload_file(
    record_uid,
    cert_content.encode('UTF-8'),
    'certificate.crt',
    'SSL Certificate'
  )

  puts "   Certificate uploaded: #{cert_uid}"

  sleep 1

  # Step 3: Upload private key
  puts "3. Uploading private key..."

  key_content = <<~KEY
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiGDemo...
    -----END PRIVATE KEY-----
  KEY

  key_uid = secrets_manager.upload_file(
    record_uid,
    key_content.encode('UTF-8'),
    'private_key.key',
    'Private Key'
  )

  puts "   Private key uploaded: #{key_uid}"
  puts ""

  # Step 4: Verify everything
  sleep 2
  puts "4. Verifying setup..."

  ssl_secret = secrets_manager.get_secrets([record_uid]).first

  puts "   Secret: #{ssl_secret.title}"
  puts "   Files: #{ssl_secret.files.length}"

  ssl_secret.files.each do |file|
    puts "     - #{file['name']} (#{file['size']} bytes)"
  end

  puts ""
  puts "SSL certificate workflow complete!"
  puts ""
  puts "Next Steps:"
  puts "   - Download files when needed for deployment"
  puts "   - Rotate certificate before expiry"
  puts "   - Share secret with deployment team"

rescue ArgumentError => e
  puts "ERROR: #{e.message}"
  puts "Make sure to set FOLDER_UID environment variable!"
rescue StandardError => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
EOF
```{{execute}}

Set your folder UID and run:

```bash
export FOLDER_UID="your-folder-uid-here"
ruby ssl_workflow.rb
```{{execute}}

## Understanding File Operations

### File Upload Process:
1. SDK encrypts file data with a generated file key
2. File key encrypted with secret's record key
3. File metadata encrypted and stored
4. File data uploaded to secure storage
5. FileRef added to secret's fields

### File Download Process:
1. SDK retrieves file metadata from secret
2. Downloads encrypted file from storage URL
3. Decrypts file key using secret's record key
4. Decrypts file data with file key
5. Returns decrypted file content

## 🔒 Security Best Practices

**DO:**
- Encrypt files before uploading (SDK does this automatically)
- Use descriptive file titles and names
- Delete files from disk after processing
- Validate file types before upload
- Set appropriate file permissions (0600) on downloads

❌ **DON'T:**
- Store unencrypted files on disk longer than needed
- Upload sensitive files to wrong secrets
- Share download URLs (they contain encrypted data)
- Skip file size validation (max 100MB)
- Log file contents

## Troubleshooting

### Error: "Record key not available for owner record"
- **Cause:** Secret hasn't been fetched with keys
- **Solution:** Call `get_secrets([uid])` before uploading

### Error: "Owner public key not found"
- **Cause:** KSM app not properly bound
- **Solution:** Re-bind with a new one-time token

### File upload succeeds but not visible
- **Cause:** Server sync delay
- **Solution:** Add `sleep 2` before fetching updated secret

### Downloaded file is corrupted
- **Cause:** Binary mode not used when saving
- **Solution:** Use `'wb'` mode: `File.open(path, 'wb')`

## Next Steps

🎉 **Congratulations!** You've mastered file operations! You can now:
- Upload files to secrets
- Download files securely
- Manage multiple files per secret
- Implement real-world file workflows

In **Step 6**, you'll learn:
- Production-ready patterns and error handling
- Caching strategies for offline resilience
- Logging and debugging techniques
- Security hardening best practices

Click **"Continue"** to proceed to Step 6: Production Patterns & Best Practices.
