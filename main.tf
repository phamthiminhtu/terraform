provider "google" {
  credentials = file("credentials/terraform-417520-b244cdfcb327.json")
  project = "terraform-417520"
  region = "australia-southeast1"
}

provider "google" {
  credentials = file("credentials/kafka-408805-03c2c1a6eb65.json")
  alias  = "kafka"
  project = "kafka-408805"
  region = "australia-southeast1"
}

module "gcp-terraform" {
  source = "./modules/gcp-terraform"
}
