# Create Controlplane (Master)
resource "aws_key_pair" "k8s_key_pair" {
  key_name   = var.key_name
  public_key = var.publick_key
  }

resource "aws_instance" "master" {
  ami                         = var.ami["master"]
  instance_type               = var.instance_type["master"]
  key_name                    = aws_key_pair.k8s_key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.sg-k8s.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 14
  }
  timeouts {
    create = "10m"
  }

  tags = {
    Name = "master-${var.k8s_name}"
  }
# Copy Scripts to Master node 
  provisioner "file" {
    source      = "scripts/master-setup.sh"
    destination = "/home/ubuntu/master-setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
# setting permission to master-setup and ran 
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/master-setup.sh",
      "/home/ubuntu/master-setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
  # Master node hots file update
provisioner "remote-exec" {
    inline = [
      "echo 'master ${self.private_ip}' | sudo tee -a /etc/hosts",
      # Backup existing Ansible hosts file
      "sudo cp /etc/ansible/hosts /etc/ansible/hosts.bak",
      #"sudo echo 'worker-${count.index} ${self.private_ip}' | sudo tee -a /etc/hosts",
      #"sudo cp /etc/hosts /etc/ansible/hosts",
      "sudo echo '[workers]' | sudo tee -a /home/ubuntu/hosts"
    ]
  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
# Copy the Ansible playbook to the master node
provisioner "file" {
  source      = "playbook/kubernetes-setup.yaml"
  destination = "/home/ubuntu/kubernetes-setup.yaml"
connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
}
# Run the Ansible playbook to set up Kubernetes
  provisioner "remote-exec" {
    inline = [
      "ansible-playbook /home/ubuntu/kubernetes-setup.yaml"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
}

# Create Worker nodes for cluster
resource "aws_instance" "wnode" {
  count                       = var.node_count
  ami                         = var.ami["worker-node"]
  instance_type               = var.instance_type["worker-node"]
  key_name                    = aws_key_pair.k8s_key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.sg-k8s.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
  tags = {
    Name = "worker-node-${count.index}"
  }
 # Copy the common setup script to worker nodes
  provisioner "file" {
    source      = "scripts/common-setup.sh"
    destination = "/home/ubuntu/common-setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }

  # Setting permission to common-setup and ran 
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/common-setup.sh",
      "/home/ubuntu/common-setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
  # Worker node hosts file update
 provisioner "remote-exec" {
    inline = [
      "echo 'worker-${count.index} ${self.private_ip}' | sudo tee -a /etc/hosts"
    ]
  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
}
# Define Ansible Hosts
resource "ansible_host" "master" {
  depends_on = [aws_instance.master]
  name       = "controlplane"
  groups     = ["master"]
  variables = {
    ansible_user                 = "ubuntu"
    ansible_host                 = aws_instance.master.public_ip
    ansible_ssh_private_key_file = "./id_rsa"
    node_hostname                = "master"
  }
}

resource "ansible_host" "worker" {
  depends_on = [aws_instance.wnode]
  count      = var.node_count
  name       = "worker-node-${count.index}"
  groups     = ["workers"]
  variables = {
    ansible_user                 = "ubuntu"
    ansible_host                 = aws_instance.wnode[count.index].public_ip
    ansible_ssh_private_key_file = "./id_rsa"
    node_hostname                = "worker-node-${count.index}"
  }
}
