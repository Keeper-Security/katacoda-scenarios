# Claude AI Tutorial Guidelines

This document provides comprehensive guidelines for creating high-quality Keeper Secrets Manager (KSM) tutorials using Claude AI assistance.

## Table of Contents

- [Available KSM Tutorials](#available-ksm-tutorials)
- [Killercoda Syntax Reference](#killercoda-syntax-reference)
- [Security & Safety Guidelines](#security--safety-guidelines)
- [Tutorial Structure & Organization](#tutorial-structure--organization)
- [Code Quality Standards](#code-quality-standards)
- [User Experience Best Practices](#user-experience-best-practices)
- [Technical Implementation Guidelines](#technical-implementation-guidelines)
- [Testing & Validation Requirements](#testing--validation-requirements)
- [Documentation Standards](#documentation-standards)

## Available KSM Tutorials

This repository contains comprehensive, production-ready tutorials for Keeper Secrets Manager SDKs:

### **Ruby SDK** (`ksm-sdk-ruby/`)
**Status**: ✅ Complete (3,799 lines)
**Version**: SDK 17.1.0 | Ruby 3.2+
**Content**: 6 steps covering installation, CRUD operations, folders, files, and production patterns

**Tutorial Structure:**
- **Step 1**: Installation & First Connection (300 lines)
- **Step 2**: Reading Secrets & Fields (433 lines)
- **Step 3**: Creating & Updating Records (538 lines)
- **Step 4**: Folder Management (543 lines)
- **Step 5**: File Operations (637 lines)
- **Step 6**: Production Patterns & Best Practices (861 lines)

**Key Features:**
- 30+ complete, tested code examples
- Real-world integration patterns (Rails, Sidekiq, Rake, Docker)
- Production-ready error handling, caching, and logging
- Comprehensive security warnings throughout
- All code validated against actual SDK

**Technical Notes:**
- Uses Brightbox PPA for Ruby 3.2 on Ubuntu 22.04
- Gem: `keeper_secrets_manager` version 17.1.0
- Main classes: `KeeperSecretsManager`, `Storage::InMemoryStorage`, `Storage::FileStorage`
- Key methods: `get_secrets`, `create_secret`, `update_secret`, `create_folder`, `upload_file`, `download_file`

### **Python SDK** (`ksm-python-sdk/`)
**Status**: ✅ Complete
Comprehensive Python SDK tutorial with notebook patterns and async support.

### **CLI** (`ksm-cli/`)
**Status**: ✅ Complete
Command-line interface tutorial for quick secret retrieval and automation.

### **Java SDK** (`ksm-java-sdk/`)
**Status**: ✅ Complete
Enterprise Java patterns with Gradle/Maven integration.

---

## Killercoda Syntax Reference

**📚 CRITICAL**: Before creating or modifying any Killercoda tutorials, consult the comprehensive syntax reference:

**[docs/killercoda_syntax_reference.md](docs/killercoda_syntax_reference.md)**

This document contains:
- ✅ Complete markdown execute syntax (single-line, multi-line, heredoc)
- ✅ Copy to clipboard patterns
- ✅ Advanced execute options (terminals, hosts, interrupts)
- ✅ Complete index.json schema with all available options
- ✅ File structure guidelines
- ✅ Default behaviors and gotchas
- ✅ Common patterns used in our repository
- ✅ Debugging tips for common issues

**Key Points to Remember:**
1. **Heredoc MUST use fenced code blocks** (not inline backticks)
2. **Multi-line commands require triple backticks + {{execute}}**
3. **Bash blocks auto-execute, others auto-copy** (by default)
4. **Always test in Docker with matching imageid**

**When in doubt, reference the docs!**

## Security & Safety Guidelines

### 🔒 Credential Safety

**CRITICAL SECURITY REQUIREMENTS:**

```markdown
## ⚠️ IMPORTANT SECURITY NOTICE

**DO NOT USE YOUR PRODUCTION CREDENTIALS IN ANY OF THESE EXAMPLES**

This is a learning environment. Always use test accounts and dummy data for educational purposes. Never enter your real production passwords or sensitive information in tutorial environments.
```

- ✅ **Always include security warnings** at the beginning of tutorials
- ✅ **Use placeholder values** like `[YOUR_TOKEN_HERE]` that must be replaced
- ✅ **Emphasize test environments** in all credential instructions
- ✅ **Never include real credentials** in code examples
- ❌ **Never assume production data** is safe for tutorials

### 🛡️ API Safety Patterns

- ✅ **Validate all API calls** before including in tutorials
- ✅ **Test with actual SDKs** to ensure examples work
- ✅ **Include proper error handling** for all operations
- ✅ **Verify method names and signatures** against current SDK versions
- ❌ **Never include deprecated or non-existent APIs**

## Tutorial Structure & Organization

### 📋 Standard Tutorial Template

```markdown
# Step X: [Descriptive Title]

**Learning Objective**: [Single sentence describing what users will learn]

## What You'll Learn
[Bullet points of specific skills/concepts covered]

## Why [Topic] Matters?

### **Business Benefits**:
- [Benefit 1 with business impact]
- [Benefit 2 with business impact]

### **Technical Benefits**:
- [Technical advantage 1]
- [Technical advantage 2]

### 1. [Setup/Preparation Step]
[Clear instructions with expected outputs]

### 2. [Implementation Step]
[Code examples with proper formatting]

### 3. [Configuration Step]
[Parameter setup and customization]

### 4. [Execution Step]
[Running the example with expected results]

## 🔍 Understanding the Code
[Detailed explanation of key concepts]

## 🔒 Security Best Practices
[Security considerations and recommendations]

## Troubleshooting
[Common issues and solutions]

## Next Steps
[What users accomplished and what's coming next]
```

### 🎯 Step Organization Principles

1. **Start Simple**: Begin with basic connection/authentication
2. **Build Progressively**: Each step builds on previous knowledge
3. **Focus Per Step**: One main concept per step
4. **Include Validation**: Show users how to verify their work
5. **End with Advanced**: Conclude with enterprise/production patterns

### 📊 Recommended Step Sequence

**For SDK Tutorials:**
1. **Connection & Authentication** (file-based, in-memory, tokens)
2. **Caching & Resilience** (offline capability, not performance)
3. **Record Operations** (CRUD operations, field handling)
4. **File Operations** (upload, download, management)
5. **Advanced Features** (folders, bulk operations, enterprise patterns)

**For CLI Tutorials:**
1. **Installation & Setup** (basic commands, help system)
2. **Secret Retrieval** (list, get, search, caching)
3. **File Operations** (upload, download, notation syntax)
4. **Advanced Usage** (automation, CI/CD, scripting)

## Code Quality Standards

### ✅ Code Formatting Requirements

```python
# ✅ GOOD: Proper code block with language and copy functionality
```python
import os
from keeper_secrets_manager_core import SecretsManager
from keeper_secrets_manager_core.storage import InMemoryKeyValueStorage

# Configuration - replace with your credentials
KSM_CONFIG = os.environ.get("KSM_CONFIG", "[YOUR_CONFIG_HERE]")

def main():
    """Main execution function"""
    try:
        config = InMemoryKeyValueStorage(KSM_CONFIG)
        secrets_manager = SecretsManager(config=config)
        secrets = secrets_manager.get_secrets()
        print(f"✅ Success! Found {len(secrets)} secret(s)")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
```{{copy}}
```

### 🚫 Common Code Issues to Avoid

```python
# ❌ BAD: Missing closing tags, broken formatting
def example():
    print("This code block is not properly closed")

## Next Section
This text appears inside the code block!
```

**Critical Formatting Rules:**
- ✅ **Always close code blocks** with proper ``` tags
- ✅ **Include language specification** (```python, ```bash)
- ✅ **Add {{copy}} for executable code** when appropriate
- ✅ **Separate code from text** with proper line breaks
- ❌ **Never leave code blocks unclosed**

### 📝 Code Comment Standards

- ✅ **Include docstrings** for functions explaining purpose
- ✅ **Add inline comments** for complex logic
- ✅ **Use descriptive variable names** that explain purpose
- ✅ **Include configuration comments** explaining placeholders
- ❌ **Don't over-comment obvious code**

## User Experience Best Practices

### 🎨 Visual Formatting

**Use Consistent Emoji Patterns:**
- 🚀 **Starting/launching operations**
- ✅ **Success states and confirmations**
- ❌ **Errors and failures**
- ⚠️ **Warnings and important notes**
- 💡 **Tips and helpful information**
- 🔍 **Analysis and investigation**
- 🔒 **Security-related content**
- 📋 **Lists and inventories**
- 🛠️ **Configuration and setup**

### 📖 Writing Style Guidelines

**Tone & Voice:**
- ✅ **Beginner-friendly** but not condescending
- ✅ **Direct and concise** explanations
- ✅ **Action-oriented** instructions
- ✅ **Encouraging** when users succeed
- ❌ **Avoid jargon** without explanation

**Instruction Clarity:**
- ✅ **Use numbered steps** for sequential actions
- ✅ **Include expected outputs** for verification
- ✅ **Provide alternative approaches** when relevant
- ✅ **Explain the "why"** behind actions
- ❌ **Assume prior knowledge** without context

### 🎯 Success Indicators

**Always Include:**
- **Expected outputs** for each command/operation
- **Verification steps** to confirm success
- **Clear progress indicators** throughout the tutorial
- **Troubleshooting guidance** for common issues

```markdown
### 3. Run the Example

```bash
python3 step1-connection.py
```
`python3 step1-connection.py`{{execute}}

**✅ Expected Output**:
- Connection confirmation message
- Number of secrets found
- First secret title and type
- Authentication method used

**🔍 Verification**: You should see your secret count and no error messages.
```

## Technical Implementation Guidelines

### 🔧 SDK-Specific Requirements

**Python SDK Guidelines:**
- ✅ **Use correct import names** (e.g., `InMemoryKeyValueStorage` not `MemoryKeyValueStorage`)
- ✅ **Follow proper field patterns** (e.g., `RecordField(field_type='login', value=['data'])`)
- ✅ **Include proper error handling** with try-catch blocks
- ✅ **Use current API methods** (avoid deprecated calls)
- ✅ **Test all code examples** in clean Docker environments

**CLI Guidelines:**
- ✅ **Use correct command syntax** (e.g., `ksm --cache secret list`)
- ✅ **Include help system examples** (e.g., `ksm --help`)
- ✅ **Show proper flag usage** with current CLI version
- ✅ **Include output formatting** examples
- ✅ **Test all commands** before publication

### 🏗️ Architecture Patterns

**Authentication Patterns:**
```python
# ✅ GOOD: Multiple auth methods with fallbacks
def initialize_secrets_manager():
    """Initialize SecretsManager with available configuration"""
    # Try in-memory config first
    if KSM_CONFIG_BASE64:
        try:
            config = InMemoryKeyValueStorage(KSM_CONFIG_BASE64)
            return SecretsManager(config=config), "In-Memory Config"
        except Exception as e:
            print(f"⚠️  In-memory config failed: {e}")
    
    # Try file-based config with token
    if ONE_TIME_TOKEN:
        try:
            config = FileKeyValueStorage('config.json')
            return SecretsManager(token=ONE_TIME_TOKEN, config=config), "File-Based Config"
        except Exception as e:
            print(f"⚠️  File-based config failed: {e}")
    
    raise Exception("No valid configuration found.")
```

### 🧪 Resilience Patterns

**Caching for Resilience (Not Performance):**
- ✅ **Emphasize offline capability** as primary benefit
- ✅ **Focus on network outage protection** rather than speed
- ✅ **Include fallback scenarios** in examples
- ❌ **Don't oversell performance gains** (this isn't the main point)

## Testing & Validation Requirements

### 🐳 Docker Testing Standards

**⚠️ CRITICAL: ALWAYS TEST IN CONTAINERS BEFORE PUSHING**

**Before publishing or committing any tutorial changes:**

1. **Test in clean Docker environment matching the tutorial platform**:

**For Python tutorials:**
```bash
docker run --rm -v $(pwd):/workspace -w /workspace python:3.9-slim bash -c "
pip install keeper-secrets-manager-core >/dev/null 2>&1 &&
python3 your_tutorial_code.py"
```

**For Java/Gradle tutorials:**
```bash
# Test with the same Gradle version as the tutorial environment
docker run --rm -v $(pwd):/workspace -w /workspace gradle:4.4.1-jdk11 bash -c "
cd /workspace &&
gradle --version &&
# Test gradle init commands if applicable
# Test build.gradle configuration
gradle build --no-daemon"
```

**For Node.js tutorials:**
```bash
docker run --rm -v $(pwd):/workspace -w /workspace node:16-alpine sh -c "
npm install keeper-secrets-manager-core &&
node your_tutorial_code.js"
```

2. **Validate all imports** and dependencies
3. **Test with placeholder credentials** (should fail gracefully)
4. **Verify error handling** works as expected
5. **Check code structure** without network dependencies
6. **Test all command-line flags and syntax** with the specific version in the tutorial environment

### 🔧 Version-Specific Testing

**IMPORTANT: Tool versions in tutorial environments may be outdated**

- **Gradle**: Killercoda often has Gradle 4.x, not the latest 8.x
  - ❌ Modern flags like `--project-name`, `--package`, `--type` don't exist in 4.x
  - ✅ Use manual project setup or version-compatible commands
  - ✅ Test with the exact Gradle version in the environment

- **Node.js**: Check the installed version and API compatibility
- **Python**: Verify pip package versions match tutorial requirements
- **CLI Tools**: Confirm flag syntax matches the installed version

**Before pushing:**
1. ✅ Test all commands in a container with matching tool versions
2. ✅ Verify all code examples compile and run
3. ✅ Check that heredocs, scripts, and automation work correctly
4. ✅ Ensure {{execute}} button commands are single-line compatible
5. ✅ Validate file paths and directory structures are created correctly

### ✅ Validation Checklist

**Before Committing:**
- [ ] **🐳 ALL CODE TESTED IN DOCKER CONTAINER** with matching environment versions
- [ ] All code blocks properly closed
- [ ] All imports verified against current SDK
- [ ] All API calls tested with real SDK
- [ ] All command-line syntax verified with actual tool version
- [ ] Security warnings included
- [ ] Placeholder credentials used
- [ ] Error handling implemented
- [ ] Expected outputs documented
- [ ] Troubleshooting section complete
- [ ] {{execute}} buttons tested for single-line compatibility
- [ ] File creation commands (cat, heredoc) tested and working

## Documentation Standards

### 📚 Supporting Files

**Always Update:**
- `index.json` - Step titles and file references
- `intro.md` - Tutorial overview and learning objectives
- `finish.md` - Summary and next steps
- `README.md` - Feature matrix (if applicable)

### 🗂️ File Organization

```
tutorial-name/
├── index.json          # Killercoda configuration
├── intro.md           # Tutorial introduction
├── step1.md          # Individual tutorial steps
├── step2.md
├── ...
├── finish.md         # Tutorial conclusion
└── install-*.sh      # Setup scripts (if needed)
```

### 📋 README.md Feature Matrix

**When updating feature matrices:**
- ✅ **Only mark features as ✅** if explicitly demonstrated in tutorial
- ✅ **Use 🛠️ for partial coverage** or tool-specific implementations
- ✅ **Use ➖ for not applicable** or not covered
- ❌ **Never claim features** that aren't actually demonstrated

## Commit Standards

### 💬 Commit Message Template

```
[Action] [Component] [Brief Description]

- [Specific change 1 with technical detail]
- [Specific change 2 with technical detail]
- [API fixes, import corrections, etc.]
- [Security improvements or additions]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Examples:**
- `Refactor KSM Python SDK tutorial with comprehensive improvements`
- `Fix critical issues in KSM Python SDK tutorial`
- `Add caching examples to KSM CLI tutorial`

### 🎯 Best Practices for Claude AI

**When working with Claude:**
1. **Be specific about testing requirements** - ask Claude to validate in Docker
2. **Request security pattern inclusion** - ensure warnings are included
3. **Ask for current API verification** - don't assume methods exist
4. **Require error handling** - production-ready patterns only
5. **Validate against real SDKs** - test with actual dependencies

**Quality Gates:**
- All tutorials must pass Docker testing
- All API calls must be verified against current SDK versions
- All security warnings must be prominently displayed
- All code blocks must be properly formatted and closed

---

## Summary

These guidelines ensure that all KSM tutorials maintain high quality, security, and user experience standards. Following these patterns will create consistent, reliable, and beginner-friendly educational content that properly represents Keeper Security's tools and best practices.

**Remember**: The goal is to create tutorials that users can trust, that work reliably, and that teach secure patterns from the beginning.