#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==============================================================================
# CONFIGURATION - Change the version here for future updates
# ==============================================================================
TOMCAT_VERSION="10.1.34"
# ==============================================================================

# Extract the major version dynamically (e.g., "10" from "10.1.34")
TOMCAT_MAJOR=$(echo $TOMCAT_VERSION | cut -d. -f1)

echo "========================================================================"
echo " Starting Apache Tomcat ${TOMCAT_VERSION} Installation on Ubuntu"
echo "========================================================================"

# 1. Update system packages
echo "--> Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install OpenJDK (Tomcat requires Java)
echo "--> Installing OpenJDK..."
sudo apt install default-jdk -y

# 3. Create Tomcat user and group (for security)
echo "--> Creating Tomcat service user..."
if ! getent group tomcat > /dev/null; then
    sudo groupadd tomcat
fi
if ! getent passwd tomcat > /dev/null; then
    sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
fi

# 4. Download and Extract Tomcat
echo "--> Downloading Tomcat ${TOMCAT_VERSION}..."
cd /tmp
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Fallback to archive mirror if the current version is older/moved
if ! wget -q --spider "$TOMCAT_URL"; then
    echo "    Using archive mirror..."
    TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
fi

wget "$TOMCAT_URL"

echo "--> Extracting Tomcat to /opt/tomcat..."
sudo mkdir -p /opt/tomcat
sudo tar -xf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1

# 5. Set Permissions
echo "--> Setting permissions..."
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/

# 6. Create Systemd Service File
echo "--> Creating systemd service..."
JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed "s:bin/java::")

sudo bash -c "cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=\"JAVA_HOME=${JAVA_HOME_PATH}\"
Environment=\"CATALINA_PID=/opt/tomcat/temp/tomcat.pid\"
Environment=\"CATALINA_HOME=/opt/tomcat\"
Environment=\"CATALINA_BASE=/opt/tomcat\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseG1GC\"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF"

# 7. Start and Enable Tomcat Service
echo "--> Starting Tomcat service..."
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

echo "========================================================================"
echo " Tomcat ${TOMCAT_VERSION} installation completed successfully!"
echo " You can access it at http://localhost:8080"
echo " Check status with: sudo systemctl status tomcat"
echo "========================================================================"