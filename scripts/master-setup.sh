#!/bin/bash
# common + master-setup.sh

# Change hostname
sudo hostnamectl set-hostname master

echo "I am in Master +common before apt update."
# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y curl gnupg software-properties-common sshpass openssh-server

# Generate SSH keys for passwordless authentication
if [ ! -f /home/ubuntu/.ssh/id_rsa ]; then
    sudo -u ubuntu ssh-keygen -t rsa -N "" -f /home/ubuntu/.ssh/id_rsa
    echo "Ansible keypair generated /home/ubuntu/.ssh/id_rsa"
    # Ensure the .ssh directory and keys have the correct permissions
    sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    sudo chmod 700 /home/ubuntu/.ssh
    sudo chmod 600 /home/ubuntu/.ssh/id_rsa
    sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub
    echo "Keypair folder and user permissions are applied"
fi

# Append the new public key to authorized_keys on the master node
cat /home/ubuntu/.ssh/id_rsa.pub | sudo tee -a /home/ubuntu/.ssh/authorized_keys > /dev/null
