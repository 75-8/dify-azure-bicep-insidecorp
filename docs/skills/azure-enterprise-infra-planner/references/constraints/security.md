# Security

## Common resources

- Key Vault (`Microsoft.KeyVault/vaults`)
- Managed Identity (`Microsoft.ManagedIdentity/userAssignedIdentities`)
- Role Assignments (`Microsoft.Authorization/roleAssignments`)
- Policy Assignments (`Microsoft.Authorization/policyAssignments`)

## Planning notes

- Prefer managed identities, least-privilege roles, private endpoints, and purge protection.
- Keep secrets out of parameter files and Terraform variables.
- Define audit logging, key rotation, and compliance controls.
