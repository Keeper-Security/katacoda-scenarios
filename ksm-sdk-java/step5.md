# Step 5: Advanced Get Options, Caching & Record Deletion

This final step explores advanced options for retrieving secrets, implementing client-side caching for performance, and how to delete records using the KSM Java SDK.

## 1. Advanced Get Secrets Options (Filtering)

The `SecretsManager.getSecrets()` method can take a list of record UIDs to fetch specific records. If you need to filter records based on other criteria like title or type after fetching all, you would do that in your Java code by iterating through the results.

## 2. Secret Caching for Performance

The KSM SDK supports caching of secrets to reduce latency and the number of API calls to Keeper servers for frequently accessed secrets. In-memory configuration using a Base64 string (covered conceptually as part of initialization elsewhere) is also a key advanced configuration.

### Create/Modify Java Class: AdvancedOperationsDemo

```bash
# Example: touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/AdvancedOperationsDemo.java
# Ensure your package structure matches.
```
`# For this tutorial, we assume you are modifying an existing class or creating one with this name.`{{execute}}

### Add/Modify the Java Code for Caching and Record Deletion

Paste or update the following code into your Java file (e.g., `AdvancedOperationsDemo.java`):

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import static com.keepersecurity.secretsManager.core.SecretsManager.initializeStorage;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class AdvancedOperationsDemo {

    private static final String ONE_TIME_TOKEN = "[ONE_TIME_TOKEN_IF_NEEDED]"; // Only if ksm-config.json doesn't exist
    private static final String CONFIG_FILE_NAME = "ksm-config.json";
    
    // ⚠️ Replace with the UID of a record you want to use for deletion testing (e.g., created in Step 3)
    private static String RECORD_UID_TO_DELETE = "[RECORD_UID_FOR_DELETION_TEST]";
    // ⚠️ Replace with the UID of a folder where a test record can be created for deletion.
    private static final String TARGET_FOLDER_UID_FOR_TEST_RECORD = "[YOUR_SHARED_FOLDER_UID_HERE]";

    public static void main(String[] args) throws InterruptedException {
        System.out.println("🚀 Demonstrating KSM Secret Caching and Record Deletion...");
        LocalConfigStorage storage = new LocalConfigStorage(CONFIG_FILE_NAME);
        SecretsManagerOptions optionsWithCache = null;

        try {
            if (!new File(CONFIG_FILE_NAME).exists() || (ONE_TIME_TOKEN != null && !ONE_TIME_TOKEN.startsWith("["))) {
                System.out.println("🔑 Initializing KSM storage...");
                initializeStorage(storage, ONE_TIME_TOKEN);
            }

            // Configure caching. Cache for 60 seconds in this example.
            long cacheRefreshIntervalSeconds = 60;
            optionsWithCache = new SecretsManagerOptions(storage, null, false, cacheRefreshIntervalSeconds);

            System.out.println("\n--- First secrets fetch (populates cache) ---");
            long startTime = System.nanoTime();
            KeeperSecrets secrets1 = SecretsManager.getSecrets(optionsWithCache);
            long duration1 = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startTime);
            System.out.println("✅ Fetched " + secrets1.getRecords().size() + " records in " + duration1 + " ms (from server, cache populated).");

            System.out.println("\n--- Second secrets fetch (should be from cache) ---");
            startTime = System.nanoTime();
            KeeperSecrets secrets2 = SecretsManager.getSecrets(optionsWithCache);
            long duration2 = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startTime);
            System.out.println("✅ Fetched " + secrets2.getRecords().size() + " records in " + duration2 + " ms (from cache).");

            if (duration2 < duration1) {
                System.out.println("⚡️ Performance improvement observed due to caching!");
            }

            System.out.println("\nWaiting for cache to expire (configured for " + cacheRefreshIntervalSeconds + " seconds)...");
            TimeUnit.SECONDS.sleep(cacheRefreshIntervalSeconds + 5); // Wait a bit longer

            System.out.println("\n--- Third secrets fetch (cache expired, should fetch from server again) ---");
            startTime = System.nanoTime();
            KeeperSecrets secrets3 = SecretsManager.getSecrets(optionsWithCache);
            long duration3 = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startTime);
            System.out.println("✅ Fetched " + secrets3.getRecords().size() + " records in " + duration3 + " ms (from server, cache repopulated).");

            // --- Record Deletion Example ---
            System.out.println("\n--- Record Deletion Example ---");
            // For safety, let's create a temporary record to delete, if a specific one isn't provided.
            if (RECORD_UID_TO_DELETE.startsWith("[")) { // Check if placeholder is still there
                System.out.println("ℹ️ RECORD_UID_TO_DELETE placeholder not replaced. Creating a temporary record for deletion test.");
                if (TARGET_FOLDER_UID_FOR_TEST_RECORD.startsWith("[")){
                     System.err.println("❌ Cannot create temp record: TARGET_FOLDER_UID_FOR_TEST_RECORD placeholder not replaced. Skipping deletion test.");
                } else {
                    KeeperRecordData tempRecData = new KeeperRecordData("Temp Record for Deletion - Java", "login", new ArrayList<>(), null, "To be deleted");
                    RECORD_UID_TO_DELETE = SecretsManager.createSecret(optionsWithCache, TARGET_FOLDER_UID_FOR_TEST_RECORD, tempRecData);
                    System.out.println("✅ Temporary record created for deletion test. UID: " + RECORD_UID_TO_DELETE);
                }
            }

            if (!RECORD_UID_TO_DELETE.startsWith("[")) {
                System.out.println("🗑️ Attempting to delete record UID: " + RECORD_UID_TO_DELETE);
                SecretsManagerDeleteResponse deleteResponse = SecretsManager.deleteSecrets(optionsWithCache, List.of(RECORD_UID_TO_DELETE));
                
                boolean deletedSuccessfully = false;
                if (deleteResponse != null && deleteResponse.getResponses() != null && !deleteResponse.getResponses().isEmpty()) {
                    for (SecretsManagerDeleteResponse.DeleteResponseItem item : deleteResponse.getResponses()) {
                        if (RECORD_UID_TO_DELETE.equals(item.getRecordUid()) && "success".equalsIgnoreCase(item.getStatus())) {
                            System.out.println("✅ Record deleted successfully: " + item.getRecordUid());
                            deletedSuccessfully = true;
                            break;
                        }
                    }
                }
                if (!deletedSuccessfully) {
                     System.out.println("⚠️ Record deletion may have failed or record UID was not found in response.");
                }
                 // Verify deletion by trying to fetch it (should fail or return no record)
                try {
                    KeeperSecrets postDeleteSecrets = SecretsManager.getSecrets(optionsWithCache, List.of(RECORD_UID_TO_DELETE));
                    if (postDeleteSecrets.getRecords().isEmpty() || postDeleteSecrets.getRecordByUid(RECORD_UID_TO_DELETE) == null) {
                        System.out.println("✅ Verification: Record UID '" + RECORD_UID_TO_DELETE + "' no longer found after deletion attempt.");
                    } else {
                        System.out.println("⚠️ Verification: Record UID '" + RECORD_UID_TO_DELETE + "' still found after deletion attempt.");
                    }
                } catch (Exception eVerify) {
                    System.out.println("✅ Verification: Fetching deleted record UID '" + RECORD_UID_TO_DELETE + "' resulted in an error (expected). " + eVerify.getMessage());
                }
            } else {
                System.out.println("ℹ️ Skipping record deletion as no valid RECORD_UID_TO_DELETE was provided or created.");
            }

        } catch (Exception e) {
            System.err.println("❌ Error during advanced operations: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("\n🎉 Advanced operations demo complete.");
    }
}
```{{copy}}

### Configure Placeholders

-   In your Java file (e.g., `AdvancedOperationsDemo.java`):
    -   If your `ksm-config.json` isn't set up, replace `[ONE_TIME_TOKEN_IF_NEEDED]`.
    -   Replace `[RECORD_UID_FOR_DELETION_TEST]` with the UID of a record you are okay with deleting. If you leave the placeholder, the script will attempt to create and then delete a temporary record (ensure `[YOUR_SHARED_FOLDER_UID_HERE]` is also set for this). 
    -   Replace `[YOUR_SHARED_FOLDER_UID_HERE]` with a shared folder UID if you want the script to create a temporary record for deletion.

### Run the Demo

```bash
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.AdvancedOperationsDemo run --console=plain
```
`gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.AdvancedOperationsDemo run --console=plain`{{execute}}

### Expected Output:

The output will show caching behavior similar to before, followed by messages about record deletion attempts and verification.

```
... (caching output from before) ...

