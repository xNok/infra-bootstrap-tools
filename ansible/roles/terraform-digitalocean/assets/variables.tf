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

