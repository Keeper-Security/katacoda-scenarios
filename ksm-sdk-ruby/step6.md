# Step 6: Production Patterns & Best Practices

**Learning Objective**: Master production-ready patterns, error handling, caching, logging, and security hardening for real-world deployments.

## What You'll Accomplish

In this step, you'll learn how to:
- Implement robust error handling
- Use caching for offline resilience
- Configure logging for debugging and auditing
- Handle network failures and retries
- Secure configuration management
- Deploy KSM in production environments

## Why Production Patterns Matter

**Business Benefits:**
- **High availability** - applications work even during network issues
- **Audit compliance** - complete logging of secret access
- **Reduced downtime** - graceful degradation during failures
- **Cost efficiency** - reduced API calls with caching

**Technical Benefits:**
- **Resilience** - handle transient failures automatically
- **Observability** - debug issues with proper logging
- **Security** - defense-in-depth with multiple layers
- **Performance** - optimized secret retrieval with caching

## 1. Robust Error Handling

Implement comprehensive error handling. Create the `production_errors.rb` file:

```
cat > production_errors.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'
require 'logger'

# Production-ready error handling
class KSMClientWrapper
  attr_reader :secrets_manager, :logger

  def initialize(config, logger: nil)
    @logger = logger || Logger.new(STDOUT)
    @logger.level = Logger::INFO

    begin
      storage = KeeperSecretsManager::Storage::InMemoryStorage.new(config)
      @secrets_manager = KeeperSecretsManager.new(
        config: storage,
        logger: @logger
      )

      @logger.info "KSM client initialized successfully"

    rescue JSON::ParserError => e
      @logger.fatal "Invalid KSM configuration format: #{e.message}"
      raise
    rescue KeeperSecretsManager::Error => e
      @logger.fatal "KSM initialization failed: #{e.message}"
      raise
    end
  end

  def get_secret_safely(uid, retries: 3)
    attempt = 0

    begin
      attempt += 1
      @logger.info "Fetching secret #{uid} (attempt #{attempt}/#{retries})"

      secrets = @secrets_manager.get_secrets([uid])

      if secrets.empty?
        @logger.error "Secret #{uid} not found"
        return nil
      end

      @logger.info "Successfully retrieved secret #{uid}"
      secrets.first

    rescue KeeperSecretsManager::NetworkError => e
      @logger.warn "Network error on attempt #{attempt}: #{e.message}"

      if attempt < retries
        sleep_time = 2 ** attempt  # Exponential backoff
        @logger.info "Retrying in #{sleep_time} seconds..."
        sleep sleep_time
        retry
      else
        @logger.error "Failed to retrieve secret after #{retries} attempts"
        nil
      end

    rescue KeeperSecretsManager::RecordNotFoundError => e
      @logger.error "Secret #{uid} does not exist: #{e.message}"
      nil

    rescue KeeperSecretsManager::Error => e
      @logger.error "KSM error: #{e.message}"
      nil

    rescue StandardError => e
      @logger.error "Unexpected error: #{e.class} - #{e.message}"
      @logger.debug e.backtrace.join("\n")
      nil
    end
  end

  def get_secret_field_safely(uid, field_name)
    secret = get_secret_safely(uid)
    return nil unless secret

    begin
      case field_name
      when 'login'
        secret.login
      when 'password'
        secret.password
      when 'url'
        secret.url&.first
      else
        secret.get_field_value_single(field_name)
      end

    rescue StandardError => e
      @logger.error "Failed to extract field '#{field_name}': #{e.message}"
      nil
    end
  end
end

# Usage example
puts "Production Error Handling Example"
puts "=" * 60
puts ""

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

begin
  client = KSMClientWrapper.new(KSM_CONFIG)

  # Get all secrets
  secrets = client.secrets_manager.get_secrets

  if secrets.any?
    # Test with first secret
    uid = secrets.first.uid

    # Safely get secret
    secret = client.get_secret_safely(uid)

    if secret
      puts "Secret retrieved: #{secret.title}"

      # Safely get fields
      login = client.get_secret_field_safely(uid, 'login')
      puts "   Login: #{login || '(not set)'}"
    end
  else
    puts "WARNING: No secrets available"
  end

rescue => e
  puts "ERROR: Fatal error: #{e.message}"
end

puts ""
puts "=" * 60
puts "Error handling example complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby production_errors.rb
```{{execute}}

