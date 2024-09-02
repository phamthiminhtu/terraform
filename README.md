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

## CICD Flow:
1. Local changes
2. Pull request
3. GitHub Action is triggered: `Google Authentication` `terraform plan`, etc. 
  ![image](https://github.com/user-attachments/assets/7e41840e-7266-42f1-90df-56336ad8db29)
4. GitHub Action runs `terraform apply` when the PR is merged
  ![image](https://github.com/user-attachments/assets/3a0039a6-cb43-4cff-ba8b-57df6d622df3)


