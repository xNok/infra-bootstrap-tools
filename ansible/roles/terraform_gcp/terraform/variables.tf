variable "project_name" {
  type = string
  default = "infra-bootstrap-tools"
  description = "Project name"
}

variable "gcp_project_id" {
  type = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type = string
  description = "GCP Region"
  default = "europe-west1"
}

variable "gcp_zone" {
  type = string
  description = "GCP Zone"
  default = "europe-west1-b"
}

variable "machine_type_manager" {
  type = string
  description = "Machine type for managers"
  default = "e2-micro"
}

variable "machine_type_node" {
  type = string
  description = "Machine type for nodes"
  default = "e2-micro"
}

variable "manager_count" {
  type = number
  default = 1
}

variable "worker_count" {
  type = number
  default = 0
}

variable "image" {
  type = string
  description = "Image for instances"
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "public_key_openssh" {
  type = string
  description = "SSH public key to be added to instances"
}
