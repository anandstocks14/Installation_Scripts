#!/bin/bash

set -euxo pipefail

# Wait if apt/dpkg is locked by another process
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
      sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
  echo "Waiting for apt lock to be released..."
  sleep 10
done

# Remove old/conflicting Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt remove -y $pkg || true
done

# Update package index
sudo apt update

# Install required packages
sudo apt install -y ca-certificates curl

# Create Docker keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker official GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# Give read permission to Docker GPG key
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker official repository
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update package index after adding Docker repository
sudo apt update

# Install Docker Engine, CLI, containerd, Buildx and Compose plugin
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker to start on boot
sudo systemctl enable docker

# Start Docker service
sudo systemctl start docker

# Verify Docker service
sudo systemctl is-active --quiet docker && echo "Docker is running"

# Run test container using sudo
sudo docker run hello-world

# Create docker group if it does not exist
sudo groupadd docker || true

# Add current user to docker group
sudo usermod -aG docker "$USER"

# Apply docker group in current shell
newgrp docker <<EOF
docker run hello-world
docker version
docker compose version
EOF

echo "Docker installation completed successfully."
echo "Logout and login again, or reboot, to use docker without sudo permanently."