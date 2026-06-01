# Compute (PaaS)

## Common resources

- App Service Plan and App Service (`Microsoft.Web/serverfarms`, `Microsoft.Web/sites`)
- Function App (`Microsoft.Web/sites`)
- Container Apps and Container Apps Environment (`Microsoft.App/containerApps`, `Microsoft.App/managedEnvironments`)
- Azure Container Registry (`Microsoft.ContainerRegistry/registries`)
- Static Web Apps (`Microsoft.Web/staticSites`)

## Planning notes

- Match compute SKU, scale, and zone support to workload requirements.
- Use managed identities for Key Vault, registry, storage, and database access.
- Confirm VNet integration, private ingress, diagnostics, and health probes.
