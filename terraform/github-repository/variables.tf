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

variable "CADDY_DIGITALOCEAN_API_TOKEN" {
  type = string
  description = "Digital API key that caddy will use to setup DNS records"
  default = ""
}

variable "CADDY_GITHUB_CLIENT_ID" {
  type = string
  description = "Github App client id that caddy will use for authorization"
  default = ""
}

variable "CADDY_GITHUB_CLIENT_SECRET" {
  type = string
  description = "Github App client secret that caddy will use for authorization"
  default = ""
}
