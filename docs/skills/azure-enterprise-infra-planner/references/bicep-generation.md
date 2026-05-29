# Bicep Generation

Generate Bicep only after `meta.status` is `approved`.

## Rules

- Place Bicep files under `/infra/`.
- Use parameters for environment-specific values and secure parameters for secrets.
- Use managed identities and Key Vault references rather than hardcoded credentials.
- Generate modules for repeatable resource groups or resource families.
- Validate with `az bicep build` before presenting deployment commands.
