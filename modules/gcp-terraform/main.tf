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

resource "google_service_account" "doris_vm_dev_sa" {
  project = var.gcp_dev_project_id
  account_id   = "doris-vm-dev-sa"
  display_name = "Custom SA for Dev Doris VM Instance"
}

resource "google_compute_instance" "doris_vm_dev" {
  name         = var.gcp_projects_info[var.gcp_dev_project_id].vm_name
  machine_type = "e2-medium"
  zone         = var.gcp_project_region
  project      = var.gcp_dev_project_id
  tags = [var.gcp_projects_info[var.gcp_dev_project_id].vm_name]

  scheduling {
    provisioning_model = "SPOT"
    preemptible = "true"
    automatic_restart = "false"
    instance_termination_action = "STOP"
    max_run_duration {
      seconds = 604800 # 7 days
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      labels = {
        env = "dev"
      }
      size = 100
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
    ssh-keys = var.gcp_compute_engine_ssh_pub_key
  }
  allow_stopping_for_update = true
  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.doris_vm_dev_sa.email
    scopes = ["cloud-platform"]
  }
}


resource "google_project_iam_custom_role" "custom-delegate" {
  project     = var.gcp_dev_project_id
  role_id     = "CustomDelegate"
  title       = "Iceberg BQ Delegate"
  description = "Iceberg BQ Delegate"
  permissions = ["bigquery.connections.delegate"]
}