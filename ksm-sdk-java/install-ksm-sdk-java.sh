#!/bin/bash

echo "🚀 Setting up Java environment and KSM SDK dependencies..."

# Update package lists and install OpenJDK 17, unzip, and curl
echo "🔧 Installing Java (OpenJDK 17), unzip, and curl..."
apt update -qq && apt install -y openjdk-17-jdk unzip curl

# Install Gradle 8.11.1 (latest stable 8.x version)
echo "📦 Installing Gradle 8.11.1..."
GRADLE_VERSION=8.11.1
cd /opt
curl -sL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip
unzip -q gradle.zip
rm gradle.zip
ln -sf /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle
cd ~

# Verify installations
echo "✅ Verifying installations..."
java -version
gradle --version

# Clean up default Gradle project files if they exist (scenario specific)
echo "🧹 Cleaning up any existing default Gradle project files..."
rm -f src/main/java/com/keepersecurity/ksmsample/App.java 2>/dev/null && rm -f src/test/java/com/keepersecurity/ksmsample/AppTest.java 2>/dev/null

echo "✅ Java SDK environment setup complete!"
echo "💡 You can now proceed with the KSM Java SDK tutorial steps." 