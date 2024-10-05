variable "tf_organization_name" {
  type = string
  description = "Your Terraform Cloud organization name"
  default = "nokwebspace"
}

variable "repo_name" {
  type = string
  description = "Your infrastructure as code repository"
  default = "xNok/infra-bootstrap-tools"
}

variable "deployement_approver" {
  type = string
  description = "Your user, it will de added as the approver for the repository"
  default = "xNok"
}
