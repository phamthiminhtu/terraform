resource "google_service_account" "unified_data_pipeline_service_account" {
  account_id   = "unified-data-pipeline-sa"
  display_name = "Unified Data Pipeline Service Account"
}

resource "google_project_iam_member" "unified_data_pipeline_service_account_role" {
  role   = "roles/editor"
  project = var.gcp_project_id
  member = "serviceAccount:${google_service_account.unified_data_pipeline_service_account.email}"
}
