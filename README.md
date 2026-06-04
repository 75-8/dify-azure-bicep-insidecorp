# dify-azure-bicep

Deploy [langgenius/dify](https://github.com/langgenius/dify), an LLM-based chat bot application on Azure with Bicep infrastructure-as-code.

> **Note**: This repository uses Bicep to provision Dify on Azure. The upstream Dify container image tags are referenced from `docker-compose-template.yaml`.

## Table of Contents

- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Architecture Overview](#architecture-overview)
- [Security Notice](#%EF%B8%8F-security-notice)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- PowerShell (for deployment script)

### Deploy in 4 Steps

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Copy and configure parameters**:
   ```bash
   # Choose dev or prd environment
   cp infra/parameters/parameters_dev.example.json infra/parameters.json
   
   # Edit infra/parameters.json with your secure passwords and configuration
   # ⚠️ See Security Notice below for required password changes
   ```

3. **Review parameters**:
   - Edit `infra/parameters.json` with your environment-specific values
   - Ensure strong passwords for `pgsqlPassword` and `acaCertPassword`
   - See [Parameter Reference](#parameter-reference) for details

4. **Deploy**:
   ```bash
   ./infra/deploy.ps1
   ```

## Documentation

This repository contains comprehensive documentation organized in `docs/`:

| Document | Purpose |
|----------|---------|
| [docs/architecture.md](docs/architecture.md) | System architecture diagram and component relationships |
| [docs/directory.md](docs/directory.md) | Repository structure and file organization |
| [docs/spec/](docs/spec/) | Domain-specific design specifications (network, auth, API, AOAI, ACA, DB, secrets) |
| [docs/spec/spec.md](docs/spec/spec.md) | Specification index and module mapping |
| [docs/test/](docs/test/) | Test plans and validation procedures |
| [docs/cost/](docs/cost/) | Cost estimation resources |

**Start here**: [docs/directory.md](docs/directory.md) provides a complete overview of the repository structure.

## Architecture Overview

The Dify deployment consists of:

- **Frontend**: nginx (reverse proxy + OAuth2 auth) in Azure Container Apps
- **Backend**: API, web, worker, sandbox, and plugin services in Azure Container Apps
- **Database**: PostgreSQL Flexible Server (with pgvector)
- **Cache**: Azure Cache for Redis
- **Storage**: Azure Storage Account (Blob + File Share)
- **Ingress**: Application Gateway (public endpoint)
- **Networking**: VNet with subnets, NSGs, and private endpoints
- **Secrets**: Azure Key Vault for sensitive configuration

**Detailed Design**: See [docs/spec/spec.md](docs/spec/spec.md) for end-to-end design and [docs/architecture.md](docs/architecture.md) for visual diagrams.

### Key Features

- **Network Isolation**: Corporate network access only (configurable via `allowedIngressCidrs`)
- **Authentication**: Entra ID (Azure AD) integration via OAuth2 Proxy
- **Data Security**: Private endpoints, disabled public network access, encrypted storage
- **Infrastructure as Code**: Fully automated Bicep deployment with parameter-driven configuration

### Bicep Variables Documentation

This document provides detailed descriptions of the variables used in the Bicep configuration for setting up the Dify environment.

## ⚠️ Security Notice

**CRITICAL**: The `infra/parameters.json` file contains sensitive information including:
- Database password (`pgsqlPassword`)
- Certificate password (`acaCertPassword`, if using custom certificate)

### Before Deploying

1. **Generate strong passwords**: Use a password manager or generate with:
   ```bash
   # Generate 16-char password with uppercase, lowercase, numbers, and symbols
   openssl rand -base64 12 | tr -d '=' | fold -w 16 | head -1
   ```

2. **Edit** `infra/parameters.json`:
   - Replace `pgsqlPassword` with a strong password (min 8 chars: uppercase, lowercase, numbers)
   - If `isProvidedCert` is `true`, replace `acaCertPassword` with your certificate password

3. **Never commit** `infra/parameters.json` to version control (already in `.gitignore`)

4. **Network Access**: By default, only traffic from `10.0.0.0/8` is allowed. Update `allowedIngressCidrs` in parameters to match your corporate network CIDR.

### Production Recommendations

- Use strong passwords unique to each environment
- Store secrets in a password manager
- Consider using Azure Key Vault references instead of direct parameters
- Regularly audit network policies and RBAC assignments
- See [docs/security_guardrails.md](docs/security_guardrails.md) for additional security hardening options

## Parameter Reference

The deployment uses parameters defined in `infra/main.bicep`. Key parameters include:

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| `location` | string | `japaneast` | Azure region for deployment |
| `resourceGroupPrefix` | string | `rg` | Prefix for resource group naming |
| `ipPrefix` | string | `10.99` | CIDR prefix for VNet (10.99.0.0/16) |
| `pgsqlPassword` | securestring | *(required)* | PostgreSQL admin password |
| `acaCertBase64Value` | securestring | `` | Custom certificate (Base64) if `isProvidedCert=true` |
| `acaCertPassword` | securestring | `` | Certificate password if `isProvidedCert=true` |
| `acaDifyCustomerDomain` | string | `dify.example.com` | Custom domain (if `isProvidedCert=false`) |
| `allowedIngressCidrs` | array | `['10.0.0.0/8']` | Allowed source IPs for nginx ingress |
| `difyApiImage` | string | `langgenius/dify-api:1.13.3` | Dify API container image |
| `difyWebImage` | string | `langgenius/dify-web:1.13.3` | Dify web UI container image |
| `difySandboxImage` | string | `langgenius/dify-sandbox:0.2.14` | Dify sandbox container image |
| `oauth2ProxyClientId` | string | *(required)* | Entra App Registration client ID for OAuth2 |
| `oauth2ProxyTenantId` | string | *(required)* | Azure Entra tenant ID |

**For detailed parameter documentation**, see [docs/spec/80_bicep.md](docs/spec/80_bicep.md) and review `infra/main.bicep` parameter descriptions.

## Project Structure

```
dify-azure-bicep-insidecorp/
├── README.md                          # This file
├── infra/
│   ├── main.bicep                     # Root Bicep template (subscription scope)
│   ├── deploy.ps1                     # Deployment script
│   ├── parameters/
│   │   ├── parameters_dev.example.json
│   │   └── parameters_prd.example.json
│   └── modules/                       # Reusable Bicep modules
│       ├── network.bicep
│       ├── nsg.bicep
│       ├── appgw.bicep
│       ├── keyvault.bicep
│       ├── aca-env.bicep
│       ├── postgresql.bicep
│       ├── redis-cache.bicep
│       ├── storage.bicep
│       └── apim.bicep
├── docs/
│   ├── architecture.md                # System architecture and diagrams
│   ├── directory.md                   # Repository structure details
│   ├── spec/                          # Design specifications
│   │   ├── spec.md                    # Index and module mapping
│   │   ├── 10_network.md              # VNet, subnets, NSG design
│   │   ├── 15_appgw.md                # Application Gateway design
│   │   ├── 20_auth.md                 # Authentication (OAuth2, Entra ID)
│   │   ├── 30_api.md                  # API Management design
│   │   ├── 40_aoai.md                 # Azure OpenAI integration
│   │   ├── 50_aca.md                  # ACA and container configuration
│   │   ├── 60_db.md                   # Database and storage design
│   │   ├── 70_secret.md               # Key Vault and secrets
│   │   └── 80_bicep.md                # Bicep template structure
│   ├── test/                          # Test plans and validation
│   └── cost/                          # Cost estimation
└── pipelines/                        # CI/CD pipeline definitions
    ├── azure-pipeline-ci.yaml
    └── azure-pipeline-cd.yaml
```

## Troubleshooting

### Common Issues

#### Deployment Fails with Permission Error

**Symptom**: `User does not have permission to create resource`

**Solution**:
1. Verify your Azure account has `Contributor` or `Owner` role on the subscription
2. Run `az login --use-device-code` if having authentication issues
3. Check that your subscription is active: `az account show`

#### Parameters Validation Errors

**Symptom**: `Invalid value for 'ipPrefix'` or password requirement errors

**Solution**:
1. Review `infra/parameters.json` against [Parameter Reference](#parameter-reference)
2. Ensure passwords meet requirements (8+ chars, uppercase, lowercase, numbers)
3. Verify `oauth2ProxyClientId` and `oauth2ProxyTenantId` are correctly set

#### Certificate Issues

**Symptom**: `Certificate password incorrect` or `Certificate format invalid`

**Solution**:
1. If `isProvidedCert=false`, ensure `acaDifyCustomerDomain` is set correctly
2. If `isProvidedCert=true`, verify certificate is Base64 encoded: `base64 -w 0 certificate.pfx`
3. Double-check certificate password

#### Application Gateway Returns 502 Bad Gateway

**Symptom**: Browser shows `502 Bad Gateway` when accessing Dify through App Gateway

**Diagnosis & Solution**:

1. **Check nginx container is healthy**:
   ```bash
   az containerapp show --resource-group rg-dify-japaneast --name nginx \
     --query "properties.template.containers[0].image"
   ```
   - Verify the nginx image is correct and container is running

2. **Check health probe responses**:
   ```bash
   # Inside nginx container pod
   az containerapp exec --resource-group rg-dify-japaneast --name nginx \
     --command "curl http://localhost:4180/oauth2/ping"
   # Expected: 200 OK response
   ```
   - If probe fails, check oauth2-proxy sidecar logs

3. **Verify App Gateway backend pool configuration**:
   ```bash
   az network application-gateway backend-address-pool list \
     --resource-group rg-dify-japaneast \
     --gateway-name dify-appgw
   ```
   - Confirm FQDN matches nginx Container App internal domain (`nginx.<default-domain>`)

4. **Check NSG rules between App Gateway and ACA subnets**:
   ```bash
   # Verify inbound rule on nsg-aca allows AppGwSubnet → port 4180
   az network nsg rule list --resource-group rg-dify-japaneast --nsg-name nsg-aca \
     --query "[?properties.destinationPortRange=='4180']"
   ```

5. **Review logs**:
   ```bash
   # Container Apps logs
   az containerapp logs show --resource-group rg-dify-japaneast --name nginx \
     --tail 50
   
   # oauth2-proxy specific logs
   az containerapp exec --resource-group rg-dify-japaneast --name nginx \
     --command "cat /proc/$(pidof oauth2-proxy)/fd/1"
   ```

#### OAuth2 Proxy Authentication Not Working

**Symptom**: Redirected to Entra login but authentication fails or stuck in loop

**Diagnosis & Solution**:

1. **Verify Entra App Registration Configuration**:
   - Check Redirect URI matches exactly: `https://<your-domain>/oauth2/callback`
   - Ensure "API permissions" include `openid`, `profile`, `email` scopes

2. **Check OAuth2 Proxy environment variables in Container App**:
   ```bash
   az containerapp show --resource-group rg-dify-japaneast --name nginx \
     --query "properties.template.containers[] | [?name=='oauth2-proxy'].env"
   ```
   - Verify `OAUTH2_PROXY_OIDC_ISSUER_URL` is `https://login.microsoftonline.com/<tenant-id>/v2.0`
   - Ensure `OAUTH2_PROXY_REDIRECT_URL` matches Entra redirect URI

3. **Test Entra connectivity from Container App**:
   ```bash
   az containerapp exec --resource-group rg-dify-japaneast --name nginx \
     --command "curl -I https://login.microsoftonline.com/<tenant-id>/v2.0/.well-known/openid-configuration"
   # Should return 200 OK
   ```

4. **Check NSG allows outbound to Microsoft Entra**:
   ```bash
   # nsg-aca should allow outbound HTTPS (443) to internet
   az network nsg rule list --resource-group rg-dify-japaneast --nsg-name nsg-aca \
     --query "[?properties.access=='Allow' && properties.direction=='Outbound' && contains(properties.destinationPortRange, '443')]"
   ```

5. **Review oauth2-proxy logs**:
   ```bash
   az containerapp exec --resource-group rg-dify-japaneast --name nginx \
     --command "grep -i 'oauth\|auth' /dev/stderr"
   ```

#### Network Connectivity Issues (NSG or Firewall)

**Symptom**: Services cannot reach database/cache/storage (timeout or connection refused)

**Diagnosis**:

1. **Check NSG rules for private link subnet**:
   ```bash
   az network nsg rule list --resource-group rg-dify-japaneast --nsg-name nsg-privatelink
   ```
   - Verify inbound allows ACA subnet (10.99.2.0/23) on ports 443 (key vault, storage, redis), 5432 (postgres)

2. **Verify Private Endpoint DNS resolution**:
   ```bash
   # From ACA pod
   az containerapp exec --resource-group rg-dify-japaneast --name api \
     --command "nslookup dify-kv.vault.azure.net"
   # Should resolve to private IP (10.99.0.x)
   ```

3. **Test connectivity from Container App**:
   ```bash
   # PostgreSQL
   az containerapp exec --resource-group rg-dify-japaneast --name api \
     --command "nc -zv <postgres-fqdn> 5432"
   
   # Redis (if TLS enabled)
   az containerapp exec --resource-group rg-dify-japaneast --name api \
     --command "openssl s_client -connect <redis-fqdn>:6379"
   ```

#### Database or Redis Connection Failures

**Symptom**: API/worker fails with `could not connect to server` or `Connection refused`

**Solution**:
1. Verify database/cache is running: `az postgres server show`, `az redis show`
2. Check firewall/network rules allow Container App subnet
3. Verify connection strings in Container App environment variables
4. For PostgreSQL with SSL: ensure minimum TLS version compatibility
5. Review Container App logs for detailed error messages

#### File Share Upload Issues

**Symptom**: `deploy.ps1` fails during mount file uploads

**Solution**:
1. Ensure `infra/mountfiles/` directory structure exists and has expected files
2. Verify storage account allows file share uploads (firewall rules)
3. Check SAS token or storage key has correct permissions
4. If using azcopy, ensure it is installed: `azcopy --version`
5. Fall back to `az CLI` by temporarily disabling azcopy in `deploy.ps1`

### Getting Help

1. **Check design specs**: Review relevant section in [docs/spec/](docs/spec/)
2. **Test plan**: Consult [docs/test/](docs/test/) for validation procedures
3. **Architecture questions**: See [docs/architecture.md](docs/architecture.md)
4. **Security & secrets**: See [docs/security-implementation-guide.md](docs/security-implementation-guide.md)

### Operational Runbook

#### Post-Deployment Validation

After successful deployment, perform the following checks:

1. **Access Dify UI**:
   ```bash
   # Get App Gateway public IP
   APP_GW_IP=$(az network public-ip show \
     --resource-group rg-dify-japaneast \
     --name dify-appgw-pip \
     --query ipAddress -o tsv)
   
   # Open browser to https://$APP_GW_IP
   # Should redirect to Entra login
   ```

2. **Verify all Container Apps are healthy**:
   ```bash
   az containerapp list --resource-group rg-dify-japaneast \
     --query "[].{name:name, state:properties.runningStatus.state}"
   # All should show "Running"
   ```

3. **Confirm database connectivity**:
   ```bash
   # Test from API container
   az containerapp exec --resource-group rg-dify-japaneast --name api \
     --command "psql -h <postgres-fqdn> -U adminuser -d dify -c 'SELECT version();'"
   # Should display PostgreSQL version
   ```

4. **Check Redis connectivity**:
   ```bash
   # Test from API container
   az containerapp exec --resource-group rg-dify-japaneast --name api \
     --command "redis-cli -h <redis-fqdn> ping"
   # Should return "PONG"
   ```

#### Key Vault Secrets Management

For details on managing secrets with Key Vault, see [docs/security-implementation-guide.md](docs/security-implementation-guide.md).

#### NSG Rule Updates (Breaking Changes Prevention)

Before modifying NSG rules:

1. **Document current rules**:
   ```bash
   az network nsg rule list --resource-group rg-dify-japaneast --nsg-name nsg-aca --output table
   ```

2. **Test changes in dev environment first**

3. **Monitor for connection errors** after changes:
   ```bash
   az monitor metrics list --resource rg-dify-japaneast \
     --metric "NetworkPacketsDropped" --start-time 2026-06-05T00:00:00Z
   ```

4. **Revert if issues occur**:
   ```bash
   az network nsg rule update --resource-group rg-dify-japaneast \
     --nsg-name <nsg-name> --name <rule-name> --access Allow
   ```

#### Scaling and Performance Tuning

To increase Container App replicas:

```bicep
# In application.bicep or edge-runtime.bicep, adjust scale:
scale: {
  minReplicas: 2          # Increase from 1 to 2
  maxReplicas: 10         # Adjust based on load
  rules: [
    {
      name: 'cpu-scaling'
      custom: {
        metric: 'cpu'
        metadata: {
          type: 'Utilization'
          value: '80'
        }
      }
    }
  ]
}
```

Redeploy: `./infra/deploy.ps1`

## Development and Testing

Before deploying to production:

1. **Validate template**: 
   ```bash
   az bicep build --file infra/main.bicep
   ```

2. **Test deployment**:
   - Start with the dev parameters: `parameters_dev.example.json`
   - Use a test subscription if available
   - Monitor deployment in Azure Portal

3. **Run tests**: See [docs/test/test.md](docs/test/test.md) for test procedures

## Authentication Setup (Entra ID / OAuth2)

To enable Entra ID authentication:

1. **Create Entra App Registration**:
   - In Azure Portal: Azure AD > App Registrations > New Registration
   - Set Redirect URI: `https://your-domain/oauth2/callback`

2. **Configure in parameters**:
   - `oauth2ProxyClientId`: Application (client) ID
   - `oauth2ProxyClientSecret`: Client secret value
   - `oauth2ProxyTenantId`: Directory (tenant) ID

3. **See [docs/spec/20_auth.md](docs/spec/20_auth.md)** for detailed authentication architecture

## Cost Estimation

See [docs/cost/pricing_resources.yaml](docs/cost/pricing_resources.yaml) for estimated monthly costs by resource type.

## Contributing

When modifying the infrastructure:

1. Update the relevant spec document in `docs/spec/`
2. Update the corresponding Bicep module in `infra/modules/`
3. Document changes in `docs/` and update `docs/directory.md`
4. Test with both dev and prd parameter sets

## References

- [Dify Documentation](https://docs.dify.ai/)
- [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/)

## License

[Add license information if applicable]

---

**Last Updated**: June 2026  
**Maintained by**: Infrastructure Team
