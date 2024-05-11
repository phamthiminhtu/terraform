# provider "google" {
#   credentials = file("credentials/terraform-417520-b244cdfcb327.json")
#   project = "terraform-417520"
#   region = "australia-southeast1"
# }

provider "google" {
  credentials = file("credentials/kafka-408805-a71c410a3bb6.json")
  project = "kafka-408805"
}

data "google_project" "dev_project" {
  # provider = google.kafka
}

# data "google_project" "prod_project" {
#   provider = google
# }


locals {
  tags = {
    "environment" = [
      # { "prod" : (data.google_project.prod_project.number) },
      { "dev" : (data.google_project.dev_project.number) },
    ],
    "system-id" = [
      # { "tototus" : (data.google_project.prod_project.number) },
      { "tototus" : (data.google_project.dev_project.number) },
    ]
  }
}

locals {
  helper_list = flatten([
    for tag_short_name, values in local.tags : [
      for value in values : [
        for tag_value, project_number in value : {
          "tag_short_name" = tag_short_name
          "tag_value"      = tag_value
          "project_number" = project_number
    }]]
  ])
}


resource "google_tags_tag_key" "key" {
  for_each    = { for idx, record in local.helper_list : idx => record }
  parent      = "projects/${each.value.project_number}"
  short_name  = each.value.tag_short_name
  description = "For ${each.value.tag_short_name} resources."
}

# Create Tags Values for Key
resource "google_tags_tag_value" "value" {
  for_each    = { for idx, record in local.helper_list : idx => record }
  parent      = "tagKeys/${google_tags_tag_key.key[each.key].name}"
  short_name  = each.value.tag_value
  description = each.value.tag_value
}

# Create Tags Binding
resource "google_tags_tag_binding" "binding" {
  for_each  = { for idx, record in local.helper_list : idx => record }
  parent    = "//cloudresourcemanager.googleapis.com/projects/${each.value.project_number}"
  tag_value = "tagValues/${google_tags_tag_value.value[each.key].name}"
}