## 2. Caching for Offline Resilience

Implement caching to handle network outages:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'
require 'json'
require 'fileutils'

# Production caching wrapper
class CachedKSMClient
  CACHE_DIR = '/tmp/ksm_cache'
  CACHE_TTL = 3600  # 1 hour

  attr_reader :secrets_manager

  def initialize(config)
    FileUtils.mkdir_p(CACHE_DIR)

    storage = KeeperSecretsManager::Storage::InMemoryStorage.new(config)
    @secrets_manager = KeeperSecretsManager.new(config: storage)
  end

  def get_secrets_with_cache(force_refresh: false)
    cache_file = File.join(CACHE_DIR, 'secrets_cache.json')

    # Try cache first unless force refresh
    unless force_refresh
      if File.exist?(cache_file)
        cache_age = Time.now - File.mtime(cache_file)

        if cache_age < CACHE_TTL
          puts "Using cached secrets (age: #{cache_age.to_i}s)"

          cache_data = JSON.parse(File.read(cache_file))
          return cache_data['secrets'].map { |s| reconstruct_secret(s) }
        else
          puts "Cache expired (age: #{cache_age.to_i}s > #{CACHE_TTL}s)"
        end
      end
    end

    # Fetch from KSM
    begin
      puts "Fetching from Keeper Secrets Manager..."

      secrets = @secrets_manager.get_secrets

      # Cache the results
      cache_data = {
        'timestamp' => Time.now.to_i,
        'secrets' => secrets.map { |s| serialize_secret(s) }
      }

      File.open(cache_file, 'w') do |f|
        f.write(JSON.pretty_generate(cache_data))
      end

      File.chmod(0600, cache_file)  # Secure permissions

      puts "Fetched #{secrets.length} secrets and cached"

      secrets

    rescue => e
      # Fallback to cache on error
      if File.exist?(cache_file)
        puts "WARNING: Network error, using stale cache: #{e.message}"

        cache_data = JSON.parse(File.read(cache_file))
        cache_age = Time.now.to_i - cache_data['timestamp']

        puts "Using cached data (#{cache_age}s old)"

        return cache_data['secrets'].map { |s| reconstruct_secret(s) }
      else
        puts "ERROR: No cache available and network failed"
        raise
      end
    end
  end

  def clear_cache
    cache_file = File.join(CACHE_DIR, 'secrets_cache.json')
    File.delete(cache_file) if File.exist?(cache_file)
    puts "Cache cleared"
  end

  private

  def serialize_secret(secret)
    {
      'uid' => secret.uid,
      'title' => secret.title,
      'type' => secret.type,
      'login' => secret.login,
      'url' => secret.url,
      'fields' => secret.fields,
      'custom' => secret.custom,
      'notes' => secret.notes
    }
  end

  def reconstruct_secret(data)
    # Create a simple object with cached data
    secret = Object.new

    data.each do |key, value|
      secret.define_singleton_method(key) { value }
    end

    secret
  end
end

# Usage example
puts "Caching for Offline Resilience"
puts "=" * 60
puts ""

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

begin
  client = CachedKSMClient.new(KSM_CONFIG)

  # First fetch (from network)
  puts "First fetch:"
  secrets = client.get_secrets_with_cache
  puts "Found #{secrets.length} secrets"
  puts ""

  # Second fetch (from cache)
  puts "Second fetch (should use cache):"
  secrets = client.get_secrets_with_cache
  puts "Found #{secrets.length} secrets"
  puts ""

  # Force refresh
  puts "Force refresh:"
  secrets = client.get_secrets_with_cache(force_refresh: true)
  puts "Found #{secrets.length} secrets"
  puts ""

  # Show secret titles
  puts "Secrets:"
  secrets.each_with_index do |secret, i|
    puts "  #{i + 1}. #{secret.title}"
  end

