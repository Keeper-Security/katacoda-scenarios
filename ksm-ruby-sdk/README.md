# Keeper Secrets Manager - Ruby SDK Tutorial

**Status**: ✅ Production Ready
**Version**: SDK 17.1.0 | Ruby 3.2+
**Total Content**: 3,799 lines
**Last Updated**: 2024-11-06

## 📋 Overview

This comprehensive, hands-on tutorial teaches developers how to integrate Keeper Secrets Manager Ruby SDK into their applications. From basic connection to production-ready patterns, this tutorial covers everything needed to build secure, zero-knowledge secret management into Ruby applications.

## 🎯 Learning Objectives

By completing this tutorial, developers will be able to:
- Connect to Keeper Secrets Manager and retrieve secrets
- Perform CRUD operations on secrets and folders
- Upload and download files securely
- Implement production-ready patterns (caching, logging, error handling)
- Integrate KSM into Rails, Sidekiq, and other Ruby frameworks

## 📂 Tutorial Structure

### Step 1: Installation & First Connection (300 lines)
- Install KSM Ruby SDK 17.1.0
- Connect with InMemoryStorage and FileStorage
- Retrieve and list secrets
- Understand basic initialization patterns

### Step 2: Reading Secrets & Fields (433 lines)
- Access common fields (login, password, URL)
- Search secrets by title
- Work with custom fields and complex field types
- Use notation system for direct field access

### Step 3: Creating & Updating Records (538 lines)
- Create simple and complex secrets
- Update existing records
- Work with all field types (phone, address, payment card, etc.)
- Implement bulk update patterns

### Step 4: Folder Management (543 lines)
- List and navigate folder hierarchies
- Create and organize folders
- Understand shared folder encryption
- Manage folder permissions

### Step 5: File Operations (637 lines)
- Upload files to secrets
- Download files securely
- Manage multiple files per record
- Implement SSL certificate workflows

### Step 6: Production Patterns & Best Practices (861 lines)
- Implement robust error handling with retries
- Use caching for offline resilience
- Configure comprehensive logging and auditing
- Deploy to production environments
- Security hardening checklist

## 🚀 Quick Start

```ruby
require 'keeper_secrets_manager'

# Initialize with base64 configuration
storage = KeeperSecretsManager::Storage::InMemoryStorage.new(ENV['KSM_CONFIG'])
secrets_manager = KeeperSecretsManager.new(config: storage)

# Get all secrets
secrets = secrets_manager.get_secrets

# Access a specific field
secret = secrets.first
puts "Login: #{secret.login}"
puts "Password: #{secret.password}"
```

## 🔑 Key Features

### Complete Code Examples
- 30+ fully working, tested Ruby scripts
- Real-world integration patterns (Rails, Sidekiq, Rake, Docker Compose)
- Production-ready error handling and retry logic

### Security First
- Prominent security warnings in every step
- Best practices for credential storage
- Memory cleanup patterns
- SSL/TLS verification enforcement

### Production Ready
- Caching for offline resilience
- Comprehensive logging and auditing
- Error handling with exponential backoff
- Monitoring and alerting guidance

### Killercoda Integration
- Proper {{execute}} and {{copy}} syntax
- Expected outputs for verification
- Troubleshooting sections
- Interactive learning experience

## 🛠️ Technical Details

### Requirements
- **Ruby**: 3.1.0 or higher (3.2+ recommended)
- **Gem**: `keeper_secrets_manager` version 17.1.0
- **Platform**: Ubuntu 22.04+ (Killercoda environment)

### Installation
Tutorial uses Brightbox PPA for Ruby 3.2 installation on Ubuntu 22.04:
```bash
add-apt-repository -y ppa:brightbox/ruby-ng
apt-get install ruby3.2 ruby3.2-dev build-essential
gem install keeper_secrets_manager --version 17.1.0
```

### Core SDK Classes
- `KeeperSecretsManager::Core::SecretsManager` - Main client
- `KeeperSecretsManager::Storage::InMemoryStorage` - In-memory configuration
- `KeeperSecretsManager::Storage::FileStorage` - Persistent file-based storage
- `KeeperSecretsManager::Dto::KeeperRecord` - Secret record object
- `KeeperSecretsManager::Dto::KeeperFolder` - Folder object

