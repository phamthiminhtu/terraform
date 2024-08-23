gcp_projects_info = {
    "unified-pipeline-prod-20240820" = {
        project_name = "Unified Data Pipeline Prod",
        service_account_id = "unified-data-pipeline-prod-sa",
        service_account_name = "Unified Data Pipeline Prod Service Account"
        iceberg_bucket_name = "iceberg-prod-20240820"
    },
    "unified-pipeline-dev-20240820" = {
        project_name = "Unified Data Pipeline Dev",
        service_account_id = "unified-data-pipeline-dev-sa",
        service_account_name = "Unified Data Pipeline Dev Service Account"
        iceberg_bucket_name = "iceberg-dev-20240820"
        vm_name = "doris-dev"
    }
}
gcp_project_region = "asia-southeast1-a"
gcs_bucket_location = "ASIA-SOUTHEAST1"
gcp_credentials_file_path = "/Users/tototus/.config/gcloud/application_default_credentials.json"
gcp_dev_project_id = "unified-pipeline-dev-20240820"
gcp_prod_project_id = "unified-pipeline-prod-20240820"
gcp_compute_engine_ssh_pub_key = "admin-203:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAPPBHnRpQTha8AD+h9x3BDpiBg+v+kjB3rEsm3OJE2 admin-203@unified-data-pipeline-433105.iam.gserviceaccount.com"

