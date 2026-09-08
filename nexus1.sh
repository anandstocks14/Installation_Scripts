#!/bin/bash

set -e

NEXUS_VERSION="3.96.0-09"

echo "1. Updating packages..."
sudo apt update

echo "2. Installing required tools..."
sudo apt install -y wget tar

echo "3. Creating Nexus user..."
if ! id nexus >/dev/null 2>&1; then
    sudo useradd \
        --system \
        --home-dir /opt/nexus \
        --shell /bin/bash \
        nexus
fi

echo "4. Downloading Nexus Repository..."
cd /tmp

wget -O nexus.tar.gz \
    "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"

echo "5. Extracting Nexus..."
sudo tar -xzf nexus.tar.gz -C /opt/

echo "6. Creating /opt/nexus symbolic link..."
sudo ln -sfn "/opt/nexus-${NEXUS_VERSION}" /opt/nexus

echo "7. Creating Nexus data directory..."
sudo mkdir -p /opt/sonatype-work/nexus3

echo "8. Configuring memory for 4 GB RAM..."
sudo sed -i 's/^-Xms.*/-Xms2G/' \
    /opt/nexus/bin/nexus.vmoptions

sudo sed -i 's/^-Xmx.*/-Xmx2G/' \
    /opt/nexus/bin/nexus.vmoptions

sudo sed -i \
    's/^-XX:MaxDirectMemorySize=.*/-XX:MaxDirectMemorySize=512M/' \
    /opt/nexus/bin/nexus.vmoptions

echo "9. Setting ownership..."
sudo chown -R nexus:nexus "/opt/nexus-${NEXUS_VERSION}"
sudo chown -R nexus:nexus /opt/sonatype-work

echo "10. Creating systemd service..."
sudo tee /etc/systemd/system/nexus.service >/dev/null <<'EOF'
[Unit]
Description=Sonatype Nexus Repository
After=network.target

[Service]
Type=forking
User=nexus
Group=nexus

ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop

Restart=on-failure
RestartSec=10
TimeoutStartSec=600

LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "11. Reloading systemd..."
sudo systemctl daemon-reload

echo "12. Enabling Nexus at boot..."
sudo systemctl enable nexus

echo "13. Starting Nexus..."
sudo systemctl start nexus

echo "14. Removing downloaded archive..."
rm -f /tmp/nexus.tar.gz

echo "Nexus installation completed."
echo "Allow approximately 2-5 minutes for startup."
echo "Access Nexus at: http://SERVER-PUBLIC-IP:8081"