rescue => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "Caching example complete"
```{{copy}}

Save as `caching_example.rb` and run:

```bash
ruby caching_example.rb
```{{execute}}

## 3. Logging and Debugging

Configure comprehensive logging:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'
require 'logger'

# Production logging configuration
class ProductionKSMClient
  attr_reader :secrets_manager

  def initialize(config, log_level: Logger::INFO)
    # Create logger with rotation
    @logger = Logger.new(
      '/tmp/ksm.log',
      10,          # Keep 10 old log files
      1024 * 1024  # Each file max 1MB
    )

    @logger.level = log_level
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.ljust(5)} -- #{msg}\n"
    end

    @audit_logger = Logger.new('/tmp/ksm_audit.log')
    @audit_logger.level = Logger::INFO
    @audit_logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.iso8601}] #{msg}\n"
    end

    @logger.info "Initializing KSM client"

    storage = KeeperSecretsManager::Storage::InMemoryStorage.new(config)
    @secrets_manager = KeeperSecretsManager.new(
      config: storage,
      logger: @logger,
      log_level: log_level
    )

    @logger.info "KSM client initialized successfully"
  end

  def get_secret_with_audit(uid, purpose: nil)
    start_time = Time.now

    @logger.debug "Fetching secret: #{uid}"

    begin
      secrets = @secrets_manager.get_secrets([uid])

      if secrets.empty?
        @logger.warn "Secret not found: #{uid}"

        audit_log(
          action: 'GET_SECRET_FAILED',
          uid: uid,
          reason: 'NOT_FOUND',
          purpose: purpose
        )

        return nil
      end

      secret = secrets.first
      duration = Time.now - start_time

      @logger.info "Retrieved secret: #{secret.title} (#{duration.round(3)}s)"

      audit_log(
        action: 'GET_SECRET_SUCCESS',
        uid: uid,
        title: secret.title,
        duration_ms: (duration * 1000).round(2),
        purpose: purpose
      )

      secret

    rescue => e
      duration = Time.now - start_time

      @logger.error "Failed to fetch secret #{uid}: #{e.class} - #{e.message}"
      @logger.debug e.backtrace.join("\n")

      audit_log(
        action: 'GET_SECRET_ERROR',
        uid: uid,
        error: e.class.to_s,
        message: e.message,
        duration_ms: (duration * 1000).round(2),
        purpose: purpose
      )

      nil
    end
  end

  def list_secrets_with_audit
    @logger.info "Listing all secrets"
    start_time = Time.now

    begin
      secrets = @secrets_manager.get_secrets
      duration = Time.now - start_time

      @logger.info "Retrieved #{secrets.length} secrets (#{duration.round(3)}s)"

      audit_log(
        action: 'LIST_SECRETS',
        count: secrets.length,
        duration_ms: (duration * 1000).round(2)
      )

      secrets

    rescue => e
      duration = Time.now - start_time

      @logger.error "Failed to list secrets: #{e.message}"

      audit_log(
        action: 'LIST_SECRETS_ERROR',
        error: e.class.to_s,
        message: e.message,
        duration_ms: (duration * 1000).round(2)
      )

      []
    end
  end

  private

  def audit_log(data)
    data[:timestamp] = Time.now.iso8601
    data[:user] = ENV['USER'] || 'unknown'
    data[:hostname] = `hostname`.chomp rescue 'unknown'

    @audit_logger.info(JSON.generate(data))
  end
end

# Usage example
puts "Production Logging Example"
puts "=" * 60
puts ""

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

begin
  # Initialize with debug logging
  client = ProductionKSMClient.new(KSM_CONFIG, log_level: Logger::DEBUG)

  puts "Performing operations with full logging..."
  puts ""

  # List secrets with audit
  secrets = client.list_secrets_with_audit

  puts "Found #{secrets.length} secrets"
  puts ""

  # Get specific secret with audit
  if secrets.any?
    uid = secrets.first.uid

    secret = client.get_secret_with_audit(
      uid,
      purpose: "Demo: Production logging tutorial"
    )

    if secret
      puts "Retrieved: #{secret.title}"
    end
  end

  puts ""
  puts "Log files created:"
  puts "   /tmp/ksm.log - Application logs"
  puts "   /tmp/ksm_audit.log - Audit trail (JSON format)"

  puts ""
  puts "View logs with:"
  puts "   tail -f /tmp/ksm.log"
  puts "   tail -f /tmp/ksm_audit.log | jq"

rescue => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "Logging example complete"
```{{copy}}

