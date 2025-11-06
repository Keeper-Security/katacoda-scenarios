# Step 4: Folder Management

**Learning Objective**: Master folder operations including creation, hierarchy navigation, and organizing secrets.

## What You'll Accomplish

In this step, you'll learn how to:
- List all accessible folders
- Create new folders in shared folder hierarchies
- Update folder names
- Navigate folder hierarchies
- Create secrets in specific folders
- Delete folders safely

## Why Folder Management Matters

**Business Benefits:**
- **Organized access control** - folders define permission boundaries
- **Team-based secret organization** - separate dev/staging/prod
- **Audit scope** - track access by folder

**Technical Benefits:**
- **Hierarchical organization** - nested folder structures
- **Shared folder roots** - team-based secret sharing
- **Automatic inheritance** - subfolders inherit parent permissions

## 1. Listing All Folders

Let's start by exploring your folder structure. Create the `list_folders.rb` file:

```
cat > list_folders.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Listing Folders"
puts "=" * 60
puts ""

begin
  # Get all folders
  folders = secrets_manager.get_folders

  puts "Found #{folders.length} folder(s)"
  puts ""

  if folders.empty?
    puts "WARNING: No folders accessible to this KSM application"
    puts "Share a folder with your KSM app in Keeper Vault first"
  else
    folders.each_with_index do |folder, index|
      # Folder properties
      indent = folder.parent_uid && !folder.parent_uid.empty? ? "  " : ""

      puts "#{index + 1}. #{indent}#{folder.name}"
      puts "#{indent}   UID: #{folder.uid}"
      puts "#{indent}   Parent: #{folder.parent_uid || '(root shared folder)'}"
      puts "#{indent}   Records: #{folder.records&.length || 0}"
      puts ""
    end

    # Show folder hierarchy
    puts "Folder Hierarchy:"
    puts "-" * 60

    # Find root folders (no parent)
    root_folders = folders.select { |f| f.parent_uid.nil? || f.parent_uid.empty? }

    root_folders.each do |root|
      puts "[Folder] #{root.name} (#{root.uid})"

      # Find children
      children = folders.select { |f| f.parent_uid == root.uid }
      children.each do |child|
        puts "  └─ [Folder] #{child.name} (#{child.uid})"

        # Find grandchildren
        grandchildren = folders.select { |f| f.parent_uid == child.uid }
        grandchildren.each do |grandchild|
          puts "     └─ [Folder] #{grandchild.name} (#{grandchild.uid})"
        end
      end
    end
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"
end

puts ""
puts "=" * 60
puts "Folder listing complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby list_folders.rb
```{{execute}}

**Expected Output:**
```
Listing Folders
============================================================

Found 5 folder(s)

1. DevOps Secrets
   UID: lPxZXk...
   Parent: (root shared folder)
   Records: 3

2.   Production
   UID: mQyAYl...
   Parent: lPxZXk...
   Records: 5

3.   Staging
   UID: nRzBZm...
   Parent: lPxZXk...
   Records: 2

Folder Hierarchy:
------------------------------------------------------------
DevOps Secrets (lPxZXk...)
  └─ Production (mQyAYl...)
  └─ Staging (nRzBZm...)

============================================================
Folder listing complete
```

## 2. Creating Folders

Create new folders in your shared folder structure. Create the `create_folder.rb` file:

```
cat > create_folder.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Creating New Folders"
puts "=" * 60
puts ""

begin
  # First, get existing folders to find a parent
  folders = secrets_manager.get_folders

  if folders.empty?
    puts "ERROR: No folders found. You need at least one shared folder to create subfolders."
    exit 1
  end

  # Use the first folder as parent
  parent_folder = folders.first

  puts "Parent Folder: #{parent_folder.name}"
  puts "Parent UID: #{parent_folder.uid}"
  puts ""

  # Create a new subfolder
  folder_name = "Ruby SDK Demo - #{Time.now.strftime('%Y%m%d-%H%M%S')}"

  puts "Creating folder: #{folder_name}"

  folder_uid = secrets_manager.create_folder(
    folder_name,
    parent_uid: parent_folder.uid
  )

  puts "Folder created successfully!"
  puts "   UID: #{folder_uid}"
  puts ""

  # Verify by fetching folders again
  sleep 1
  updated_folders = secrets_manager.get_folders

  new_folder = updated_folders.find { |f| f.uid == folder_uid }

  if new_folder
    puts "Verification:"
    puts "   Name: #{new_folder.name}"
    puts "   UID: #{new_folder.uid}"
    puts "   Parent: #{new_folder.parent_uid}"
  end

rescue ArgumentError => e
  puts "ERROR: Validation Error: #{e.message}"

rescue KeeperSecretsManager::Error => e
  puts "ERROR: KSM Error: #{e.message}"
  puts ""
  puts "Common issues:"
  puts "- Ensure parent_uid is a valid folder UID"
  puts "- Check that your KSM app has permission to create folders"
end

puts ""
puts "=" * 60
puts "Folder creation complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby create_folder.rb
```{{execute}}

