# Killercoda Syntax Reference Guide

**Version**: 1.0
**Last Updated**: 2025-10-14
**Purpose**: Comprehensive reference for Killercoda/Katacoda markdown syntax and configuration

## Table of Contents

1. [Markdown Execute Syntax](#1-markdown-execute-syntax)
2. [Copy to Clipboard Syntax](#2-copy-to-clipboard-syntax)
3. [Advanced Execute Options](#3-advanced-execute-options)
4. [Index.json Structure](#4-indexjson-structure)
5. [File Structure](#5-file-structure)
6. [Grafana Transformer Directives](#6-grafana-transformer-directives)
7. [Default Behaviors](#7-default-behaviors)
8. [Special Markdown Features](#8-special-markdown-features)
9. [Course Structure](#9-course-structure)
10. [Common Patterns](#10-common-patterns-in-our-repo)
11. [Best Practices](#11-best-practices)
12. [Debugging Tips](#12-debugging-tips)

---

## 1. Markdown Execute Syntax

### Single-line Commands

```markdown
`command here`{{execute}}
```

**Example:**
```markdown
`echo "Hello World"`{{execute}}
`ls -la`{{execute}}
`cd /home/user`{{execute}}
```

### Multi-line Commands

**⚠️ CRITICAL**: Multi-line commands MUST use fenced code blocks (triple backticks), NOT inline backticks!

```markdown
```
command line 1
command line 2
command line 3
```{{execute}}
```

**Example:**
```markdown
```
echo "Line 1"
echo "Line 2"
echo "Line 3"
```{{execute}}
```

### Heredoc Commands (Specific Pattern)

**For creating files with cat and heredoc:**

```markdown
```
cat > filename << 'EOF'
content line 1
content line 2
content line 3
EOF
```{{execute}}
```

**Real Example:**
```markdown
```
cat > build.gradle << 'EOF'
plugins {
    id 'java'
    id 'application'
}

repositories {
    mavenCentral()
}
EOF
```{{execute}}
```

**Common Mistake** ❌:
```markdown
`cat > file << 'EOF'
multi-line content
EOF`{{execute}}
```
This will NOT work! Heredoc requires fenced code blocks.

---

## 2. Copy to Clipboard Syntax

### Single-line Copy

```markdown
`command to copy`{{copy}}
```

**Example:**
```markdown
`npm install keeper-secrets-manager-core`{{copy}}
```

### Multi-line Copy

```markdown
```language
code to copy
multiple lines
```{{copy}}
```

**Example:**
```markdown
```java
public class Example {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
```{{copy}}
```

---

## 3. Advanced Execute Options

### Interrupt Running Commands

Sends Ctrl+C before executing the command:

```markdown
`command`{{execute interrupt}}
```

**Use case**: Stop a long-running process before starting a new one.

### Control Sequences

```markdown
`^C`{{execute ctrl-seq}}      # Sends Ctrl+C
`^ESC`{{execute ctrl-seq}}    # Sends Ctrl+Escape
`i`{{execute no-newline}}     # Sends keystroke without newline
```

### Target Specific Terminals

For scenarios with multiple terminal windows:

```markdown
`command`{{execute T2}}       # Execute in Terminal 2
`command`{{execute T3}}       # Execute in Terminal 3
`command`{{execute T4}}       # Execute in Terminal 4
```

**Default**: Commands without terminal specification run in Terminal 1 (T1).

### Target Specific Hosts

For multi-host scenarios:

```markdown
`command`{{execute HOST1}}    # Execute on Host 1
`command`{{execute HOST2}}    # Execute on Host 2
```

---

## 4. Index.json Structure

### Complete Schema

```json
{
  "title": "Scenario Title",
  "description": "Scenario description text",

  "noindex": true,                    // Optional: exclude from search engines
  "time": "20-25 minutes",            // Optional: estimated completion time
  "difficulty": "Beginner",           // Optional: Beginner|Intermediate|Advanced

  "details": {
    "intro": {
      "text": "intro.md",
      "credits": "Author Name",       // Optional: author attribution
      "code": "setup-script.sh"       // Optional: foreground setup script
    },
    "steps": [
      {
        "title": "Step 1: Title Here",
        "text": "step1.md"
      },
      {
        "title": "Step 2: Another Title",
        "text": "step2.md"
      }
    ],
    "finish": {
      "text": "finish.md"
    }
  },

  "environment": {
    "uilayout": "terminal",            // Options: terminal, editor-terminal
    "hideintro": false,               // true = skip intro page
    "hidefinish": false,              // true = skip finish page
    "showdashboard": true             // Show dashboard interface
  },

  "backend": {
    "imageid": "ubuntu"               // See available images below
  },

  "interface": {
    "layout": "ide"                   // Optional: use Theia IDE interface
  }
}
```

### Available Backend Images

| Image ID | Description |
|----------|-------------|
| `ubuntu` | Ubuntu 20.04 with Docker and Podman pre-installed |
| `python` | Python environment |
| `kubernetes-kubeadm-1node` | Kubernetes cluster with 1 node (faster loading) |
| `kubernetes-kubeadm-2nodes` | Kubernetes cluster with 2 nodes |

**Recommendation**: Use `kubernetes-kubeadm-1node` when possible for faster loading times.

### Environment Configuration Notes

- **Legacy**: `environment.uilayout` is deprecated in newer Killercoda versions
- **Modern**: Use `interface.layout = "ide"` for Theia IDE integration
- If both are present, `interface.layout` takes precedence

---

## 5. File Structure

### Standard Scenario Structure

```
scenario-directory/
├── index.json              # Required: scenario configuration
├── intro.md               # Optional: introduction page
├── step1.md              # Required: at least one step file
├── step2.md              # Optional: additional step files
├── step3.md              # Optional: more steps as needed
├── finish.md             # Optional: conclusion/summary page
├── setup-script.sh       # Optional: environment setup script
└── assets/               # Optional: images, files, etc.
```

### Course Structure (Multiple Scenarios)

```
course-directory/
├── structure.json         # Required for course organization
├── scenario1/
│   ├── index.json
│   ├── step1.md
│   └── ...
├── scenario2/
│   ├── index.json
│   ├── step1.md
│   └── ...
└── ...
```

---

## 6. Grafana Transformer Directives

These directives control how content is transformed from regular documentation into Killercoda tutorials.

### Interactive Copy Directive

```markdown
<!-- INTERACTIVE copy START -->
```bash
echo "This code will be copyable"
ls -la
```
<!-- INTERACTIVE copy END -->
```

### Interactive Exec Directive

```markdown
<!-- INTERACTIVE exec START -->
```bash
echo "This code will be executable"
npm install
```
<!-- INTERACTIVE exec END -->
```

### Ignore Directive

Content between these directives will NOT be included in the Killercoda tutorial:

```markdown
<!-- INTERACTIVE ignore START -->
This content is only for the original documentation.
It will be excluded from Killercoda.
<!-- INTERACTIVE ignore END -->
```

### Page Directive

Specify which content belongs to which step:

```markdown
<!-- INTERACTIVE page step1.md START -->
Content for step 1
<!-- INTERACTIVE page step1.md END -->

<!-- INTERACTIVE page step2.md START -->
Content for step 2
<!-- INTERACTIVE page step2.md END -->
```

---

## 7. Default Behaviors

**⚠️ IMPORTANT AUTOMATIC BEHAVIORS**:

1. **Bash code blocks** are **executable by default** (unless overridden with directives)
2. **Non-bash code blocks** are **copyable by default** (unless overridden with directives)

### Examples

**Automatically Executable** (no {{execute}} needed in some contexts):
```markdown
```bash
echo "This might auto-execute"
```
```

**Automatically Copyable**:
```markdown
```java
// This is automatically copyable
public class Example {}
```
```

**Explicit Control** (Recommended):
```markdown
```bash
echo "Explicitly executable"
```{{execute}}

```java
// Explicitly copyable
```{{copy}}
```

---

## 8. Special Markdown Features

### Code Block Language Specification

Always specify the language for proper syntax highlighting:

```markdown
```java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
```{{copy}}

```bash
#!/bin/bash
echo "Bash script"
```{{execute}}

```python
def hello():
    print("Hello World")
```{{copy}}

```json
{
  "key": "value"
}
```{{copy}}
```

### Supported Languages

- `bash` / `sh`
- `java`
- `python`
- `javascript` / `js`
- `json`
- `yaml` / `yml`
- `xml`
- `sql`
- `go`
- `rust`
- `dockerfile`
- And more...

---

## 9. Course Structure

### structure.json Format

Organize multiple scenarios into a structured course:

```json
{
  "items": [
    {
      "title": "Module 1: Getting Started",
      "items": [
        "intro-scenario",
        "basic-setup"
      ]
    },
    {
      "title": "Module 2: Advanced Topics",
      "items": [
        "advanced-config",
        "production-deployment"
      ]
    }
  ]
}
```

**Important**: Once `structure.json` exists, ONLY scenarios listed in it will be visible. Any scenario not in the structure file will be ignored.

---

## 10. Common Patterns in Our Repo

### Pattern: Creating Files with Heredoc

```markdown
```
cat > build.gradle << 'EOF'
plugins {
    id 'java'
    id 'application'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.keepersecurity:secrets-manager:+'
}
EOF
```{{execute}}
```

### Pattern: Single Directory Creation Command

```markdown
`mkdir -p src/main/java/com/keepersecurity/ksmsdk/javatutorial`{{execute}}
```

### Pattern: Chained Commands

```markdown
`cd project-dir && gradle build && java -jar app.jar`{{execute}}
```

### Pattern: Copy Java Class

```markdown
```java
package com.keepersecurity.example;

import com.keepersecurity.secretsManager.core.*;

public class Example {
    public static void main(String[] args) {
        // Implementation here
    }
}
```{{copy}}
```

### Pattern: Execute Gradle Command

```markdown
`gradle -PmainClass=com.keepersecurity.Example run --console=plain`{{execute}}
```

### Pattern: Create and Verify File

```markdown
`echo "Sample content" > test.txt && cat test.txt`{{execute}}
```

---

## 11. Best Practices

### ✅ DO

1. **Use fenced code blocks for multi-line commands**
   ```markdown
   ```
   line 1
   line 2
   ```{{execute}}
   ```

2. **Test all {{execute}} commands in actual Killercoda environment**
   - Commands that work in local terminal may not work in Killercoda
   - Interactive prompts won't work

3. **Use proper language tags**
   ```markdown
   ```bash
   # for bash scripts
   ```

   ```java
   // for java code
   ```
   ```

4. **Keep commands simple and focused**
   - One logical action per execute block
   - Break complex operations into steps

5. **Provide expected outputs**
   ```markdown
   **Expected Output:**
   ```
   Hello World
   ```
   ```

6. **Include verification steps**
   ```markdown
   Verify the file was created:
   `ls -la filename.txt`{{execute}}
   ```

7. **Test in Docker containers matching the imageid**
   ```bash
   docker run --rm -it ubuntu:20.04 bash
   # Test your commands here
   ```

### ❌ DON'T

1. **Use inline backticks for multi-line commands**
   ```markdown
   ❌ `command 1
   command 2`{{execute}}
   ```

2. **Mix different command types in one block**
   ```markdown
   ❌ Don't mix file creation and execution in one block
   ```

3. **Assume all bash features work**
   - Some interactive features may not work
   - Complex bash expansions may fail

4. **Use interactive prompts**
   ```markdown
   ❌ `read -p "Enter value: " VAR`{{execute}}
   # This won't work - no user input possible
   ```

5. **Forget to test heredoc syntax**
   ```markdown
   ❌ `cat > file <<EOF
   content
   EOF`{{execute}}
   # This is wrong - use fenced blocks!
   ```

6. **Use relative paths without context**
   ```markdown
   ✅ Better: Show the full context
   `cd /home/ubuntu/project && ./script.sh`{{execute}}
   ```

---

## 12. Debugging Tips

### Issue: {{execute}} Button Not Working

**Possible Causes:**
1. Multi-line command using inline backticks instead of fenced code blocks
2. Syntax error in the command
3. Missing closing backtick or brace

**Solution:**
```markdown
# Wrong
`multi
line`{{execute}}

# Correct
```
multi
line
```{{execute}}
```

### Issue: Heredoc Not Creating File

**Possible Causes:**
1. Using inline backticks instead of fenced code blocks
2. EOF delimiter mismatch
3. Quote issues with 'EOF' vs EOF

**Solution:**
```markdown
```
cat > filename << 'EOF'
content here
EOF
```{{execute}}
```

**Key**: Use `'EOF'` (with quotes) to prevent variable expansion.

### Issue: Copy Button Not Appearing

**Possible Causes:**
1. Missing language specification
2. Incorrect {{copy}} syntax
3. Code block not properly closed

**Solution:**
```markdown
```java
// Code here
```{{copy}}
```

### Issue: Command Executes in Wrong Terminal

**Solution**: Explicitly specify terminal:
```markdown
`command`{{execute T2}}  # Force Terminal 2
```

### Testing Strategy

1. **Test locally first** in Docker container:
   ```bash
   docker run --rm -it ubuntu:20.04 bash
   # Run your commands
   ```

2. **Test heredoc syntax**:
   ```bash
   cat > test.txt << 'EOF'
   line 1
   line 2
   EOF
   cat test.txt
   ```

3. **Verify file permissions**:
   ```bash
   ls -la created-file.sh
   chmod +x created-file.sh  # If needed
   ```

4. **Check command exit codes**:
   ```bash
   command && echo "Success" || echo "Failed"
   ```

---

## Quick Reference Card

### Execute Patterns

| Pattern | Syntax |
|---------|--------|
| Single line | `` `command`{{execute}} `` |
| Multi-line | ` ```\nlines\n```{{execute}} ` |
| Heredoc | ` ```\ncat > file << 'EOF'\nlines\nEOF\n```{{execute}} ` |
| Interrupt | `` `command`{{execute interrupt}} `` |
| Terminal 2 | `` `command`{{execute T2}} `` |
| Host 2 | `` `command`{{execute HOST2}} `` |

### Copy Patterns

| Pattern | Syntax |
|---------|--------|
| Single line | `` `code`{{copy}} `` |
| Code block | ` ```lang\ncode\n```{{copy}} ` |

### Common Commands

```bash
# Directory creation
mkdir -p path/to/dir && cd path/to/dir

# File creation
touch filename.ext

# File with content
echo "content" > filename.txt

# Heredoc file creation
cat > file << 'EOF'
content
EOF

# Verify file
cat filename.txt

# Run gradle
gradle run --console=plain
```

---

## Resources

- **Official Killercoda Creators**: https://killercoda.com/creators
- **Scenario Examples**: https://github.com/killercoda/scenario-examples
- **Katacoda Examples**: https://github.com/katacoda/scenario-examples
- **Migration Guide**: Katacoda to Killercoda migration documentation

---

## Version History

- **1.0** (2025-10-14): Initial comprehensive documentation
  - All markdown syntax patterns
  - index.json complete schema
  - Best practices and debugging tips
  - Common patterns from our repository

---

**Maintained by**: Keeper Security Team
**For**: Internal tutorial development