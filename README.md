# Cloud Infrastructure

This repository provisions a small AWS footprint with Terraform. The live Terraform root is `src`, environment-specific values live under `environments`, and the helper scripts wrap Terraform with the correct paths.

## Layout

```text
cloud-infra/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── scripts/
└── src/
    ├── backend.tf
    ├── main.tf
    ├── outputs.tf
    ├── provider.tf
    ├── variables.tf
    └── modules/
```

## What It Creates

- A VPC with public and private subnets.
- A security group for the EC2 instance.
- An EC2 instance using the latest Amazon Linux 2023 AMI available in the selected region.
- An S3 bucket for application storage with versioning, server-side encryption, and public access blocking enabled.

## Prerequisites

- Terraform 1.5 or newer.
- AWS CLI configured with credentials that can manage the target resources.
- An existing S3 bucket and DynamoDB table for remote Terraform state, referenced by `environments/<env>/backend.tfvars`.
- Bash. On Windows, Git Bash is the simplest option.

## Deploy With Scripts

From the repository root:

```bash
./scripts/deploy.sh -e dev
./scripts/deploy.sh -e staging -p
./scripts/deploy.sh -e prod -f
```

Destroy an environment:

```bash
./scripts/cleanup.sh -e dev
./scripts/cleanup.sh -e prod -f
```

`create.sh` is a thin wrapper around `deploy.sh`:

```bash
./scripts/create.sh dev
./scripts/create.sh staging --plan
```

## Run Terraform Manually

All Terraform commands should target the `src` directory.

```bash
terraform -chdir=src init -backend-config=../environments/dev/backend.tfvars
terraform -chdir=src workspace select dev || terraform -chdir=src workspace new dev
terraform -chdir=src validate
terraform -chdir=src fmt -recursive
terraform -chdir=src plan -var-file=../environments/dev/terraform.tfvars
terraform -chdir=src apply -var-file=../environments/dev/terraform.tfvars
```

## Environment Variables

Each `environments/<env>/terraform.tfvars` file now defines:

- `aws_region`
- `vpc_cidr`
- `public_subnet_cidrs`
- `private_subnet_cidrs`
- `instance_type`
- `bucket_name_prefix`
- `ssh_ingress_cidrs`

`bucket_name_prefix` is a prefix, not a full name. Terraform uses it to create a stable, globally unique bucket name on first apply.

## Notes

- Review `ssh_ingress_cidrs` before using this outside a test environment. The sample values currently allow SSH from anywhere.
- The backend state bucket is separate from the application storage bucket created by this stack.
- The root-level `terraform.tfvars` file is only a reference example. The deployment scripts use the environment-specific tfvars under `environments/`.

## Troubleshooting

State lock issue:

```bash
terraform -chdir=src force-unlock <LOCK_ID>
```

Re-check formatting and validation:

```bash
terraform -chdir=src fmt -check -recursive
terraform -chdir=src validate
```
```
- Stanley - [@574n13y](https://github.com/574n13y)
```

## Usage Guidelines

- Use the `src/modules/example-module` directory to create reusable modules for your infrastructure components.
- Customize the input variables in `variables.tf` and `terraform.tfvars` as needed for your environment.
- Review the output values defined in `outputs.tf` to understand the resources created after applying the configuration.

