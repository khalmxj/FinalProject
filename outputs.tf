output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = [for i in aws_instance.wnode : i.public_ip]
}

output "ansible_version" {
  description = "The version of Ansible installed on the master node."
  value       = aws_instance.master.public_ip
}

output "kubernetes_nodes" {
  description = "List of Kubernetes nodes after cluster setup."
  value       = "kubectl get nodes --kubeconfig /home/ubuntu/.kube/config"
}

output "docker_installed" {
  description = "Check Docker is installed and running on all nodes."
  value       = "docker --version"
}
