#!/bin/bash

# Variables
ALERTMANAGER_VERSION="0.24.0"  # Replace with the desired version
INSTALL_DIR="/opt/alertmanager"
USER="alertmanager"
GROUP="alertmanager"

# Create a user and group for Alertmanager
sudo groupadd -r $GROUP
sudo useradd -r -s /bin/false -g $GROUP $USER

# Download Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz -O /tmp/alertmanager.tar.gz

# Extract Alertmanager
sudo mkdir -p $INSTALL_DIR
sudo tar -xzf /tmp/alertmanager.tar.gz -C $INSTALL_DIR --strip-components=1

# Set ownership
sudo chown -R $USER:$GROUP $INSTALL_DIR

# Clean up
rm /tmp/alertmanager.tar.gz

# Create a systemd service file for Alertmanager
sudo bash -c 'cat << EOF > /etc/systemd/system/alertmanager.service
[Unit]
Description=Alertmanager for Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd and start Alertmanager
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

echo "Alertmanager installation and setup complete."
