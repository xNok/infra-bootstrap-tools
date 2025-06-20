variable "project_name" {
  type = string
  default = "infra-bootstrap-tools"
  description = "DigitalOcean Project holding all the resource"
}

variable "droplet_image" {
  type = string
  description = "name of the image to use when provioning droplets"
  default = "ubuntu-24-04-x64"
}

variable "droplet_location" {
  type = string
  description = "location where the droplet need to be deployed"
  default = "lon1"
}

variable "worker_count" {
  type = number
  default = 0
}

variable "worker_size" {
  type = string
  default = "s-1vcpu-1gb"
  description = "DigitalOcean droplet size"
}

variable "manager_count" {
  type = number
  default = 1
}

variable "manager_size" {
  type = string
  default = "s-1vcpu-1gb"
  description = "DigitalOcean droplet size"
}

variable "public_key_openssh" {
  type = string
  description = "SSh public key to be added to all the droplets"
}