### Key Methods
- `get_secrets(uids = nil)` - Retrieve secrets
- `create_secret(record_data, options)` - Create new secret
- `update_secret(record)` - Update existing secret
- `delete_secret(record_uids)` - Delete secrets
- `get_folders()` - List all folders
- `create_folder(name, parent_uid:)` - Create folder
- `upload_file(owner_uid, file_data, file_name, title)` - Upload file
- `download_file(file_data)` - Download file
- `get_notation(notation_uri)` - Access via notation

## 📖 Real-World Integration Examples

### Rails Application
```ruby
# config/initializers/keeper_secrets_manager.rb
module KeeperConfig
  def self.secrets_manager
    @secrets_manager ||= begin
      config = ENV['KSM_CONFIG']
      storage = KeeperSecretsManager::Storage::InMemoryStorage.new(config)
      KeeperSecretsManager.new(config: storage, logger: Rails.logger)
    end
  end

  def self.database_password
    secret = secrets_manager.get_secret_by_title('Production Database')
    secret.password
  end
end
```

### Sidekiq Background Jobs
```ruby
class CredentialRotationWorker
  include Sidekiq::Worker

  def perform(secret_uid)
    secrets_manager = initialize_ksm
    secret = secrets_manager.get_secrets([secret_uid]).first

    # Rotate password
    secret.password = generate_secure_password
    secrets_manager.update_secret(secret)

    # Update external systems
    update_external_systems(secret)
  end
end
```

### Docker Compose
```yaml
services:
  app:
    environment:
      - KSM_CONFIG=${KSM_CONFIG}
    command: bundle exec rails server
```

## 🔒 Security Best Practices

### Configuration Management
- ✅ Store config in environment variables
- ✅ Never commit credentials to git
- ✅ Use separate KSM apps for dev/staging/prod
- ✅ Set file permissions to 0600

### Network Security
- ✅ Always verify SSL certificates
- ✅ Use latest TLS version (1.3)
- ✅ Implement timeout settings
- ✅ Rate limit API calls

### Error Handling
- ✅ Implement retry logic with exponential backoff
- ✅ Gracefully degrade on failures
- ✅ Never expose secret values in error messages
- ✅ Log errors without sensitive data

### Monitoring
- ✅ Log all secret access with audit trail
- ✅ Monitor API latency and error rates
- ✅ Set up alerts for anomalous access
- ✅ Track cache hit ratio

## 📚 Additional Resources

- **Tutorial Files**: All markdown files in this directory
- **KSM Documentation**: https://docs.keeper.io/secrets-manager/
- **Ruby SDK GitHub**: https://github.com/Keeper-Security/secrets-manager/tree/master/sdk/ruby
- **RubyGems**: https://rubygems.org/gems/keeper_secrets_manager
- **Support**: https://www.keepersecurity.com/support.html

## 🧪 Testing

All code examples have been validated for:
- Syntax correctness
- API method accuracy
- Error handling robustness
- Production readiness
- Killercoda compatibility

## 📝 File Inventory

```
ksm-ruby-sdk/
├── index.json           # Killercoda configuration (42 lines)
├── setup.sh             # Environment setup script (50 lines)
├── intro.md             # Tutorial introduction (79 lines)
├── step1.md             # Installation & Connection (300 lines)
├── step2.md             # Reading Secrets (433 lines)
├── step3.md             # Creating & Updating (538 lines)
├── step4.md             # Folder Management (543 lines)
├── step5.md             # File Operations (637 lines)
├── step6.md             # Production Patterns (861 lines)
├── finish.md            # Summary & Next Steps (320 lines)
└── README.md            # This file

Total: 3,803 lines of comprehensive tutorial content
```

## 🎓 Target Audience

- Ruby developers new to KSM
- DevOps engineers implementing secret management
- Security teams deploying zero-knowledge architectures
- Teams migrating from hardcoded credentials

## ✅ Production Readiness Checklist

- [x] All code examples tested and working
- [x] Security warnings prominently displayed
- [x] Error handling implemented throughout
- [x] Production patterns documented
- [x] Real-world integration examples provided
- [x] Killercoda syntax validated
- [x] Troubleshooting sections complete
- [x] Documentation comprehensive

## 🤝 Contributing

Found an issue or have an improvement? Please:
1. Test your changes in a Docker container with Ubuntu 22.04
2. Validate all Killercoda syntax
3. Follow the security guidelines in `/CLAUDE.md`
4. Submit with clear documentation

## 📄 License

This tutorial is part of the Keeper Security documentation and follows the same licensing terms.

---

**Created with ❤️ for the Keeper Security community**

*Last validated: 2024-11-06*
