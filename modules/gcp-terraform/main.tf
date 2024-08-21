# resource "google_project" "projects" {
#   for_each = var.gcp_projects_info
#   name       = each.value.project_name
#   project_id = each.key  # Must be globally unique
#   lifecycle {
#     prevent_destroy = false
#   }
# }

resource "google_service_account" "service_accounts" {
  for_each = var.gcp_projects_info
  provider = google
  account_id   = each.value.service_account_id
  display_name = "Service Account for ${each.key}"
  project      = each.key
}

resource "google_project_iam_member" "unified_data_pipeline_service_accounts_roles" {
  for_each = var.gcp_projects_info
  role   = "roles/editor"
  project = each.key 
  member = "serviceAccount:${google_service_account.service_accounts[each.key].email}"
}

resource "google_storage_bucket" "iceberg_buckets" {
  for_each = var.gcp_projects_info
  project = each.key
  name          = each.value.iceberg_bucket_name # Must be globally unique
  location      = var.gcs_bucket_location
  force_destroy = true

  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = false
  }
}
