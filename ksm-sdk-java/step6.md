# Step 6: Advanced File Management - Upload and Remove Files

This step demonstrates the new file removal capability in Keeper Secrets Manager SDK, allowing you to programmatically remove file attachments from records.

## Overview

The SDK now supports removing files from records using the `UpdateOptions` class with the `linksToRemove` parameter. This enables automated file management workflows.

## 1. Create the File Management Demo Class

Create a new Java class to demonstrate file upload and removal:

`touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/FileRemovalDemo.java`{{execute}}

## 2. Add the File Management Code

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import static com.keepersecurity.secretsManager.core.SecretsManager.*;
import java.util.*;

public class FileRemovalDemo {
    
    private static final String CONFIG_FILE_NAME = "ksm-config.json";
    
    public static void main(String[] args) {
        System.out.println("📁 File Upload and Removal Demo");
        System.out.println("================================\n");
        
        LocalConfigStorage storage = new LocalConfigStorage(CONFIG_FILE_NAME);
        SecretsManagerOptions options = null;
        
        try {
            options = new SecretsManagerOptions(storage);
            
            // Step 1: Get first available record
            System.out.println("Step 1: Finding a record to work with...");
            KeeperSecrets allRecords = getSecrets(options);
            if (allRecords.getRecords().isEmpty()) {
                System.out.println("❌ No records found in vault");
                return;
            }
            
            KeeperRecord record = allRecords.getRecords().get(0);
            String recordUid = record.getRecordUid();
            System.out.println("✅ Using record: " + record.getData().getTitle());
            System.out.println("   UID: " + recordUid);
            
            // Step 2: Get record with file details
            System.out.println("\nStep 2: Checking existing files...");
            QueryOptions queryOptions = new QueryOptions(
                Arrays.asList(recordUid),     // specific record
                Collections.emptyList(),      // no folder filter
                true                          // request files/links
            );
            
            KeeperSecrets recordDetails = getSecrets2(options, queryOptions);
            KeeperRecord targetRecord = recordDetails.getRecords().get(0);
            
            // Display existing files
            List<KeeperFile> existingFiles = targetRecord.getFiles();
            int initialFileCount = existingFiles != null ? existingFiles.size() : 0;
            System.out.println("📊 Current files in record: " + initialFileCount);
            
            if (existingFiles != null && !existingFiles.isEmpty()) {
                System.out.println("Existing files:");
                for (KeeperFile file : existingFiles) {
                    System.out.println("  • " + file.getFileUid() + " - " + 
                        (file.getData() != null ? file.getData().getTitle() : "Untitled"));
                }
            }
            
            // Step 3: Upload test files
            System.out.println("\nStep 3: Uploading test files...");
            
            // Upload first file
            byte[] content1 = "This is test file content #1\nCreated for demonstration".getBytes();
            KeeperFileUpload upload1 = new KeeperFileUpload(
                "test_document_1.txt",        // filename
                "Test Document #1",           // title
                "text/plain",                 // MIME type
                content1                      // content
            );
            
            String fileUid1 = uploadFile(options, targetRecord, upload1);
            System.out.println("✅ Uploaded file 1: " + fileUid1);
            
            // Refresh record before second upload
            recordDetails = getSecrets2(options, queryOptions);
            targetRecord = recordDetails.getRecords().get(0);
            
            // Upload second file
            byte[] content2 = "This is test file content #2\nAlso for demonstration".getBytes();
            KeeperFileUpload upload2 = new KeeperFileUpload(
                "test_document_2.txt",
                "Test Document #2", 
                "text/plain",
                content2
            );
            
            String fileUid2 = uploadFile(options, targetRecord, upload2);
            System.out.println("✅ Uploaded file 2: " + fileUid2);
            
            // Step 4: Verify uploads
            System.out.println("\nStep 4: Verifying uploads...");
            recordDetails = getSecrets2(options, queryOptions);
            targetRecord = recordDetails.getRecords().get(0);
            List<KeeperFile> afterUpload = targetRecord.getFiles();
            
            System.out.println("📁 Files after upload: " + 
                (afterUpload != null ? afterUpload.size() : 0));
            
            if (afterUpload != null) {
                for (KeeperFile file : afterUpload) {
                    System.out.println("  • " + file.getFileUid() + " - " + 
                        (file.getData() != null ? file.getData().getTitle() : "Untitled"));
                }
            }
            
            // Wait a moment for user to see the state
            Thread.sleep(2000);
            
            // Step 5: Remove uploaded files using UpdateOptions
            System.out.println("\n🗑️ Step 5: Removing the uploaded files...");
            System.out.println("Files to remove: [" + fileUid1 + ", " + fileUid2 + "]");
            
            // Create UpdateOptions with files to remove
            UpdateOptions removeOptions = new UpdateOptions(
                null,                                    // transactionType (null for default)
                Arrays.asList(fileUid1, fileUid2)      // linksToRemove - list of file UIDs
            );
            
            // Execute the removal
            updateSecretWithOptions(options, targetRecord, removeOptions);
            System.out.println("✅ Removal command executed");
            
            // Step 6: Verify removal
            System.out.println("\nStep 6: Verifying file removal...");
            KeeperSecrets afterRemoval = getSecrets2(options, queryOptions);
            List<KeeperFile> finalFiles = afterRemoval.getRecords().get(0).getFiles();
            
            int finalFileCount = finalFiles != null ? finalFiles.size() : 0;
            System.out.println("📊 Files after removal: " + finalFileCount);
            
            // Check if specific files were removed
            boolean file1Removed = true;
            boolean file2Removed = true;
            
            if (finalFiles != null) {
                for (KeeperFile file : finalFiles) {
                    if (file.getFileUid().equals(fileUid1)) file1Removed = false;
                    if (file.getFileUid().equals(fileUid2)) file2Removed = false;
                    
                    System.out.println("  • " + file.getFileUid() + " - " + 
                        (file.getData() != null ? file.getData().getTitle() : "Untitled"));
                }
            }
            
            // Final results
            System.out.println("\n🎯 Results:");
            System.out.println("  Initial file count: " + initialFileCount);
            System.out.println("  Files uploaded: 2");
            System.out.println("  Files removed: 2");
            System.out.println("  Final file count: " + finalFileCount);
            System.out.println("  Test file 1 removed: " + (file1Removed ? "✅ Yes" : "❌ No"));
            System.out.println("  Test file 2 removed: " + (file2Removed ? "✅ Yes" : "❌ No"));
            
            if (file1Removed && file2Removed) {
                System.out.println("\n✅ SUCCESS: File removal feature working correctly!");
            }
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```{{copy}}

## 3. Run the File Management Demo

Execute the demo to see file upload and removal in action:

`gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.FileRemovalDemo run --console=plain`{{execute}}

### Expected Output

```
📁 File Upload and Removal Demo
================================

Step 1: Finding a record to work with...
✅ Using record: [Record Title]
   UID: [Record UID]

Step 2: Checking existing files...
📊 Current files in record: [number]

Step 3: Uploading test files...
✅ Uploaded file 1: [file UID]
✅ Uploaded file 2: [file UID]

Step 4: Verifying uploads...
📁 Files after upload: [number]

🗑️ Step 5: Removing the uploaded files...
✅ Removal command executed

Step 6: Verifying file removal...
📊 Files after removal: [number]

🎯 Results:
  Test file 1 removed: ✅ Yes
  Test file 2 removed: ✅ Yes

✅ SUCCESS: File removal feature working correctly!
```

## Understanding the Code

### Key Components

1. **UpdateOptions Class**: The new class that enables file removal
   ```java
   UpdateOptions removeOptions = new UpdateOptions(
       null,                    // transactionType
       Arrays.asList(fileUids)  // linksToRemove - file UIDs to remove
   );
   ```

2. **updateSecretWithOptions Method**: Executes the removal
   ```java
   updateSecretWithOptions(options, record, updateOptions);
   ```

3. **File UIDs**: Each file has a unique identifier used for removal
   ```java
   String fileUid = uploadFile(options, record, upload);
   ```

### Important Notes

- **Atomic Operation**: All specified files are removed in a single transaction
- **File UIDs Required**: You must know the specific file UIDs to remove them
- **Refresh Record State**: Always refresh the record after operations for accurate state
- **Batch Removal**: Can remove multiple files in one operation

## Use Cases

### Selective File Removal

Remove files based on specific criteria:

```java
// Remove only temporary files
List<String> filesToRemove = new ArrayList<>();
for (KeeperFile file : record.getFiles()) {
    if (file.getData().getTitle().startsWith("temp_")) {
        filesToRemove.add(file.getFileUid());
    }
}

if (!filesToRemove.isEmpty()) {
    UpdateOptions cleanup = new UpdateOptions(null, filesToRemove);
    updateSecretWithOptions(options, record, cleanup);
}
```

### File Rotation

Replace old files with new versions:

```java
// Remove old version
UpdateOptions removeOld = new UpdateOptions(null, Arrays.asList(oldFileUid));
updateSecretWithOptions(options, record, removeOld);

// Upload new version
KeeperFileUpload newFile = new KeeperFileUpload(
    "document_v2.pdf", "Updated Document", "application/pdf", newContent
);
String newFileUid = uploadFile(options, record, newFile);
```

## Next Steps

In the next step, you'll learn about GraphSync™ - the new record linking feature that enables you to establish and traverse relationships between Keeper records.