resource "google_service_account" "service_accounts" {
  for_each     = var.gcp_projects_info
  provider     = google
  account_id   = each.value.service_account_id
  display_name = "Service Account for ${each.key}"
  project      = each.key
}

resource "google_project_iam_member" "unified_data_pipeline_service_accounts_roles" {
  for_each = var.gcp_projects_info
  role     = "roles/editor"
  project  = each.key
  member   = "serviceAccount:${google_service_account.service_accounts[each.key].email}"
}

locals {
  flattened_iceberg_buckets = {
    for project_id, value in var.gcp_projects_info : project_id => lookup(value, "iceberg_bucket_names", null)
  }

  iceberg_gcs = flatten(
    [for project_id, value in local.flattened_iceberg_buckets :
      flatten(
        [for iceberg_bucket_name in value :
          {
            "project_id"          = project_id
            "iceberg_bucket_name" = iceberg_bucket_name
          }
      ])
  ])

  iceberg_gcs_map = zipmap(
    [for i in range(length(local.iceberg_gcs)) : i],
    local.iceberg_gcs
  )
}

resource "google_storage_bucket" "iceberg_buckets" {
  for_each      = local.iceberg_gcs_map
  project       = each.value.project_id
  name          = each.value.iceberg_bucket_name # Must be globally unique
  location      = var.gcp_project_location
  force_destroy = true

  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = false
  }
}

# Grant permissions

locals {
  iceberg_dev_catalog_bucket = [for bucket in local.flattened_iceberg_buckets["${var.gcp_dev_project_id}"] : bucket if can(regex("catalog", bucket))][0]
  iceberg_dev_storage_bucket = [for bucket in local.flattened_iceberg_buckets["${var.gcp_dev_project_id}"] : bucket if can(regex("storage", bucket))][0]
  iceberg_prod_catalog_bucket = [for bucket in local.flattened_iceberg_buckets["${var.gcp_prod_project_id}"] : bucket if can(regex("catalog", bucket))][0]
  iceberg_prod_storage_bucket = [for bucket in local.flattened_iceberg_buckets["${var.gcp_prod_project_id}"] : bucket if can(regex("storage", bucket))][0]
  gcs_bucket_bindings = [
    {
      bucket = local.iceberg_dev_storage_bucket
      role   = "roles/storage.objectViewer"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_dev_project_id].spark[0].service_account_id}"
      ]
    },
    {
      bucket = local.iceberg_dev_catalog_bucket
      role   = "roles/storage.objectAdmin"
      members = [
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_dev_project_id].cloud_resource[0].service_account_id}"
      ]
    },
    {
      bucket = local.iceberg_dev_storage_bucket
      role   = "roles/storage.objectAdmin"
      members = [
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_dev_project_id].cloud_resource[0].service_account_id}",
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_dev_project_id].spark[0].service_account_id}"
      ]
    },
    {
      bucket = local.iceberg_prod_storage_bucket
      role   = "roles/storage.objectViewer"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_prod_project_id].spark[0].service_account_id}"
      ]
    },
    {
      bucket = local.iceberg_prod_catalog_bucket
      role   = "roles/storage.objectAdmin"
      members = [
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_prod_project_id].cloud_resource[0].service_account_id}"
      ]
    },
    {
      bucket = local.iceberg_prod_storage_bucket
      role   = "roles/storage.objectAdmin"
      members = [
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_prod_project_id].cloud_resource[0].service_account_id}",
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_prod_project_id].spark[0].service_account_id}"
      ]
    }
  ]
  bigquery_dataset_bindings = [
    {
      dataset_id = "taxi_dataset"
      role       = "roles/bigquery.dataOwner"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_dev_project_id].spark[0].service_account_id}",
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_dev_project_id].cloud_resource[0].service_account_id}",
      ]
    }
  ]
  all_bigquery_dataset_bindings = [
    for binding in local.bigquery_dataset_bindings :
    {
      project    = var.gcp_dev_project_id # only have spark connection on dev for now
      dataset_id = binding.dataset_id
      role       = binding.role
      members    = binding.members
    }
  ]
  project_bindings = [
    {
      project = var.gcp_dev_project_id
      role    = "roles/biglake.admin"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_dev_project_id].spark[0].service_account_id}",
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_dev_project_id].cloud_resource[0].service_account_id}",
      ]
    },
    {
      project = var.gcp_dev_project_id
      role    = "roles/bigquery.user"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_dev_project_id].spark[0].service_account_id}",
      ]
    },
    {
      project = var.gcp_prod_project_id
      role    = "roles/biglake.admin"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_prod_project_id].spark[0].service_account_id}",
        "serviceAccount:${google_bigquery_connection.biglake_connection[var.gcp_prod_project_id].cloud_resource[0].service_account_id}",
      ]
    },
    {
      project = var.gcp_prod_project_id
      role    = "roles/bigquery.user"
      members = [
        "serviceAccount:${google_bigquery_connection.bigspark_connection[var.gcp_prod_project_id].spark[0].service_account_id}",
      ]
    }
  ]
}

