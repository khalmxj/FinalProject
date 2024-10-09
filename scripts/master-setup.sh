#!/bin/bash
# common + master-setup.sh

# Change hostname
sudo hostnamectl set-hostname master

echo "I am in Master +common before apt update."
# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y curl gnupg software-properties-common sshpass

echo "Basic setup complete."
echo " I am master start"
# Install Ansible on the master node
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get update -y
sudo apt-get install -y ansible sshpass # Install sshpass for passwordless authentication setup

echo "Master after apt update"
# Generate SSH keys for passwordless authentication
if [ ! -f /home/ubuntu/.ssh/id_rsa ]; then
    sudo -u ubuntu ssh-keygen -t rsa -N "" -f /home/ubuntu/.ssh/id_rsa
fi

# Ensure the .ssh directory and keys have the correct permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/id_rsa
sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub

# Append the new public key to authorized_keys on the master node
cat /home/ubuntu/.ssh/id_rsa.pub | sudo tee -a /home/ubuntu/.ssh/authorized_keys > /dev/null

# Copy the public key to the workers (passwordless SSH)
#for worker_ip in $(awk '/worker/{print $2}' /etc/hosts); do
#  sshpass -p "ubuntu" ssh-copy-id -o StrictHostKeyChecking=no ubuntu@$worker_ip
#done

# Copy the public key to the master itself (for Ansible self-SSH)
#sshpass -p "ubuntu" ssh-copy-id -o StrictHostKeyChecking=no ubuntu@localhost

# Run the Ansible playbook to configure the cluster
#ansible-playbook /home/ubuntu/kubernetes-setup.yaml -i /home/ubuntu/hosts

echo "Ansible setup complete. Kubernetes configured."