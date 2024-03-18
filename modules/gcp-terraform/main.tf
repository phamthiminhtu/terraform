data "google_project" "project" {
}

locals {
  key_specs = [
    {
        "key_name" : "env",
        "description" : "Environment"
    },
    {
        "key_name" : "source",
        "description" : "source"
    }
  ]
}

resource "google_tags_tag_key" "key" {
  parent = "projects/${data.google_project.project.number}"
  for_each = { for val_desc in local.key_specs : val_desc.key_name => val_desc }
  short_name = each.value.key_name
  description = each.value.description
}

locals {
  value_specs = [
      {   
          "parent_key_id" : "281478389885499",
          "value" : "source_value_1",
          "value_id": "281479755284307",
          "description" : "source_value_1",
          "tag_binding": "//cloudresourcemanager.googleapis.com/projects/${data.google_project.project.number}"
      },
      {   
          "parent_key_id" : "281475978701827",
          "value" : "env_value_1",
          "value_id": "281476537547913",
          "description" : "env_value_1",
          "tag_binding": "//cloudresourcemanager.googleapis.com/projects/${data.google_project.project.number}"
      },
  ]
}

# Create Tags Values for Key
resource "google_tags_tag_value" "value" {
  for_each    = { for val_desc in local.value_specs : val_desc.value => val_desc }
  parent      = "tagKeys/${each.value.parent_key_id}"
  short_name  = each.value.value
  description = each.value.description
}

# Create Tags Binding
resource "google_tags_location_tag_binding" "binding" {
  for_each    = { for val_desc in local.value_specs : val_desc.value => val_desc }
  parent    = each.value.tag_binding
  tag_value = "tagValues/${each.value.value_id}"
}