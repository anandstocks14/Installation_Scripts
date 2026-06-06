#!/bin/bash

set -euxo pipefail

# Wait if Ubuntu automatic updates are using apt/dpkg
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
      sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
  echo "Waiting for apt lock to be released..."
  sleep 10
done

# Update package index
sudo apt update

# Install required dependencies for Jenkins
sudo apt install -y fontconfig openjdk-21-jre wget

# Verify Java installation
java -version

# Create keyrings directory if not already present
sudo mkdir -p /etc/apt/keyrings

# Add Jenkins official repository key
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins official repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package index again after adding Jenkins repo
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Reload systemd
sudo systemctl daemon-reload

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Start Jenkins service
sudo systemctl start jenkins

# Verify Jenkins is running
sudo systemctl is-active --quiet jenkins && echo "Jenkins is running"

# Show initial Jenkins admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword