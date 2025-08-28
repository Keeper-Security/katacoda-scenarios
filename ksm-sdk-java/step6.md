# Step 6: GraphSync™ Record Linking and File Management

This step demonstrates two powerful new features in the Keeper Secrets Manager Java SDK: GraphSync™ record linking for establishing relationships between records, and advanced file management including programmatic file removal.

## Part 1: GraphSync™ Record Linking

GraphSync™ allows you to establish and traverse relationships between Keeper records using a Directed Acyclic Graph structure.

### 1. Create Java Class: GraphSyncDemo

Create a new Java class to demonstrate GraphSync™ functionality:

```bash
touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/GraphSyncDemo.java
```
`touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/GraphSyncDemo.java`{{execute}}

### Add the GraphSync™ Demo Code

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import static com.keepersecurity.secretsManager.core.SecretsManager.*;
import java.util.*;
import java.util.stream.Collectors;

public class GraphSyncDemo {
    
    private static final String CONFIG_FILE_NAME = "ksm-config.json";
    
    public static void main(String[] args) {
        System.out.println("🔗 GraphSync™ Record Linking Demo\n");
        
        LocalConfigStorage storage = new LocalConfigStorage(CONFIG_FILE_NAME);
        SecretsManagerOptions options = null;
        
        try {
            options = new SecretsManagerOptions(storage);
            
            // IMPORTANT: Request links with QueryOptions
            QueryOptions queryOptions = new QueryOptions(
                Collections.emptyList(),  // no record filter
                Collections.emptyList(),  // no folder filter  
                true                      // requestLinks - MUST be true
            );
            
            System.out.println("📊 Retrieving records with GraphSync™ links...\n");
            KeeperSecrets secrets = getSecrets2(options, queryOptions);
            
            // Build relationship map
            Map<String, List<String>> linkMap = new HashMap<>();
            Map<String, String> recordTitles = new HashMap<>();
            
            for (KeeperRecord record : secrets.getRecords()) {
                recordTitles.put(record.getRecordUid(), record.getTitle());
                
                List<KeeperRecordLink> links = record.getLinks();
                if (links != null && !links.isEmpty()) {
                    List<String> linkedUids = links.stream()
                        .map(KeeperRecordLink::getRecordUid)
                        .collect(Collectors.toList());
                    linkMap.put(record.getRecordUid(), linkedUids);
                    
                    // Display link details
                    System.out.println("📌 " + record.getTitle());
                    for (KeeperRecordLink link : links) {
                        System.out.println("  → Links to: " + link.getRecordUid());
                        
                        // Check link properties
                        if (link.getPath() != null) {
                            System.out.println("    Type: " + link.getPath());
                        }
                        if (link.isAdminUser()) {
                            System.out.println("    🔑 Admin privileges");
                        }
                        if (link.allowsRotation()) {
                            System.out.println("    🔄 Allows rotation");
                        }
                        
                        // Access encrypted link data if available
                        Map<String, Object> linkData = link.getLinkData(record.getRecordKey());
                        if (linkData != null) {
                            System.out.println("    📦 Has encrypted settings: " + linkData.keySet());
                        }
                    }
                    System.out.println();
                }
            }
            
            // Analyze relationships
            System.out.println("📈 GraphSync™ Analysis:");
            System.out.println("  Total records: " + secrets.getRecords().size());
            System.out.println("  Records with links: " + linkMap.size());
            
            // Find dependency chains
            Set<String> targets = new HashSet<>();
            for (List<String> links : linkMap.values()) {
                targets.addAll(links);
            }
            System.out.println("  Link target records: " + targets.size());
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```{{copy}}

### Run GraphSync™ Demo

```bash
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.GraphSyncDemo run --console=plain
```
`gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.GraphSyncDemo run --console=plain`{{execute}}

## Part 2: Advanced File Management with Removal

Now let's demonstrate file upload and removal capabilities.

### 2. Create Java Class: FileManagementDemo

```bash
touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/FileManagementDemo.java
```
`touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/FileManagementDemo.java`{{execute}}

### Add the File Management Code

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import static com.keepersecurity.secretsManager.core.SecretsManager.*;
import java.util.*;

public class FileManagementDemo {
    
    private static final String CONFIG_FILE_NAME = "ksm-config.json";
    
    public static void main(String[] args) {
        System.out.println("📁 File Upload and Removal Demo\n");
        
        LocalConfigStorage storage = new LocalConfigStorage(CONFIG_FILE_NAME);
        SecretsManagerOptions options = null;
        
        try {
            options = new SecretsManagerOptions(storage);
            
            // Get first available record
            KeeperSecrets allRecords = getSecrets(options);
            if (allRecords.getRecords().isEmpty()) {
                System.out.println("❌ No records found");
                return;
            }
            
            KeeperRecord record = allRecords.getRecords().get(0);
            String recordUid = record.getRecordUid();
            System.out.println("📝 Using record: " + record.getData().getTitle());
            
            // Get record with file details
            QueryOptions queryOptions = new QueryOptions(
                Arrays.asList(recordUid),
                Collections.emptyList(),
                true  // Request files
            );
            
            KeeperSecrets recordDetails = getSecrets2(options, queryOptions);
            KeeperRecord targetRecord = recordDetails.getRecords().get(0);
            
            // Check existing files
            List<KeeperFile> existingFiles = targetRecord.getFiles();
            System.out.println("📊 Existing files: " + 
                (existingFiles != null ? existingFiles.size() : 0));
            
            // Step 1: Upload test files
            System.out.println("\n📤 Uploading test files...");
            
            byte[] content1 = "Test file content #1".getBytes();
            KeeperFileUpload upload1 = new KeeperFileUpload(
                "test_doc_1.txt",
                "Test Document 1",
                "text/plain",
                content1
            );
            
            String fileUid1 = uploadFile(options, targetRecord, upload1);
            System.out.println("✅ Uploaded: " + fileUid1);
            
            // Refresh record for second upload
            recordDetails = getSecrets2(options, queryOptions);
            targetRecord = recordDetails.getRecords().get(0);
            
            byte[] content2 = "Test file content #2".getBytes();
            KeeperFileUpload upload2 = new KeeperFileUpload(
                "test_doc_2.txt",
                "Test Document 2", 
                "text/plain",
                content2
            );
            
            String fileUid2 = uploadFile(options, targetRecord, upload2);
            System.out.println("✅ Uploaded: " + fileUid2);
            
            // Refresh and verify uploads
            recordDetails = getSecrets2(options, queryOptions);
            targetRecord = recordDetails.getRecords().get(0);
            List<KeeperFile> afterUpload = targetRecord.getFiles();
            
            System.out.println("\n📁 Files after upload: " + 
                (afterUpload != null ? afterUpload.size() : 0));
            
            if (afterUpload != null) {
                for (KeeperFile file : afterUpload) {
                    System.out.println("  • " + file.getFileUid() + 
                        " - " + (file.getData() != null ? file.getData().getTitle() : ""));
                }
            }
            
            // Step 2: Remove uploaded files using UpdateOptions
            System.out.println("\n🗑️ Removing uploaded files...");
            
            UpdateOptions removeOptions = new UpdateOptions(
                null,  // transactionType
                Arrays.asList(fileUid1, fileUid2)  // files to remove
            );
            
            updateSecretWithOptions(options, targetRecord, removeOptions);
            System.out.println("✅ Files removed successfully");
            
            // Step 3: Verify removal
            KeeperSecrets afterRemoval = getSecrets2(options, queryOptions);
            List<KeeperFile> finalFiles = afterRemoval.getRecords().get(0).getFiles();
            
            System.out.println("\n📊 Files after removal: " + 
                (finalFiles != null ? finalFiles.size() : 0));
            
            // Check specific files were removed
            boolean file1Removed = true;
            boolean file2Removed = true;
            
            if (finalFiles != null) {
                for (KeeperFile file : finalFiles) {
                    if (file.getFileUid().equals(fileUid1)) file1Removed = false;
                    if (file.getFileUid().equals(fileUid2)) file2Removed = false;
                }
            }
            
            System.out.println("🎯 Verification:");
            System.out.println("  File 1 removed: " + (file1Removed ? "✅" : "❌"));
            System.out.println("  File 2 removed: " + (file2Removed ? "✅" : "❌"));
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```{{copy}}

### Run File Management Demo

```bash
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.FileManagementDemo run --console=plain
```
`gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.FileManagementDemo run --console=plain`{{execute}}

## Understanding the New Features

### GraphSync™ Key Points:
- **QueryOptions**: Must set `requestLinks=true` to retrieve link data
- **Link Properties**: Check admin status, rotation permissions, connection settings
- **Encrypted Data**: Use `getLinkData()` to decrypt link metadata
- **Relationships**: Build dependency maps and traverse record connections

### File Management Key Points:
- **UpdateOptions**: Transaction-based updates with `linksToRemove` parameter
- **File UIDs**: Each file has a unique identifier for targeted removal
- **Batch Operations**: Remove multiple files in a single transaction
- **State Management**: Refresh record after each operation for accurate state

## Next Steps

You've now learned how to:
- Use GraphSync™ to work with record relationships
- Upload files to records programmatically
- Remove files using UpdateOptions
- Build dependency maps from linked records

These features enable powerful automation scenarios for managing complex credential infrastructures and file attachments in your Keeper Vault.