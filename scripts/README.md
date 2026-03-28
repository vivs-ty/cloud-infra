# Script Usage

The scripts resolve the repository paths themselves and always run Terraform from the `src` directory.

Basic deployment:

```bash
./scripts/deploy.sh -e dev
```

Plan only:

```bash
./scripts/deploy.sh -e staging -p
./scripts/create.sh staging --plan
```

Force production apply:

```bash
./scripts/deploy.sh -e prod -f
```

Cleanup:

```bash
./scripts/cleanup.sh -e dev
./scripts/cleanup.sh -e prod -f
```

Requirements:

- AWS CLI credentials must already be configured.
- The remote state bucket and DynamoDB lock table referenced by `environments/<env>/backend.tfvars` must already exist.
- Review `ssh_ingress_cidrs` in each environment tfvars before deploying outside a test environment.