## 3. Updating Folder Names

Rename existing folders. Create the `update_folder.rb` file:

```
cat > update_folder.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Updating Folder Name"
puts "=" * 60
puts ""

begin
  # Get all folders
  folders = secrets_manager.get_folders

  # Find a folder to rename (look for our demo folders)
  demo_folder = folders.find { |f| f.name.include?('Ruby SDK Demo') }

  if demo_folder.nil?
    puts "WARNING: No demo folder found to rename"
    puts "Create one first with create_folder.rb"
    exit 0
  end

  puts "Current name: #{demo_folder.name}"
  puts "Folder UID: #{demo_folder.uid}"
  puts ""

  # Update the name
  new_name = "#{demo_folder.name} - Updated"

  puts "Updating to: #{new_name}"

  secrets_manager.update_folder(demo_folder.uid, new_name)

  puts "Folder name updated!"
  puts ""

  # Verify
  sleep 1
  updated_folders = secrets_manager.get_folders
  updated_folder = updated_folders.find { |f| f.uid == demo_folder.uid }

  if updated_folder
    puts "Verification:"
    puts "   New name: #{updated_folder.name}"
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "Folder update complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby update_folder.rb
```{{execute}}

## 4. Working with Folder Hierarchy

Use the FolderManager for advanced operations. Create the `folder_hierarchy.rb` file:

```
cat > folder_hierarchy.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Folder Hierarchy Navigation"
puts "=" * 60
puts ""

begin
  # Get the folder manager
  folder_manager = secrets_manager.folder_manager

  # Get folder path (shows full hierarchy)
  folders = secrets_manager.get_folders

  folders.each do |folder|
    # Get full path for this folder
    path = folder_manager.get_folder_path(folder.uid)

    puts "Folder: #{folder.name}"
    puts "  Path: #{path}"
    puts "  UID: #{folder.uid}"
    puts ""
  end

  # Find folder by name
  puts "Search by Name:"
  puts "-" * 60

  search_name = "Production"
  found = folder_manager.find_folder_by_name(search_name)

  if found
    puts "Found: #{found.name}"
    puts "  UID: #{found.uid}"
    puts "  Path: #{folder_manager.get_folder_path(found.uid)}"
  else
    puts "No folder named '#{search_name}' found"
  end

rescue StandardError => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
puts "Hierarchy navigation complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby folder_hierarchy.rb
```{{execute}}

## 5. Creating Secrets in Specific Folders

Combine folder and record creation. Create the `create_folder_with_secrets.rb` file:

```
cat > create_folder_with_secrets.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Create Folder and Add Secrets"
puts "=" * 60
puts ""

begin
  # Get folders
  folders = secrets_manager.get_folders
  parent_folder = folders.first

  if parent_folder.nil?
    puts "ERROR: No folders available"
    exit 1
  end

  # Step 1: Create a new folder
  folder_name = "App Secrets - #{Time.now.strftime('%Y%m%d')}"
  puts "1. Creating folder: #{folder_name}"

  folder_uid = secrets_manager.create_folder(
    folder_name,
    parent_uid: parent_folder.uid
  )

  puts "   Folder created: #{folder_uid}"
  puts ""

  sleep 1

  # Step 2: Create secrets in that folder
  puts "2. Creating secrets in folder..."

  3.times do |i|
    record_data = {
      'type' => 'login',
      'title' => "App Secret #{i + 1}",
      'fields' => [
        { 'type' => 'login', 'value' => ["user#{i + 1}@example.com"] },
        { 'type' => 'password', 'value' => ["P@ssw0rd#{i + 1}!"] }
      ]
    }

    options = KeeperSecretsManager::Dto::CreateOptions.new
    options.folder_uid = parent_folder.uid    # Shared folder root
    options.subfolder_uid = folder_uid        # Newly created subfolder

    record_uid = secrets_manager.create_secret(record_data, options)
    puts "   Created: App Secret #{i + 1} (#{record_uid})"

    sleep 0.5
  end

  puts ""
  puts "Folder and secrets created successfully!"

rescue StandardError => e
  puts "ERROR: #{e.message}"
end

puts ""
puts "=" * 60
EOF
```{{execute}}

