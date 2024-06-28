#How to use
#Save the script as install_jenkins.sh.
#Make the script executable: chmod +x install_jenkins.sh.
#Run the script: ./install_jenkins.sh.

#!/bin/bash

# Update and Upgrade System Packages
sudo apt update && sudo apt upgrade -y

# Install Java Development Kit (JDK)
sudo apt install openjdk-11-jdk -y

# Add Jenkins Repository Key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg

# Add Jenkins Package Repository
sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary' | sudo tee /etc/apt/sources.list.d/jenkins.list

# Update Package Lists and Install Jenkins
sudo apt update && sudo apt install jenkins -y

# Start and Enable Jenkins Service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Function to find the Jenkins admin password
find_admin_password() {
  local password_file="/var/lib/jenkins/secrets/initialAdminPassword"

  # Check console output first (more secure)
  password=$(grep -E '^Initial password' /var/log/syslog)
  if [[ -n "$password" ]]; then
    echo "Found admin password in console output."
    password=${password#*password: }
    echo "Your Jenkins admin password is: $password"
    return 0
  fi

  # If not found in console output, use log file (less secure)
  if [[ -f "$password_file" ]]; then
    password=$(cat "$password_file")
    echo "Found admin password in log file (less secure method)."
    echo "**Warning:** Exposing password from log file is not recommended."
    echo "Your Jenkins admin password is: $password"
    return 0
  fi

  echo "Admin password not found. Check console output or Jenkins logs."
  return 1
}

# Find the admin password
if ! find_admin_password; then
  exit 1
fi

# Replace 'your_admin_password' with the actual password you found
jenkins_url="http://localhost:8080"
curl -X POST "$jenkins_url/unlockSlave?secret=your_admin_password"

echo "Jenkins installation and initial unlock complete!"

echo "**Important:**"
echo " - Access Jenkins web interface: $jenkins_url"
echo " - Consider creating a new admin user and configuring security settings."

exit 0
