#!/bin/bash
set -e

# ==========================================
# SonarQube Community Build - Ubuntu 24.04
# ==========================================

SONAR_VERSION="26.8.0.126808"
DB_PASSWORD="Sonar@12345"

echo "1. Updating packages..."
sudo apt update


echo "2. Installing Java 21, PostgreSQL and utilities..."
sudo apt install -y \
    openjdk-21-jdk \
    postgresql \
    postgresql-contrib \
    unzip \
    wget


echo "3. Starting PostgreSQL..."
sudo systemctl enable --now postgresql


echo "4. Creating SonarQube database..."

sudo -u postgres psql <<EOF
CREATE USER sonar WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE sonarqube OWNER sonar;
EOF


echo "5. Creating SonarQube Linux user..."

sudo useradd \
    --system \
    --no-create-home \
    --shell /usr/sbin/nologin \
    sonar


echo "6. Configuring Linux requirements..."

sudo tee /etc/sysctl.d/99-sonarqube.conf > /dev/null <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF

sudo sysctl --system


echo "7. Downloading SonarQube..."

cd /tmp

wget \
"https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip"


echo "8. Extracting SonarQube..."

sudo unzip -q \
    "sonarqube-${SONAR_VERSION}.zip" \
    -d /opt/

sudo mv \
    "/opt/sonarqube-${SONAR_VERSION}" \
    /opt/sonarqube


echo "9. Setting ownership..."

sudo chown -R sonar:sonar /opt/sonarqube


echo "10. Configuring PostgreSQL connection..."

sudo tee -a /opt/sonarqube/conf/sonar.properties > /dev/null <<EOF

sonar.jdbc.username=sonar
sonar.jdbc.password=${DB_PASSWORD}
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
EOF


echo "11. Creating systemd service..."

sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
[Unit]
Description=SonarQube
After=network.target postgresql.service

[Service]
Type=forking

User=sonar
Group=sonar

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

Restart=on-failure
RestartSec=5

LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF


echo "12. Starting SonarQube..."

sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube


echo "13. Installation complete."

echo
echo "Wait about 1 minute and check:"
echo "sudo systemctl status sonarqube"
echo
echo "Then open:"
echo "http://EC2-PUBLIC-IP:9000"
