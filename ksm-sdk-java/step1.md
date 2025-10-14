# Step 1: Setup & Basic Connection

This step guides you through setting up a new Gradle project, adding the Keeper Secrets Manager (KSM) Java SDK, and writing your first application to connect to Keeper and list shared secrets.

## 1. Initialize Gradle Project

First, create a new Java application project structure manually. This approach works with all Gradle versions.

```bash
# Create project directory and navigate into it
mkdir ksmsdk-java-tutorial && cd ksmsdk-java-tutorial

# Create the necessary directory structure
mkdir -p src/main/java/com/keepersecurity/ksmsdk/javatutorial
mkdir -p src/test/java/com/keepersecurity/ksmsdk/javatutorial
```
`mkdir ksmsdk-java-tutorial && cd ksmsdk-java-tutorial && mkdir -p src/main/java/com/keepersecurity/ksmsdk/javatutorial src/test/java/com/keepersecurity/ksmsdk/javatutorial`{{execute}}

This creates a new directory `ksmsdk-java-tutorial` with the standard Gradle Java project structure.

## 2. Create Gradle Configuration Files

### Create `build.gradle`

Create a `build.gradle` file in the project root with the KSM Java SDK dependency:

```bash
cat > build.gradle << 'EOF'
plugins {
    id 'java'
    id 'application'
}

repositories {
    mavenCentral()
}

dependencies {
    // Use the latest version of the Keeper Secrets Manager SDK for Java
    implementation 'com.keepersecurity.secrets-manager:core:+' // '+' fetches the latest version
}

application {
    // Define the main class for the application.
    // This will be set dynamically when running specific examples.
    mainClass = project.hasProperty("mainClass") ? project.getProperty("mainClass") : "com.keepersecurity.ksmsdk.javatutorial.ListAllSecrets"
}

// Ensure UTF-8 encoding for cross-platform compatibility
compileJava {
    options.encoding = 'UTF-8'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}
EOF
```
`cat > build.gradle << 'EOF'
plugins {
    id 'java'
    id 'application'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.keepersecurity.secrets-manager:core:+'
}

application {
    mainClass = project.hasProperty("mainClass") ? project.getProperty("mainClass") : "com.keepersecurity.ksmsdk.javatutorial.ListAllSecrets"
}

compileJava {
    options.encoding = 'UTF-8'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}
EOF`{{execute}}

### Create `settings.gradle`

Also create a `settings.gradle` file to define the project name:

```bash
cat > settings.gradle << 'EOF'
rootProject.name = 'ksmsdk-java-tutorial'
EOF
```
`cat > settings.gradle << 'EOF'
rootProject.name = 'ksmsdk-java-tutorial'
EOF`{{execute}}

### Verify Project Structure

Your project structure should now look like this:

```
ksmsdk-java-tutorial/
├── build.gradle
├── settings.gradle
└── src/
    ├── main/
    │   └── java/
    │       └── com/
    │           └── keepersecurity/
    │               └── ksmsdk/
    │                   └── javatutorial/
    └── test/
        └── java/
            └── com/
                └── keepersecurity/
                    └── ksmsdk/
                        └── javatutorial/
```

## 3. Create Your First KSM Application: List All Secrets

Let's create a Java class to connect to KSM and list all secrets shared with your application.

### Create the Java File

Ensure you are in the `ksmsdk-java-tutorial` directory.

```bash
mkdir -p src/main/java/com/keepersecurity/ksmsdk/javatutorial
touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/ListAllSecrets.java
```
`mkdir -p src/main/java/com/keepersecurity/ksmsdk/javatutorial && touch src/main/java/com/keepersecurity/ksmsdk/javatutorial/ListAllSecrets.java`{{execute}}

### Add the Java Code

Paste the following code into `src/main/java/com/keepersecurity/ksmsdk/javatutorial/ListAllSecrets.java`:

