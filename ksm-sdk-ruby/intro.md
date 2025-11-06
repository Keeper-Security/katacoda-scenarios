# Keeper Secrets Manager - Ruby SDK Complete Guide

Welcome to the comprehensive hands-on tutorial for the **Keeper Secrets Manager (KSM) Ruby SDK**. This interactive guide will teach you everything you need to know to integrate KSM into your Ruby applications securely and efficiently.

## 🎯 What You'll Learn

By the end of this tutorial, you will be able to:

- **Connect** to Keeper Secrets Manager from Ruby applications
- **Read** secrets and access specific fields programmatically
- **Create and update** records with various field types
- **Organize** secrets using folders and hierarchies
- **Manage files** attached to secrets (upload/download)
- **Implement** production-ready patterns with caching, error handling, and security best practices

## 📋 Prerequisites

- **Ruby 3.1+** (pre-installed in this environment)
- **Keeper Vault** account (free trial available at [keepersecurity.com](https://www.keepersecurity.com))
- **KSM Application** created in your Keeper Vault
- **One-Time Access Token** or **Base64 Configuration** from your KSM application

## 🔑 Before You Begin

### ⚠️ CRITICAL SECURITY NOTICE

**DO NOT USE YOUR PRODUCTION CREDENTIALS IN THIS TUTORIAL**

This is a learning environment. Always use:
- **Test accounts** with dummy data
- **Separate KSM applications** for tutorials
- **Disposable secrets** that can be safely deleted

**NEVER:**
- Commit credentials to version control
- Share your base64 configuration publicly
- Log secret values in production
- Use production tokens in development

## 🏗️ Tutorial Structure

This tutorial follows a **value-first** progression - you'll see results immediately and build on working code:

### **Step 1: Installation & First Connection** ⚡
Get up and running in under 2 minutes. Connect to KSM and list your secrets.

### **Step 2: Reading Secrets & Fields** 📖
Learn how to retrieve specific secrets, access fields, and search by title.

### **Step 3: Creating & Updating Records** ✏️
Master CRUD operations with various field types and update strategies.

### **Step 4: Folder Management** 📁
Organize your secrets with folders and understand folder hierarchies.

###**Step 5: File Operations** 📎
Upload and download files attached to secrets securely.

### **Step 6: Production Patterns** 🚀
Implement caching, error handling, logging, and security hardening for production use.

## 🛠️ What's Installed

This environment comes pre-configured with:
- **Ruby 3.2+** with full standard library
- **keeper_secrets_manager gem (17.1.0)** - latest stable version
- **Working directory** at `/root/ksm-tutorial`

## 📚 Documentation References

- [KSM Ruby SDK GitHub](https://github.com/Keeper-Security/secrets-manager/tree/master/sdk/ruby)
- [KSM Documentation](https://docs.keeper.io/secrets-manager/)
- [RubyGems Page](https://rubygems.org/gems/keeper_secrets_manager)

## 🚀 Ready to Start?

Click **"Start"** to begin with Step 1: Installation & First Connection.

You'll write your first working KSM Ruby script in the next 2 minutes!
