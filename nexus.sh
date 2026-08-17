#!/bin/bash
set -e

NEXUS_VERSION="3.95.1-01"

echo "1. Updating packages..."
sudo apt update

echo "2. Installing required tools..."
sudo apt install -y wget tar

echo "3. Creating nexus user..."
if ! id nexus >/dev/null 2>&1; then
    sudo useradd \
        --system \
        --create-home \
        --shell /bin/bash \
        nexus
fi

echo "4. Downloading Nexus Repository..."
cd /tmp

wget -O nexus.tar.gz \
"https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"

echo "5. Extracting Nexus..."
sudo tar -xzf nexus.tar.gz -C /opt/

echo "6. Renaming Nexus directory..."
sudo mv "/opt/nexus-${NEXUS_VERSION}" /opt/nexus

echo "7. Setting ownership..."
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

echo "8. Creating systemd service..."

sudo tee /etc/systemd/system/nexus.service > /dev/null <<'EOF'
[Unit]
Description=Nexus Repository
After=network.target

[Service]
Type=forking
User=nexus
Group=nexus

ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop

Restart=on-failure
RestartSec=5

LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "9. Reloading systemd..."
sudo systemctl daemon-reload

echo "10. Enabling Nexus..."
sudo systemctl enable nexus

echo "11. Starting Nexus..."
sudo systemctl start nexus

echo "12. Checking Nexus status..."
sudo systemctl status nexus --no-pager
