variable "project_name" {
  type = string
  default = "infra-bootstrap-tools"
  description = "DigitalOcean Project holding all the resource"
}

variable "instance_image" {
  type = string
  description = "Cloud instance image to use for nodes"
  default = "ubuntu-24-04-x64"
}

variable "region" {
  type = string
  description = "Cloud region to deploy resources"
  default = "lon1"
}

variable "worker_count" {
  type = number
  default = 0
}

variable "worker_instance_size" {
  type = string
  default = "s-1vcpu-1gb"
  description = "Cloud instance size for worker nodes"
}

variable "manager_count" {
  type = number
  default = 1
}

variable "manager_instance_size" {
  type = string
  default = "s-1vcpu-1gb"
  description = "Cloud instance size for manager nodes"
}

variable "public_key_openssh" {
  type = string
  description = "SSh public key to be added to all the droplets"
  sensitive = true
}
