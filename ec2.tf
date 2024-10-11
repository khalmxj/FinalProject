# Create Controlplane (Master)
resource "aws_key_pair" "k8s_key_pair" {
  key_name   = var.key_name
  public_key = file(var.publick_key)
}

# Create AWS-EC2 Jump host.
resource "aws_instance" "team2jvs" {
  ami                         = var.ami["jump-node"]
  instance_type               = var.instance_type["jump-node"]
  key_name                    = aws_key_pair.k8s_key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.sg-k8s.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 6
  }
  tags = {
    Name = "jump-node"
  }
  # Copy the jump installation script
  provisioner "file" {
    source      = "scripts/jump-setup.sh"
    destination = "/home/ubuntu/jump-setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key)
      host        = self.public_ip
    }
  }

  # Setting permission to jump-setup which will update and install ansible
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/jump-setup.sh",
      "/home/ubuntu/jump-setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key)
      host        = self.public_ip
    }
  }
}#end of jump node block


# Create AWS-EC2 Docker host

resource "aws_instance" "docker-compose" {
  ami                         = var.ami["dc-node"]
  instance_type               = var.instance_type["dc-node"]
  key_name                    = aws_key_pair.k8s_key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.cluster-subnet.id
  vpc_security_group_ids      = [aws_security_group.sg-k8s.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 6
  }
  tags = {
    Name = "dc-node"
  }
  # Copy the common installation script
  provisioner "file" {
    source      = "scripts/common-setup.sh"
    destination = "/home/common-setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key)
      host        = self.public_ip
    }
  }

  # Setting permission to dc-node on the common.sh files 
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/common-setup.sh",
      "/home/ubuntu/common-setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key)
      host        = self.public_ip
    }
  }
}#end of Docker-node block
 

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
      private_key = file(var.private_key)
      host        = self.public_ip
    }
  }
  # setting permission to master-setup and ran 
  provisioner "remote-exec" {
    inline = [
      #change the permissions on the file before running
      "chmod +x /home/ubuntu/master-setup.sh",
      "/home/ubuntu/master-setup.sh",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key)
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
      private_key = file(var.private_key)
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
      private_key = file(var.private_key)
      host        = self.public_ip
    }
  }
}
# Define Ansible Hosts
resource "ansible_host" "team2jvs" {
  depends_on = [aws_instance.team2jvs]
  name       = "controlplane"
  groups     = ["master"]
  variables = {
    ansible_user                 = "ubuntu"
    ansible_host                 = aws_instance.team2jvs.private_ip
    ansible_ssh_private_key_file = "/home/ubuntu/.ssh/id_rsa"
    node_hostname                = "jump-node"
  }
}