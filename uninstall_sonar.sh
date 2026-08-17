#!/bin/bash

# Stop SonarQube
sudo systemctl stop sonarqube 2>/dev/null || true
sudo systemctl disable sonarqube 2>/dev/null || true

# Remove SonarQube systemd service
sudo rm -f /etc/systemd/system/sonarqube.service
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Remove SonarQube files
sudo rm -rf /opt/sonarqube
sudo rm -rf /var/sonarqube

# Remove downloaded SonarQube ZIP
sudo rm -f /tmp/sonarqube-*.zip

# Remove SonarQube Linux user/group
sudo userdel sonar 2>/dev/null || true
sudo groupdel sonar 2>/dev/null || true

# Remove SonarQube limits/config
sudo rm -f /etc/security/limits.d/99-sonarqube.conf
sudo rm -f /etc/sysctl.d/99-sonarqube.conf

# Reload sysctl settings
sudo sysctl --system

# Remove SonarQube PostgreSQL database and user
sudo -u postgres psql -c "DROP DATABASE IF EXISTS sonarqube;"
sudo -u postgres psql -c "DROP USER IF EXISTS sonar;"

# Remove PostgreSQL
sudo apt purge -y postgresql postgresql-contrib
sudo apt autoremove -y

# Remove PostgreSQL remaining data/config
sudo rm -rf /var/lib/postgresql
sudo rm -rf /etc/postgresql
sudo rm -rf /var/log/postgresql

# Remove Java 21
sudo apt purge -y openjdk-21-jdk openjdk-21-jre openjdk-21-jdk-headless openjdk-21-jre-headless
sudo apt autoremove -y

echo "SonarQube setup removed."