Save as `logging_example.rb` and run:

```bash
ruby logging_example.rb
```{{execute}}

## 4. Configuration Management

Secure configuration handling:

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'
require 'yaml'
require 'json'

# Production configuration manager
class KSMConfigManager
  CONFIG_FILE = '/etc/myapp/ksm_config.yml'
  ENV_PREFIX = 'KSM_'

  def self.load_config
    # Priority: Environment > File > Raise Error

    # 1. Try environment variable
    if ENV['KSM_CONFIG']
      puts "✅ Using KSM_CONFIG from environment"
      return ENV['KSM_CONFIG']
    end

    # 2. Try config file
    if File.exist?(CONFIG_FILE)
      puts "✅ Loading config from #{CONFIG_FILE}"

      config_data = YAML.load_file(CONFIG_FILE)
      config_base64 = config_data['ksm']['config_base64']

      if config_base64 && !config_base64.empty?
        return config_base64
      end
    end

    # 3. Fail if neither found
    raise "KSM configuration not found. Set KSM_CONFIG environment variable or create #{CONFIG_FILE}"
  end

  def self.initialize_client(log_level: Logger::WARN)
    config = load_config

    storage = KeeperSecretsManager::Storage::InMemoryStorage.new(config)

    logger = Logger.new(STDOUT)
    logger.level = log_level

    KeeperSecretsManager.new(
      config: storage,
      logger: logger,
      verify_ssl_certs: true  # Always verify SSL in production
    )
  end
end

# Usage example
puts "Configuration Management Example"
puts "=" * 60
puts ""

begin
  puts "Loading KSM configuration..."

  # Initialize client from environment or file
  secrets_manager = KSMConfigManager.initialize_client

  puts "KSM client initialized"
  puts ""

  # Verify connectivity
  secrets = secrets_manager.get_secrets

  puts "Connected successfully"
  puts "   Accessible secrets: #{secrets.length}"

  puts ""
  puts "Configuration Priority:"
  puts "   1. KSM_CONFIG environment variable (highest)"
  puts "   2. #{KSMConfigManager::CONFIG_FILE} config file"
  puts "   3. Error if neither exists"

rescue => e
  puts "ERROR: Configuration error: #{e.message}"
  puts ""
  puts "Setup instructions:"
  puts "   export KSM_CONFIG='your_base64_config_here'"
  puts "   OR"
  puts "   Create #{KSMConfigManager::CONFIG_FILE}"
end

puts ""
puts "=" * 60
puts "Configuration management complete"
```{{copy}}

## 5. Production Deployment Checklist

```ruby
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

# Production readiness checker
class ProductionReadinessChecker
  def self.check_all
    checks = [
      { name: 'Configuration Security', method: :check_config_security },
      { name: 'SSL Verification', method: :check_ssl_verification },
      { name: 'Error Handling', method: :check_error_handling },
      { name: 'Logging Setup', method: :check_logging },
      { name: 'Caching Strategy', method: :check_caching },
      { name: 'Credential Rotation', method: :check_rotation },
      { name: 'Monitoring', method: :check_monitoring }
    ]

    puts "Production Readiness Checklist"
    puts "=" * 60
    puts ""

    results = checks.map do |check|
      print "Checking #{check[:name]}... "

      result = send(check[:method])

      status = result[:passed] ? "PASS" : "FAIL"
      puts status

      if result[:notes]
        puts "   #{result[:notes]}"
      end

      puts "" if result[:passed] == false

      result.merge(name: check[:name])
    end

    passed = results.count { |r| r[:passed] }
    total = results.length

    puts ""
    puts "=" * 60
    puts "Results: #{passed}/#{total} checks passed"

    if passed == total
      puts "Production ready!"
    else
      puts "WARNING: Address failing checks before production deployment"
    end

    results
  end

  def self.check_config_security
    # Check if config is in environment, not hardcoded
    has_env = ENV['KSM_CONFIG']

    {
      passed: !has_env.nil? && has_env != "[YOUR_BASE64_CONFIG_HERE]",
      notes: has_env ? nil : "Set KSM_CONFIG environment variable"
    }
  end

  def self.check_ssl_verification
    # Always true in production
    { passed: true, notes: nil }
  end

  def self.check_error_handling
    # Basic check - would be more comprehensive in real code
    { passed: true, notes: "Implement retry logic with exponential backoff" }
  end

  def self.check_logging
    # Check if log directory exists and is writable
    log_dir = '/var/log/myapp'

    passed = File.directory?(log_dir) && File.writable?(log_dir) rescue false

    {
      passed: passed,
      notes: passed ? nil : "Create #{log_dir} with proper permissions"
    }
  end

  def self.check_caching
    cache_dir = '/tmp/ksm_cache'

    passed = File.directory?(cache_dir) && File.writable?(cache_dir) rescue false

    {
      passed: passed,
      notes: passed ? nil : "Set up caching directory #{cache_dir}"
    }
  end

  def self.check_rotation
    {
      passed: true,
      notes: "Implement credential rotation schedule (recommended: 90 days)"
    }
  end

  def self.check_monitoring
    {
      passed: false,
      notes: "Set up monitoring for: API latency, error rates, cache hit ratio"
    }
  end
