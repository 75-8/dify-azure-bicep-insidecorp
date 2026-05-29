# Verification

Run verification before IaC generation and again before deployment.

## Plan verification

- Validate `/.azure/infra-plan.json` against [schema.md](schema.md).
- Check each resource against [resources/](resources/README.md).
- Check incompatible combinations against [constraints/](constraints/README.md).
- Confirm WAF coverage with [waf-checklist.md](waf-checklist.md).

## IaC verification

- Bicep: run `az bicep build --file <file>` and, where possible, `az deployment group what-if`.
- Terraform: run `terraform fmt`, `terraform init`, `terraform validate`, and `terraform plan`.
- Ensure generated files are under `/infra/` and parameter files do not contain secrets.
