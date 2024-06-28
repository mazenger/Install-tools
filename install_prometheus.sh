#!/bin/bash

# Set Prometheus, Node Exporter, and Alertmanager versions from environment variables (or default)
prometheus_version=${PROMETHEUS_VERSION:-latest}
node_exporter_version=${NODE_EXPORTER_VERSION:-latest}
alertmanager_version=${ALERTMANAGER_VERSION:-latest}

# Function to download and extract a tool
download_and_extract() {
  local tool_name="$1"
  local url="https://github.com/prometheus/$tool_name/releases/download/v$1/$tool_name-$1.linux-amd64.tar.gz"
  local target_dir="/tmp/$tool_name"

  wget -q "$url" -O - | tar -xzf - -C "$target_dir"
  if [[ $? -ne 0 ]]; then
    echo "Failed to download and extract $tool_name!"
    exit 1
  fi
}

# Function to create a Prometheus user
create_prometheus_user() {
  local user_name="prometheus"
  if [[ ! $(id -u "$user_name" &> /dev/null) ]]; then
    sudo useradd --no-create-home --shell /bin/false "$user_name"
  fi
}

# Create Prometheus user
create_prometheus_user

# Function to move binaries to Prometheus user directory
move_prometheus_binaries() {
  local user="$1"  # Prometheus user
  local target_dir="/home/$user/prometheus-$prometheus_version"

  sudo mv "/tmp/prometheus/prometheus" "/tmp/prometheus/promtool" "$target_dir"
  sudo mv "/tmp/prometheus/rules/*.yml" "/etc/prometheus/"
  sudo mv "/tmp/node_exporter/node_exporter" "$target_dir/node_exporter"
  sudo mv "/tmp/alertmanager/alertmanager" "$target_dir/alertmanager"
  sudo chown -R "$user:$user" "$target_dir" /etc/prometheus/
}

# Move binaries to Prometheus user directory
move_prometheus_binaries "prometheus"

# Create Prometheus systemd service
sudo vi /etc/systemd/system/prometheus.service

# Paste the following content into vi and save (press `:wq` to save and quit)
<<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus  # Use the Prometheus user
Group=prometheus  # Use the Prometheus user
Type=simple
WorkingDirectory=/home/prometheus/prometheus-$prometheus_version
ExecStart=/home/prometheus/prometheus-$prometheus_version/prometheus --config.file /etc/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start/enable Prometheus service
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Download and extract Node Exporter
download_and_extract "node_exporter" "$node_exporter_version"

# Move Node Exporter binary to Prometheus user directory
sudo mv "/tmp/node_exporter/node_exporter" "/home/prometheus/prometheus-$prometheus_version/node_exporter"
sudo chown prometheus:prometheus "/home/prometheus/prometheus-$prometheus_version/node_exporter"

# Create Node Exporter systemd service
sudo vi /etc/systemd/system/node_exporter.service

# Paste the following content into vi and save (press `:wq` to save and quit)
<<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=prometheus  # Use the Prometheus user
Group=prometheus  # Use the Prometheus user
Type=simple
WorkingDirectory=/home/prometheus/prometheus-$prometheus_version
ExecStart=/home/prometheus/prometheus-$prometheus_version/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start/enable Node Exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Download and extract Alertmanager
download_and_extract "alertmanager" "$alertmanager_version"

# Move Alertmanager binary to Prometheus user directory
sudo mv "/tmp/alertmanager/alertmanager" "/home/prometheus/prometheus-$prometheus_version/alertmanager"
sudo chown prometheus:prometheus "/home/prometheus/prometheus-$prometheus_version/alertmanager"

# Create Alertmanager systemd service
sudo vi /etc/system
