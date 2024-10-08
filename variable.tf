### VPC CIDR Block
variable "cidr_vpc" {
  description = "cidr range for VPC"
  type        = string
  default     = "100.192.0.0/16"
}

variable "cidr_subnet" {
  description = "cidr range for public VPC Subnet"
  type        = string
  default     = "100.192.1.0/24"
}

variable "k8s_name" {
  type        = string
  description = "cluster"
  default     = "k8cluster"
}

variable "ami" {
  description = "ubuntu machine image for nodes"
  type        = map(string)
  default = {
    master      = "ami-0e8d228ad90af673b"
    worker-node = "ami-0e8d228ad90af673b"
  }
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "publick_key" {
  type = string
}

variable "private_key" {
  type = string
}

variable "key_name" {
  description = "keypair for the cluster"
  type        = string
  default     = "K8sKeypair"
}

variable "node_count" {
  description = "# of worker nodes"
  type        = number
  default     = 2
}

variable "instance_type" {
  type = map(string)
  default = {
    master      = "t2.medium"
    worker-node = "t2.micro"
  }
}

