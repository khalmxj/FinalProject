#!/bin/bash
# master-setup.sh

# Setup kubeconfig for kubectl access
sudo mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Install Ansible on the master node
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get update -y
sudo apt-get install -y ansible sshpass # Install sshpass for passwordless authentication setup

# Generate SSH keys for passwordless authentication
if [ ! -f /home/ubuntu/.ssh/id_rsa ]; then
    sudo -u ubuntu ssh-keygen -t rsa -N "" -f /home/ubuntu/.ssh/id_rsa
fi

# Copy the public key to the workers (passwordless SSH)
for worker_ip in $(awk '/worker/{print $2}' /home/ubuntu/hosts); do
  sshpass -p "ubuntu" ssh-copy-id -o StrictHostKeyChecking=no ubuntu@$worker_ip
done

# Copy the public key to the master itself (for Ansible self-SSH)
sshpass -p "ubuntu" ssh-copy-id -o StrictHostKeyChecking=no ubuntu@localhost

# Run the Ansible playbook to configure the cluster
ansible-playbook /home/ubuntu/kubernetes-setup.yaml -i /home/ubuntu/hosts

echo "Ansible setup complete. Kubernetes configured."