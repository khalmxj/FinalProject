#!/bin/bash
# common-setup.sh

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y curl gnupg software-properties-common sshpass


# Copy the hosts file to /etc/hosts
if [ -f /home/ubuntu/hosts ]; then
  cat /home/ubuntu/hosts | sudo tee -a /etc/hosts
fi

echo "Basic setup complete."