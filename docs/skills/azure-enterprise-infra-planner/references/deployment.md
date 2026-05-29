# Deployment

Deployment is optional and requires explicit user confirmation, especially for destructive or cost-incurring changes.

## Bicep

Use `az deployment group create` or subscription-scope deployment commands that match the plan scope. Prefer `what-if` before create.

## Terraform

Use `terraform plan` first, review changes, and run `terraform apply` only after confirmation.

## Post-deployment

Capture outputs, verify health probes, confirm diagnostics, and document rollback steps.
