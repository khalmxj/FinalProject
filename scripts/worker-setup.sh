#!/bin/bash
# worker-setup.sh

# Wait for the master join command to be created
while [ ! -f /home/ubuntu/kubeadm-join.out ]; do sleep 5; done

# Join the Kubernetes cluster using the command from the master node
sudo $(cat /home/ubuntu/kubeadm-join.out)

# Output verification
echo "Worker node joined:"
kubectl get nodes