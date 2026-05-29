# Terraform Generation

Generate Terraform only after `meta.status` is `approved`.

## Rules

- Place Terraform files under `/infra/`.
- Split provider, variables, main resources, outputs, and environment tfvars where useful.
- Avoid storing secrets in `.tfvars`; use Key Vault, environment variables, or secure CI variables.
- Run `terraform fmt`, `terraform init`, `terraform validate`, and `terraform plan` before deployment.