Now run the script:

```bash
ruby create_folder_with_secrets.rb
```{{execute}}

## 6. Deleting Folders

**⚠️ CAUTION**: Deleting folders can delete contained records!

Create the `delete_folders.rb` file:

```
cat > delete_folders.rb << 'EOF'
#!/usr/bin/env ruby

require 'keeper_secrets_manager'

KSM_CONFIG = ENV['KSM_CONFIG'] || "[YOUR_BASE64_CONFIG_HERE]"

storage = KeeperSecretsManager::Storage::InMemoryStorage.new(KSM_CONFIG)
secrets_manager = KeeperSecretsManager.new(config: storage)

puts "Deleting Folders"
puts "=" * 60
puts ""

begin
  # Get all folders
  folders = secrets_manager.get_folders

  # Find demo folders to delete
  demo_folders = folders.select { |f| f.name.include?('Ruby SDK Demo') || f.name.include?('App Secrets') }

  if demo_folders.empty?
    puts "WARNING: No demo folders to delete"
    exit 0
  end

  puts "Found #{demo_folders.length} demo folder(s) to delete:"
  demo_folders.each { |f| puts "  - #{f.name} (#{f.uid})" }
  puts ""

  folder_uids = demo_folders.map(&:uid)

  # Delete folders (force: true deletes even if contains records)
  puts "Deleting folders..."
  deleted = secrets_manager.delete_folder(folder_uids, force: true)

  puts "Deleted #{deleted.length} folder(s)"

  deleted.each do |uid|
    folder = demo_folders.find { |f| f.uid == uid }
    puts "   Deleted: #{folder&.name || uid}"
  end

rescue KeeperSecretsManager::Error => e
  puts "ERROR: #{e.message}"
  puts ""
  puts "Note: Folders with records require force: true"
end

puts ""
puts "=" * 60
puts "Folder deletion complete"
EOF
```{{execute}}

Now run the script:

```bash
ruby delete_folders.rb
```{{execute}}

**⚠️ Security Warning**: Always verify folders before deletion in production!

## Understanding Folder Structure

### Shared Folder Roots
- **Root folders** have no `parent_uid` (or empty string)
- These are the "shared folders" in Keeper
- Your KSM application must have access to at least one root folder

### Subfolders
- **Subfolders** have a `parent_uid` pointing to another folder
- Can be nested multiple levels deep
- Inherit permissions from parent

### Folder Keys
- Each folder has its own encryption key (`folder_key`)
- Root folder keys encrypted with app key
- Subfolder keys encrypted with parent's shared folder key

## 🔒 Security Best Practices

**DO:**
- Organize secrets by environment (dev/staging/prod folders)
- Use descriptive folder names
- Create folder structure before bulk secret creation
- Verify folder UIDs before creating secrets
- Document folder purposes in notes

❌ **DON'T:**
- Delete folders without checking contents first
- Create deep nesting (keep it simple, max 3 levels)
- Mix environments in same folder
- Ignore folder permissions when sharing

## Troubleshooting

### Error: "Folder {uid} not found"
- **Cause:** Invalid folder UID or no access
- **Solution:** Verify with `get_folders` and check KSM app permissions

### Error: "parent_uid is required to create a folder"
- **Cause:** Missing parent folder UID
- **Solution:** All new folders need a parent (use a shared folder UID)

### Cannot delete folder
- **Cause:** Folder contains records
- **Solution:** Use `force: true` or delete records first

### Folder hierarchy shows incorrectly
- **Cause:** Folder decryption order issue
- **Solution:** This is handled automatically by the SDK

## Next Steps

🎉 **Congratulations!** You've mastered folder management! You can now:
- List and navigate folder hierarchies
- Create and organize folders
- Update folder names
- Delete folders safely

In **Step 5**, you'll learn how to:
- Upload files to secrets
- Download files from secrets
- Manage file metadata
- Handle multiple files per record

Click **"Continue"** to proceed to Step 5: File Operations.
