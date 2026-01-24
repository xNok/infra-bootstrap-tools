provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

module "swarm_cluster" {
  source = "github.com/xNok/infra-bootstrap-tools//terraform/terraform-google-instance?ref=main"

  project_name          = var.project_name
  project_id            = var.gcp_project_id
  region                = var.gcp_region
  zone                  = var.gcp_zone
  manager_instance_type = var.machine_type_manager
  worker_instance_type  = var.machine_type_node
  manager_count         = var.manager_count
  worker_count          = var.worker_count
  image                 = var.image
  public_key_openssh    = var.public_key_openssh
}
