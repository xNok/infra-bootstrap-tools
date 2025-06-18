variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "manager_instance_type" {
  description = "EC2 instance type for manager nodes"
  type        = string
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
}

variable "manager_ami_id" {
  description = "AMI ID for manager instances"
  type        = string
}

variable "worker_ami_id" {
  description = "AMI ID for worker instances"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the AWS EC2 key pair"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
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