--- Record Deletion Example ---
🗑️ Attempting to delete record UID: YOUR_RECORD_UID_FOR_DELETION_TEST (or a temp UID)
✅ Record deleted successfully: YOUR_RECORD_UID_FOR_DELETION_TEST (or a temp UID)
✅ Verification: Record UID '...' no longer found after deletion attempt.
(or ✅ Verification: Fetching deleted record UID '...' resulted in an error (expected). ...)

🎉 Advanced operations demo complete.
```

## Understanding the Code

-   **Caching (`SecretsManagerOptions` constructor)**: 
    -   The `SecretsManagerOptions` constructor overload `SecretsManagerOptions(storage, queryFunction, allowUnverifiedCertificate, clientSideCacheRefreshIntervalSeconds)` is used.
    -   Setting `clientSideCacheRefreshIntervalSeconds` enables caching. Cached data is securely stored using the provided `storage`.
-   **Record Deletion (`SecretsManager.deleteSecrets(options, List<String> recordUids)`)**: 
    -   This method is used to delete one or more records.
    -   It takes a list of record UIDs to be deleted.
    -   The response (`SecretsManagerDeleteResponse`) contains a list of `DeleteResponseItem` objects, each indicating the status of the deletion for a specific UID.

## Conclusion

This step covered advanced KSM SDK features including caching for performance and secure record deletion. These tools help you build robust and efficient applications with Keeper Secrets Manager.

This concludes the KSM Java SDK tutorial! Refer to the `finish.md` tab for a summary and next steps.

### Folder Operations

```
touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/KSMFolderOperations.java
```{{execute}}

#### Place this code in the created file:

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import java.util.List;
import java.util.Arrays;

public class KSMFolderOperations {

    public static void listFolders() {
        KeyValueStorage storage = new LocalConfigStorage("ksm-config.json");
        try {
            SecretsManagerOptions options = new SecretsManagerOptions(storage);
            
            // Get all folders
            List<KeeperFolder> folders = SecretsManager.getFolders(options);
            
            System.out.println("Found " + folders.size() + " folders:");
            for (KeeperFolder folder : folders) {
                System.out.println("Folder: " + folder.getName() + 
                                 " (UID: " + folder.getFolderUid() + ")" +
                                 (folder.getParentUid() != null ? 
                                  " Parent: " + folder.getParentUid() : ""));
            }
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }
    }

    public static void createFolder() {
        KeyValueStorage storage = new LocalConfigStorage("ksm-config.json");
        try {
            SecretsManagerOptions options = new SecretsManagerOptions(storage);
            
            // Specify parent folder
            CreateOptions createOpts = new CreateOptions(
                "[SHARED_FOLDER_UID]",  // Parent shared folder UID
                null                    // Optional subfolder UID
            );
            
            // Create the new folder
            String newFolderUid = SecretsManager.createFolder(
                options,
                createOpts,
                "My New Folder"  // Folder name
            );
            
            System.out.println("Created folder with UID: " + newFolderUid);
            
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }
    }

    public static void updateFolder() {
        KeyValueStorage storage = new LocalConfigStorage("ksm-config.json");
        try {
            SecretsManagerOptions options = new SecretsManagerOptions(storage);
            
            // Update folder name
            SecretsManager.updateFolder(
                options,
                "[FOLDER_UID]",        // Folder to update
                "Updated Folder Name"   // New name
            );
            
            System.out.println("Folder name updated successfully");
            
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }
    }

    public static void deleteFolder() {
        KeyValueStorage storage = new LocalConfigStorage("ksm-config.json");
        try {
            SecretsManagerOptions options = new SecretsManagerOptions(storage);
            
            // Delete folders
            SecretsManagerDeleteResponse response = SecretsManager.deleteFolder(
                options,
                Arrays.asList("[FOLDER_UID]"),  // List of folder UIDs to delete
                true                            // Force deletion if not empty
            );
            
            System.out.println("Folder deletion completed");
            
        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        if (args.length == 0) {
            listFolders();
            return;
        }
        
        switch (args[0]) {
            case "create": createFolder(); break;
            case "update": updateFolder(); break;
            case "delete": deleteFolder(); break;
            default: listFolders();
        }
    }
}
```{{copy}}

### 2. Modify the Code
Replace the following placeholders in the code:

- [SHARED_FOLDER_UID] - UID of the parent shared folder
- [FOLDER_UID] - UID of the folder to update/delete

### 3. List All Folders

Run the code to list existing folders:

```
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.KSMFolderOperations run
```{{execute}}

### 4. Create a New Folder

Run the code to create a new folder:

```
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.KSMFolderOperations run --args="create"
```{{execute}}

### 5. Update Folder Name

Run the code to update a folder's name:

```
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.KSMFolderOperations run --args="update"
```{{execute}}