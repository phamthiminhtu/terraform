provider "google" {
  credentials = file(var.gcp_credentials_file_path)
}

module "gcp-terraform" {
  source = "./modules/gcp-terraform"
  gcp_projects_info=var.gcp_projects_info
  gcp_project_region=var.gcp_project_region
  gcp_project_location=var.gcp_project_location
  gcp_dev_project_id=var.gcp_dev_project_id
  gcp_prod_project_id=var.gcp_prod_project_id
  gcp_compute_engine_ssh_pub_key=var.gcp_compute_engine_ssh_pub_key
}
