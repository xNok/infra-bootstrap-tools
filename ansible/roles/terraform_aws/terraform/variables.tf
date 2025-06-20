variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "manager_instance_type" {
  description = "EC2 instance type for manager nodes"
  type        = string
  default     = "t2.micro"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t2.micro"
}

variable "ami_filter" {
  description = "AMI filter to select the AMI for instances"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"
}

variable "key_pair_name" {
  description = "Name of the AWS EC2 key pair"
  type        = string
  default     = "infra-bootstrap-tools"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "manager_count" {
  description = "Number of manager nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

variable "project_name" {
  type = string
  default = "infra-bootstrap-tools"
  description = "Project name for tagging resources"
}

variable "public_key_openssh" {
  type = string
  description = "SSh public key to be added to all the droplets"
  sensitive = true
}
