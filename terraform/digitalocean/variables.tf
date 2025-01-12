variable "worker_count" {
  type = number
  default = 0
}

variable "manager_count" {
  type = number
  default = 1
}

variable "tf_organization_name" {
  type = string
  description = "Your Terraform Cloud organization name"
}