```java
package com.keepersecurity.ksmsdk.javatutorial;

import com.keepersecurity.secretsManager.core.*;
import static com.keepersecurity.secretsManager.core.SecretsManager.initializeStorage;
import java.util.List;

public class ListAllSecrets {

    // ⚠️ IMPORTANT: Replace with your actual One-Time Token from Keeper Vault
    private static final String ONE_TIME_TOKEN = "[ONE_TIME_TOKEN_HERE]";
    private static final String CONFIG_FILE_NAME = "ksm-config.json";

    public static void main(String[] args) {
        System.out.println("🚀 Attempting to connect to Keeper and list secrets...");

        // Use LocalConfigStorage for storing KSM configuration locally
        LocalConfigStorage storage = new LocalConfigStorage(CONFIG_FILE_NAME);

        try {
            // Initialize storage with the One-Time Token (only needed for the first run)
            // Subsequent runs will use the generated ksm-config.json
            System.out.println("🔑 Initializing KSM storage with token (if first run)...");
            initializeStorage(storage, ONE_TIME_TOKEN);
            System.out.println("💾 Storage initialized. Using config: " + CONFIG_FILE_NAME);

            // Set up options for the SecretsManager client
            SecretsManagerOptions options = new SecretsManagerOptions(storage);

            // Retrieve all secrets shared with this application
            System.out.println("📡 Fetching all secrets...");
            KeeperSecrets secrets = SecretsManager.getSecrets(options);

            List<KeeperRecord> records = secrets.getRecords();
            System.out.println("✅ Successfully fetched " + records.size() + " record(s):");

            if (records.isEmpty()) {
                System.out.println("\nℹ️ No records found. Ensure records are shared with your KSM application in the Keeper Vault.");
            } else {
                System.out.println("\n--- All Shared Records ---");
                for (int i = 0; i < records.size(); i++) {
                    KeeperRecord record = records.get(i);
                    System.out.printf("[%d] Record UID: %s%n", i + 1, record.getRecordUid());
                    System.out.printf("    Title: %s%n", record.getTitle());
                    System.out.printf("    Type: %s%n", record.getType());
                    System.out.printf("    Fields Count: %d%n", record.getData().getFields().size());
                    if (record.getFiles() != null) {
                        System.out.printf("    Files Count: %d%n", record.getFiles().size());
                    }
                    System.out.println("---");
                }
            }

        } catch (Exception e) {
            System.err.println("❌ Error communicating with Keeper Secrets Manager: " + e.getMessage());
            e.printStackTrace();
            System.err.println("\n💡 Troubleshooting Tips:");
            System.err.println("- Ensure your ONE_TIME_TOKEN is correct and has not been used before.");
            System.err.println("- Check network connectivity to Keeper servers.");
            System.err.println("- Verify that records are shared with the KSM application in your Keeper Vault.");
        }
    }
}
```{{copy}}

## 4. Configure Your One-Time Token

-   In the `ListAllSecrets.java` file, **replace `[ONE_TIME_TOKEN_HERE]`** with a valid One-Time Token obtained from your Keeper Vault.
    -   To get a token: Log into Keeper Web Vault -> Secrets Manager -> Applications -> Select/Create Application -> Devices -> Add Device -> Method: One-Time Token.

## 5. Run the Application

Execute the Java application using Gradle. This command compiles and runs your `ListAllSecrets` class.

```bash
gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.ListAllSecrets run --console=plain
```
`gradle -PmainClass=com.keepersecurity.ksmsdk.javatutorial.ListAllSecrets run --console=plain`{{execute}}

### Expected Output:

You should see a list of your shared secrets' UIDs, titles, types, and field/file counts, or an appropriate error message if issues occur.

```
🚀 Attempting to connect to Keeper and list secrets...
🔑 Initializing KSM storage with token (if first run)...
💾 Storage initialized. Using config: ksm-config.json
📡 Fetching all secrets...
✅ Successfully fetched X record(s):

--- All Shared Records ---
[1] Record UID: abcXYZ123...
    Title: My Sample Login
    Type: login
    Fields Count: 2
    Files Count: 1
---
...
```

## Understanding the Code

-   **`LocalConfigStorage`**: Manages the local `ksm-config.json` file, which stores encrypted application keys and connection details after the first successful token-based initialization.
-   **`initializeStorage(storage, ONE_TIME_TOKEN)`**: This is crucial for the first run. It uses the One-Time Token to securely establish a persistent configuration in `ksm-config.json`.
-   **`SecretsManagerOptions`**: Used to configure the KSM client, primarily by providing the storage mechanism.
-   **`SecretsManager.getSecrets(options)`**: Fetches all records and associated data (like files, folders) shared with the KSM application defined by the configuration.
-   **`KeeperSecrets` & `KeeperRecord`**: These classes hold the retrieved secret data. `record.getTitle()`, `record.getType()`, `record.getData().getFields()`, and `record.getFiles()` are used to access specific details.

## Troubleshooting

-   **Token Already Used**: Ensure your One-Time Token is fresh. They are single-use.
-   **No Records Found**: Verify in your Keeper Vault that records are shared with the KSM application whose token you are using.
-   **Network Issues**: Check your internet connection and any firewall rules that might block access to Keeper servers.
-   **Gradle Build Errors**: Ensure `build.gradle` is correctly configured and all dependencies are resolved. Try `gradle clean build --refresh-dependencies`.

In the next step, we'll explore how to retrieve specific secrets and their fields.
