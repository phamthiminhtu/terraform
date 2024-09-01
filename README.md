# terraform

This repo is to centralize the code that I used to create Cloud resources (only GCP up to now) for other personal projects using Terraform (Google Cloud Storage backend).

Project structure:
```
.
├── README.md
├── archive
│   └── main. tf
├── .github
│   └── workflows
│       ├── terraform.yml
├── main.tf
├── modules
│   └── gcp-terraform
│       ├── main.tf
│       └── variables.tf
├── snow.env
├── terraform.tfstate
├── terraform.tfstate.backup
├── terraform.tfvars
└── variables.tf
```

Project flow: 
```
Local changes
-> Pull request
-> GitHub Action runs Terraform commands (Google Cloud Storage backend)
-> `terraform apply` when the PR is merged
```