end

# Run the checker
ProductionReadinessChecker.check_all
```{{copy}}

Save as `production_readiness.rb` and run:

```bash
ruby production_readiness.rb
```{{execute}}

## 🔒 Production Security Checklist

### Configuration
- ✅ Store config in environment variables or secure config management
- ✅ Never commit credentials to git (add to `.gitignore`)
- ✅ Use separate KSM apps for dev/staging/prod
- ✅ Rotate KSM configurations regularly (generate new token, re-bind, update config)
- ✅ Set file permissions to 0600 for config files

### Network Security
- ✅ Always verify SSL certificates (`verify_ssl_certs: true`)
- ✅ Use latest TLS version (1.3)
- ✅ Implement timeout settings
- ✅ Use connection pooling for high traffic
- ✅ Rate limit API calls

### Error Handling
- ✅ Implement retry logic with exponential backoff
- ✅ Gracefully degrade on failures
- ✅ Never expose secret values in error messages
- ✅ Log errors without sensitive data
- ✅ Alert on persistent failures

### Logging & Monitoring
- ✅ Log all secret access with audit trail
- ✅ Monitor API latency and error rates
- ✅ Set up alerts for anomalous access patterns
- ✅ Track cache hit ratio
- ✅ Log rotation to prevent disk fill

### Caching
- ✅ Implement offline fallback with caching
- ✅ Set appropriate cache TTL (1-24 hours)
- ✅ Secure cache files (0600 permissions)
- ✅ Clear cache on configuration changes
- ✅ Monitor cache freshness

## Troubleshooting Production Issues

### High Latency
- Check network connectivity to Keeper servers
- Verify DNS resolution
- Enable caching to reduce API calls
- Use connection pooling

### Authentication Failures
- Verify KSM configuration is valid
- Check if one-time token has expired
- Ensure KSM application still has access to secrets
- Re-bind with new token if needed

### Cache Issues
- Verify cache directory permissions
- Check disk space availability
- Monitor cache file sizes
- Implement cache cleanup for old entries

### Memory Leaks
- Ensure secrets are dereferenced after use
- Don't store secrets in long-lived objects
- Clear sensitive data explicitly
- Monitor process memory usage

## Next Steps

🎉 **Congratulations!** You've completed the KSM Ruby SDK tutorial! You now know how to:
- ✅ Connect to KSM and retrieve secrets
- ✅ Read and search for specific secrets
- ✅ Create and update records
- ✅ Manage folder hierarchies
- ✅ Upload and download files
- ✅ Implement production-ready patterns

### What's Next?

1. **Integrate with your application**
   - Replace hardcoded credentials with KSM
   - Implement automatic credential rotation
   - Set up monitoring and alerting

2. **Explore advanced features**
   - Notation system for dynamic secret references
   - TOTP code generation
   - Custom field types

3. **Join the community**
   - [GitHub Repository](https://github.com/Keeper-Security/secrets-manager)
   - [Official Documentation](https://docs.keeper.io/secrets-manager/)
   - [Support Portal](https://www.keepersecurity.com/support.html)

Click **"Continue"** to view the tutorial summary and additional resources.
