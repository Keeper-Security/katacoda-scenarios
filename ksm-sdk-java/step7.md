# Step 7: GraphSync™ Record Linking - Relationships Between Records

This step introduces GraphSync™, Keeper's record linking feature that enables you to establish and traverse relationships between records using a Directed Acyclic Graph (DAG) structure.

## Overview

GraphSync™ allows you to:
- Map dependencies between records
- Track PAM machine-user relationships
- Build credential dependency graphs
- Manage complex infrastructure relationships

## 1. Create the GraphSync™ Demo Class

Create a new Java class to explore GraphSync™ functionality:

`touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/GraphSyncDemo.java`{{execute}}

## 2. Add the GraphSync™ Demo Code

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import static com.keepersecurity.secretsManager.core.SecretsManager.*;
import java.util.*;
import java.util.stream.Collectors;

public class GraphSyncDemo {
    
    private static final String CONFIG_FILE_NAME = "ksm-config.json";
    
    public static void main(String[] args) {
        System.out.println("🔗 GraphSync™ Record Linking Demo");
        System.out.println("==================================\n");
        
        LocalConfigStorage storage = new LocalConfigStorage(CONFIG_FILE_NAME);
        SecretsManagerOptions options = null;
        
        try {
            options = new SecretsManagerOptions(storage);
            
            // CRITICAL: Must request links to access GraphSync™ data
            System.out.println("Step 1: Retrieving records WITH link relationships...");
            System.out.println("⚠️  Note: requestLinks must be true to access GraphSync™ data\n");
            
            QueryOptions queryOptions = new QueryOptions(
                Collections.emptyList(),  // recordsFilter - empty for all records
                Collections.emptyList(),  // foldersFilter - empty for all folders  
                true                      // requestLinks - MUST be true for GraphSync™
            );
            
            KeeperSecrets secrets = getSecrets2(options, queryOptions);
            System.out.println("✅ Retrieved " + secrets.getRecords().size() + " records with link data\n");
            
            // Step 2: Analyze link relationships
            System.out.println("Step 2: Analyzing record relationships...\n");
            
            // Build maps for analysis
            Map<String, List<String>> linkMap = new HashMap<>();
            Map<String, String> recordTitles = new HashMap<>();
            Map<String, String> recordTypes = new HashMap<>();
            int totalLinks = 0;
            
            for (KeeperRecord record : secrets.getRecords()) {
                recordTitles.put(record.getRecordUid(), record.getTitle());
                recordTypes.put(record.getRecordUid(), record.getType());
                
                List<KeeperRecordLink> links = record.getLinks();
                
                // Important: links is null when requestLinks=false, empty list when true but no links
                if (links == null) {
                    System.err.println("⚠️  WARNING: Links are null for record " + record.getTitle());
                    System.err.println("   This means requestLinks was false in QueryOptions");
                } else if (!links.isEmpty()) {
                    List<String> linkedUids = new ArrayList<>();
                    
                    System.out.println("📌 " + record.getTitle() + " [" + record.getType() + "]");
                    System.out.println("   UID: " + record.getRecordUid());
                    System.out.println("   Links: " + links.size());
                    
                    for (KeeperRecordLink link : links) {
                        linkedUids.add(link.getRecordUid());
                        totalLinks++;
                        
                        // Display link details
                        System.out.println("   → Target: " + link.getRecordUid());
                        
                        // Check link metadata type (path)
                        String linkPath = link.getPath();
                        if (linkPath != null) {
                            System.out.println("     Type: " + linkPath);
                        }
                        
                        // Check link properties
                        if (link.isAdminUser()) {
                            System.out.println("     🔑 Admin user");
                        }
                        if (link.isLaunchCredential()) {
                            System.out.println("     🚀 Launch credential");
                        }
                        if (link.allowsRotation()) {
                            System.out.println("     🔄 Allows rotation");
                        }
                        if (link.allowsConnections()) {
                            System.out.println("     🔌 Allows connections");
                        }
                        if (link.allowsSessionRecording()) {
                            System.out.println("     📹 Session recording enabled");
                        }
                        
                        // Check for encrypted data
                        if (link.hasEncryptedData()) {
                            System.out.println("     🔒 Has encrypted metadata");
                            
                            // Try to decrypt if it's a known type
                            if ("ai_settings".equals(linkPath) || "jit_settings".equals(linkPath)) {
                                Map<String, Object> linkData = link.getLinkData(record.getRecordKey());
                                if (linkData != null) {
                                    System.out.println("     📦 Decrypted data keys: " + linkData.keySet());
                                }
                            }
                        }
                    }
                    
                    linkMap.put(record.getRecordUid(), linkedUids);
                    System.out.println();
                }
            }
            
            // Step 3: GraphSync™ Analysis
            System.out.println("Step 3: GraphSync™ Analysis Summary");
            System.out.println("====================================");
            System.out.println("📊 Total records: " + secrets.getRecords().size());
            System.out.println("🔗 Records with outgoing links: " + linkMap.size());
            System.out.println("➡️  Total links: " + totalLinks);
            
            // Find records that are link targets
            Set<String> targetRecords = new HashSet<>();
            for (List<String> links : linkMap.values()) {
                targetRecords.addAll(links);
            }
            System.out.println("🎯 Records that are link targets: " + targetRecords.size());
            
            // Step 4: Find PAM relationships
            System.out.println("\nStep 4: PAM Machine-User Relationships");
            System.out.println("=======================================");
            
            boolean foundPAM = false;
            for (KeeperRecord record : secrets.getRecords()) {
                if ("pamMachine".equals(record.getType())) {
                    foundPAM = true;
                    System.out.println("\n🖥️  PAM Machine: " + record.getTitle());
                    
                    List<KeeperRecordLink> links = record.getLinks();
                    if (links != null && !links.isEmpty()) {
                        List<String> adminUsers = new ArrayList<>();
                        List<String> standardUsers = new ArrayList<>();
                        
                        for (KeeperRecordLink link : links) {
                            // Find the linked record details
                            String linkedTitle = recordTitles.get(link.getRecordUid());
                            String linkedType = recordTypes.get(link.getRecordUid());
                            
                            if ("pamUser".equals(linkedType)) {
                                if (link.isAdminUser()) {
                                    adminUsers.add(linkedTitle != null ? linkedTitle : link.getRecordUid());
                                } else {
                                    standardUsers.add(linkedTitle != null ? linkedTitle : link.getRecordUid());
                                }
                            }
                        }
                        
                        if (!adminUsers.isEmpty()) {
                            System.out.println("   🔑 Admin Users: " + String.join(", ", adminUsers));
                        }
                        if (!standardUsers.isEmpty()) {
                            System.out.println("   👤 Standard Users: " + String.join(", ", standardUsers));
                        }
                    } else {
                        System.out.println("   No users linked to this machine");
                    }
                }
            }
            
            if (!foundPAM) {
                System.out.println("No PAM machines found in this vault");
            }
            
            // Step 5: Build dependency graph
            System.out.println("\nStep 5: Dependency Graph");
            System.out.println("=========================");
            
            if (!linkMap.isEmpty()) {
                // Find records with most dependencies
                System.out.println("\n📈 Records with most outgoing links:");
                linkMap.entrySet().stream()
                    .sorted((e1, e2) -> Integer.compare(e2.getValue().size(), e1.getValue().size()))
                    .limit(3)
                    .forEach(entry -> {
                        String title = recordTitles.get(entry.getKey());
                        System.out.println("   " + title + " → " + entry.getValue().size() + " records");
                    });
                
                // Find most depended-upon records
                Map<String, Integer> incomingLinks = new HashMap<>();
                for (List<String> links : linkMap.values()) {
                    for (String targetUid : links) {
                        incomingLinks.merge(targetUid, 1, Integer::sum);
                    }
                }
                
                if (!incomingLinks.isEmpty()) {
                    System.out.println("\n🎯 Most critical records (most incoming links):");
                    incomingLinks.entrySet().stream()
                        .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                        .limit(3)
                        .forEach(entry -> {
                            String title = recordTitles.get(entry.getKey());
                            if (title != null) {
                                System.out.println("   " + title + " ← " + entry.getValue() + " records");
                            }
                        });
                }
            } else {
                System.out.println("No link relationships found in this vault");
            }
            
            // Final summary
            System.out.println("\n✅ GraphSync™ Demo Complete!");
            System.out.println("\nKey Takeaways:");
            System.out.println("• Use QueryOptions with requestLinks=true to access GraphSync™");
            System.out.println("• Links are null when not requested, empty list when requested but no links");
            System.out.println("• Link properties indicate permissions and capabilities");
            System.out.println("• Encrypted link data can be decrypted with record key");
            System.out.println("• GraphSync™ enforces DAG structure (no circular dependencies)");
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```{{copy}}

## 3. Run the GraphSync™ Demo

Execute the demo to explore record relationships:

`gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.GraphSyncDemo run --console=plain`{{execute}}

### Expected Output

The output will vary based on your vault content, but should show:

```
🔗 GraphSync™ Record Linking Demo
==================================

Step 1: Retrieving records WITH link relationships...
✅ Retrieved [number] records with link data

Step 2: Analyzing record relationships...

📌 [Record Name] [Record Type]
   UID: [Record UID]
   Links: [number]
   → Target: [Target UID]
     Type: [Link Type]
     🔑 Admin user
     🔄 Allows rotation

Step 3: GraphSync™ Analysis Summary
====================================
📊 Total records: [number]
🔗 Records with outgoing links: [number]
➡️  Total links: [number]
🎯 Records that are link targets: [number]

Step 4: PAM Machine-User Relationships
=======================================
[PAM relationship details if any]

Step 5: Dependency Graph
=========================
[Dependency analysis]

✅ GraphSync™ Demo Complete!
```

## Understanding GraphSync™

### Key Concepts

1. **QueryOptions with requestLinks**
   - Must be `true` to access GraphSync™ data
   - Without it, `record.getLinks()` returns `null`

2. **Link Properties**
   - `isAdminUser()` - Check admin privileges
   - `allowsRotation()` - Password rotation permission
   - `allowsConnections()` - Connection permission
   - `getPath()` - Link metadata type

3. **Encrypted Link Data**
   - Some links contain encrypted metadata
   - Use `getLinkData(recordKey)` to decrypt
   - Common types: `ai_settings`, `jit_settings`

### Common Patterns

#### Finding Specific Relationships

```java
// Find all records linking to a specific target
public List<String> findRecordsLinkingTo(String targetUid, KeeperSecrets secrets) {
    List<String> results = new ArrayList<>();
    
    for (KeeperRecord record : secrets.getRecords()) {
        List<KeeperRecordLink> links = record.getLinks();
        if (links != null) {
            for (KeeperRecordLink link : links) {
                if (link.getRecordUid().equals(targetUid)) {
                    results.add(record.getRecordUid());
                    break;
                }
            }
        }
    }
    
    return results;
}
```

#### Building Quick Lookup Maps

```java
// Build bidirectional relationship maps for efficient queries
Map<String, Set<String>> forwardLinks = new HashMap<>();  // Who I link to
Map<String, Set<String>> reverseLinks = new HashMap<>();  // Who links to me

for (KeeperRecord record : secrets.getRecords()) {
    List<KeeperRecordLink> links = record.getLinks();
    if (links != null && !links.isEmpty()) {
        Set<String> targets = new HashSet<>();
        for (KeeperRecordLink link : links) {
            targets.add(link.getRecordUid());
            reverseLinks.computeIfAbsent(link.getRecordUid(), k -> new HashSet<>())
                       .add(record.getRecordUid());
        }
        forwardLinks.put(record.getRecordUid(), targets);
    }
}
```

## Performance Tips

1. **Only request links when needed** - Adds overhead to API calls
2. **Cache results** - Don't repeatedly fetch the same data
3. **Filter records** - Use QueryOptions to retrieve only needed records
4. **Build lookup maps** - Create efficient data structures for complex queries

## Next Steps

You've now learned both major new features:
- **File Removal** (Step 6) - Programmatic file management
- **GraphSync™** (Step 7) - Record relationship management

These features enable sophisticated automation scenarios for managing complex credential infrastructures in your Keeper Vault.