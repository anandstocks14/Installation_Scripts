#!/bin/bash

set -euxo pipefail

echo "Updating package index..."
sudo apt update

echo "Installing required dependencies..."
sudo apt install -y gnupg software-properties-common curl

echo "Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "Adding HashiCorp repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "Updating package index..."
sudo apt update

echo "Installing Terraform..."
sudo apt install -y terraform

echo "Verifying Terraform installation..."
terraform version