resource "google_storage_bucket_iam_binding" "bucket_permissions" {
  for_each = { for binding in local.gcs_bucket_bindings : "${binding.bucket}-${binding.role}" => binding }
  bucket   = each.value.bucket
  role     = each.value.role
  members  = each.value.members
}

resource "google_bigquery_dataset_iam_binding" "bigquery_dataset_bindings" {
  for_each   = { for binding in local.all_bigquery_dataset_bindings : "${binding.project}-${binding.dataset_id}-${binding.role}" => binding }
  project    = each.value.project
  dataset_id = each.value.dataset_id
  role       = each.value.role
  members    = each.value.members
}

resource "google_project_iam_binding" "project_roles" {
  for_each = { for binding in local.project_bindings : "${binding.project}-${binding.role}" => binding }
  project  = each.value.project
  role     = each.value.role
  members  = each.value.members
}


resource "google_service_account" "doris_vm_dev_sa" {
  project      = var.gcp_dev_project_id
  account_id   = "doris-vm-dev-sa"
  display_name = "Custom SA for Dev Doris VM Instance"
}

resource "google_compute_instance" "doris_vm_dev" {
  name         = var.gcp_projects_info[var.gcp_dev_project_id].vm_name
  machine_type = "e2-medium"
  zone         = var.gcp_project_region
  project      = var.gcp_dev_project_id
  tags         = [var.gcp_projects_info[var.gcp_dev_project_id].vm_name]

  scheduling {
    provisioning_model          = "SPOT"
    preemptible                 = "true"
    automatic_restart           = "false"
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
    foo      = "bar"
    ssh-keys = var.gcp_compute_engine_ssh_pub_key
  }
  allow_stopping_for_update = true
  metadata_startup_script   = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.doris_vm_dev_sa.email
    scopes = ["cloud-platform"]
  }
}

resource "google_project_iam_custom_role" "custom-delegates" {
  project     = var.gcp_dev_project_id
  role_id     = "CustomDelegate"
  title       = "Iceberg BQ Delegate"
  description = "Iceberg BQ Delegate"
  permissions = ["bigquery.connections.delegate"]
}

locals {
  flattened_bigquery_datasets = {
    for project_id, value in var.gcp_projects_info : project_id => lookup(value, "bigquery_datasets", null)
  }
  bigquery_datasets = flatten(
    [for project_id, value in local.flattened_bigquery_datasets :
      flatten(
        [for dataset_id, dataset_info in value :
          {
            "project_id"    = project_id
            "dataset_id"    = dataset_id
            "friendly_name" = dataset_info.friendly_name
          }
      ])
  ])
  bigquery_dataset_map = zipmap(
    [for i in range(length(local.bigquery_datasets)) : i],
    local.bigquery_datasets
  )
}

resource "google_bigquery_dataset" "datasets" {
  for_each      = local.bigquery_dataset_map
  project       = each.value.project_id
  dataset_id    = each.value.dataset_id
  friendly_name = each.value.friendly_name
  location      = var.gcp_project_location
  labels = {
    env = "dev"
  }
}

# Only create for dev project for now
resource "google_bigquery_connection" "bigspark_connection" {
  for_each      = var.gcp_projects_info
  project       = each.key
  connection_id = "bigspark-connection"
  location      = var.gcp_project_location
  spark {}
}

resource "google_bigquery_connection" "biglake_connection" {
  for_each      = var.gcp_projects_info
  project       = each.key
  connection_id = "biglake-connection"
  location      = var.gcp_project_location
  cloud_resource {}
}

