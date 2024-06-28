#!/bin/bash

# Update package lists
sudo apt-get update

# Install prerequisites
sudo apt-get install -y apt-transport-https software-properties-common wget

# Add Grafana repository
wget -q https://packages.grafana.com/gpgkey/public-grafana.gpg -O - | sudo apt-key add -

echo "deb [arch=amd64] https://packages.grafana.com/oss/stable/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Update package lists again
sudo apt-get update

# Install Grafana
sudo apt-get install -y grafana

# Enable and start Grafana service
sudo systemctl daemon-reload
sudo systemctl start grafana
sudo systemctl enable grafana

# Open Grafana in web browser (replace with your server IP or hostname if needed)
echo "Grafana is now running at http://localhost:3000"
