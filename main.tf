provider "google" {
  credentials = file(var.gcp_credentials_file_path)
  project     = var.gcp_project_id
}

module "gcp-terraform" {
  source = "./modules/gcp-terraform"
  gcp_project_id=var.gcp_project_id
  gcp_project_name=var.gcp_project_name
  gcp_project_region=var.gcp_project_region
}
