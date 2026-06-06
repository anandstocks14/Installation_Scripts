#!/bin/bash

set -e

sudo dnf install -y wget

echo "Adding Jenkins repository..."
sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/rpm-stable/jenkins.repo

echo "Importing Jenkins GPG key..."
sudo rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2023.key

echo "Updating packages..."
sudo dnf upgrade -y

echo "Installing Java..."
sudo dnf install -y fontconfig java-21-openjdk

echo "Installing Jenkins..."
sudo dnf install -y jenkins

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling Jenkins..."
sudo systemctl enable jenkins

echo "Starting Jenkins..."
sudo systemctl start jenkins

echo "Checking Jenkins service..."
sudo systemctl is-active --quiet jenkins && echo "Jenkins is running"


