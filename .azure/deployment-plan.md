# Azure Deployment Plan

> **Status:** Planning — blocked pending user requirements, Azure subscription, and region confirmation

Generated: 2026-06-02T00:00:00Z

---

## 1. Project Overview

**Goal:** Prepare the existing Dify-on-Azure Bicep repository for Azure deployment planning after the `/azure-prepare` workflow was invoked.

**Path:** Add Components / Modify Existing Azure Infrastructure

**Current repository state:** Existing Azure infrastructure-as-code project using subscription-scope Bicep modules under `infra/`. No new infrastructure, application code, Dockerfiles, or deployment configuration artifacts have been generated in this run because the plan must be approved before execution.

---

## 2. Requirements

| Attribute | Value |
|-----------|-------|
| Classification | Blocked until user confirms: POC, Development, or Production |
| Scale | Blocked until user confirms expected users/workload size |
| Budget | Blocked until user confirms Cost-Optimized, Balanced, or Performance |
| **Subscription** | Blocked: Azure CLI is not installed in this environment, and the user has not provided a subscription ID/name |
| **Location** | Default detected from Bicep/examples: `japaneast`; must be confirmed by user before execution |
| Compliance / policy constraints | Blocked until subscription is known and policy assignments can be queried |
| Network access posture | Existing documentation and parameter examples indicate corporate/private access intent via `allowedIngressCidrs` |

---

## 3. Components Detected

| Component | Type | Technology | Path |
|-----------|------|------------|------|
| Main deployment orchestration | Infrastructure | Bicep, subscription scope | `infra/main.bicep` |
| Network | Infrastructure | Azure Virtual Network / subnets | `infra/modules/network.bicep` |
| Network Security Groups | Infrastructure | Azure NSG | `infra/modules/nsg.bicep` |
| Storage | Infrastructure | Azure Storage account, blob container, Azure Files, private endpoints | `infra/modules/storage.bicep` |
| PostgreSQL | Data | Azure Database for PostgreSQL Flexible Server, databases, pgvector config | `infra/modules/postgresql.bicep` |
| Redis | Cache | Azure Cache for Redis, private endpoint | `infra/modules/redis-cache.bicep` |
| Container Apps environment | Compute platform | Azure Container Apps managed environment, Log Analytics, ACA storage mounts/certificate | `infra/modules/aca-env.bicep`, `infra/modules/aca-env/platform.bicep` |
| Dify application services | Compute | Azure Container Apps for Dify API, worker, web, sandbox, plugin daemon | `infra/modules/aca-env/application.bicep` |
| Dify edge services | Compute / ingress | Azure Container Apps for nginx and SSRF proxy | `infra/modules/aca-env/edge-runtime.bicep` |
| API Management | Optional gateway | Azure API Management / placeholder modules | `infra/modules/apim.bicep`, `infra/modules/apim-placeholder.bicep` |
| Application Gateway | Optional ingress | Azure Application Gateway | `infra/modules/appgw.bicep` |
| Key Vault | Optional secrets | Azure Key Vault modules | `infra/modules/keyvault.bicep`, `infra/modules/keyvaulte.bicep` |
| CI/CD | Pipeline | Azure Pipelines YAML | `pipelines/azure-pipeline-ci.yaml`, `pipelines/azure-pipeline-cd.yaml` |
| Documentation | Architecture/security docs | Markdown, YAML, draw.io | `README.md`, `docs/` |

---

## 4. Recipe Selection

**Selected:** Bicep

**Rationale:** The repository already contains subscription-scope Bicep infrastructure in `infra/main.bicep`, reusable Bicep modules under `infra/modules/`, example ARM deployment parameter files, and a PowerShell deployment script. Continuing with Bicep avoids converting existing user-authored IaC and preserves the repository’s documented deployment path.

---

## 5. Architecture

**Stack:** Containers on Azure Container Apps with managed Azure data services and private networking.

### Service Mapping

| Component | Azure Service | SKU / Sizing Source |
|-----------|---------------|---------------------|
| Dify nginx edge | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Dify web | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Dify API | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Dify worker | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Dify sandbox | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Dify SSRF proxy | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Dify plugin daemon | Azure Container Apps | Existing Bicep values; final min/max replicas must be confirmed |
| Container app hosting plane | Azure Container Apps managed environment | Existing Bicep module |
| Observability workspace | Log Analytics workspace | Existing Bicep module |
| Relational and vector data | Azure Database for PostgreSQL Flexible Server | Existing Bicep module; sizing must be reviewed for target environment |
| Cache/session state | Azure Cache for Redis | Existing Bicep module; enabled when `isAcaEnabled` is true |
| File/object storage | Azure Storage account, blob container, Azure Files | Existing Bicep module |
| Private connectivity | VNet, delegated subnets, private endpoints, private DNS zones | Existing Bicep modules |
| Optional API gateway | Azure API Management | Existing optional modules; enablement must be confirmed |
| Optional ingress tier | Azure Application Gateway | Existing optional module; enablement must be confirmed |
| Optional secrets boundary | Azure Key Vault | Existing optional modules; usage must be confirmed |

### Supporting Services

| Service | Purpose |
|---------|---------|
| Log Analytics | Centralized Container Apps logs |
| Private DNS zones | Name resolution for private endpoints |
| Private endpoints | Private access to Storage, PostgreSQL, and Redis where configured |
| Azure Pipelines | CI/CD automation scaffold |
| Key Vault | Optional secrets management boundary, pending confirmation and implementation review |

---

## 6. Provisioning Limit Checklist

**Purpose:** Validate that the selected subscription and region have sufficient quota/capacity for all resources to be deployed.

> **Current status:** Blocked. Azure CLI is not installed in this environment (`az: command not found`), no subscription was provided, and the user has not confirmed the deployment region. Quota validation cannot be completed until those inputs and tooling are available.

### Phase 1: Prepared Resource Inventory

| Resource Type | Number to Deploy | Total After Deployment | Limit/Quota | Notes |
|---------------|------------------|------------------------|-------------|-------|
| Microsoft.Resources/resourceGroups | 1 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Created by `infra/main.bicep` |
| Microsoft.Network/virtualNetworks | 1 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Detected in network module |
| Microsoft.Network/networkSecurityGroups | Existing module available | Blocked until deployment options confirmed | Blocked until subscription query succeeds | NSG module exists; final attachment/use should be reviewed |
| Microsoft.Storage/storageAccounts | 1 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Storage module creates one account plus child resources |
| Microsoft.Network/privateEndpoints | Multiple | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Storage, PostgreSQL, Redis private endpoint resources detected |
| Microsoft.Network/privateDnsZones | Multiple | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Storage, PostgreSQL, Redis private DNS zones detected |
| Microsoft.DBforPostgreSQL/flexibleServers | 1 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | PostgreSQL Flexible Server detected |
| Microsoft.Cache/Redis | 1 when Redis deployment condition is enabled | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Redis module is conditional through main deployment path |
| Microsoft.OperationalInsights/workspaces | 1 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | Log Analytics workspace for ACA environment |
| Microsoft.App/managedEnvironments | 1 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | ACA managed environment detected |
| Microsoft.App/containerApps | 7 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | nginx, ssrf proxy, sandbox, worker, api, plugin daemon, web |
| Microsoft.App/managedEnvironments/storages | 4 | Blocked until subscription query succeeds | Blocked until subscription query succeeds | ACA storage mounts for nginx, ssrf proxy, sandbox, plugin storage |
| Microsoft.App/managedEnvironments/certificates | 0 or 1 | Blocked until certificate option confirmed | Blocked until subscription query succeeds | Conditional when `isProvidedCert` is true |
| Microsoft.ApiManagement/service | 0 or 1 | Blocked until APIM option confirmed | Blocked until subscription query succeeds | Optional APIM modules present |
| Microsoft.Network/applicationGateways | 0 or 1 | Blocked until App Gateway option confirmed | Blocked until subscription query succeeds | Optional Application Gateway module present |
| Microsoft.KeyVault/vaults | 0 or 1 | Blocked until Key Vault option confirmed | Blocked until subscription query succeeds | Optional Key Vault modules present |

### Phase 2: Fetch Quotas and Validate Capacity

Quota validation is not complete. Required next actions:

1. Install or provide an environment with Azure CLI and Bicep support.
2. Confirm Azure subscription ID/name.
3. Confirm Azure region, currently inferred as `japaneast` from repository defaults.
4. Query provider quotas and current usage for each resource type in the inventory.
5. Update this section with actual current usage, limits, and pass/warn/fail capacity status before execution.

**Status:** Blocked pending Azure context and tooling.

---

## 7. Execution Checklist

### Phase 1: Planning
- [x] Create initial deployment plan skeleton
- [x] Analyze workspace
- [ ] Gather missing requirements from user
- [ ] Confirm subscription and location with user
- [x] Prepare resource inventory
- [ ] Fetch quotas and validate capacity
- [x] Scan codebase
- [x] Select recipe
- [x] Plan architecture based on existing repository
- [ ] Present complete quota-validated plan to user
- [ ] **User approved this plan**

### Phase 2: Execution
- [ ] Research components and service-specific references
- [ ] Generate or modify infrastructure/configuration only after plan approval
- [ ] Harden security based on approved target environment
- [ ] Functional verification, where applicable
- [ ] **Update plan status to `Ready for Validation` before azure-validate hand-off**

### Phase 3: Validation
- [ ] Invoke azure-validate skill after preparation execution
- [ ] All validation checks pass
- [ ] Update plan status to `Validated`
- [ ] Record validation proof below

### Phase 4: Deployment
- [ ] Invoke azure-deploy skill only after validation
- [ ] Deployment successful
- [ ] Report deployed endpoint URLs
- [ ] Update plan status to `Deployed`

---

## 8. Validation Proof

> **Required:** The azure-validate workflow must populate this section before setting status to `Validated`.

| Check | Command Run | Result | Timestamp |
|-------|-------------|--------|-----------|
| Azure CLI availability | `az account show --query '{name:name,id:id,tenantId:tenantId}' -o json` | ⚠️ Blocked: `az` not installed | 2026-06-02T00:00:00Z |
| Bicep build availability | `az bicep build --file infra/main.bicep` | ⚠️ Blocked: `az` not installed | 2026-06-02T00:00:00Z |
| Standalone Bicep CLI availability | `bicep build infra/main.bicep` | ⚠️ Blocked: `bicep` not installed | 2026-06-02T00:00:00Z |

**Validated by:** Not yet validated; azure-validate has not been invoked.

---

## 9. Files to Generate or Modify

| File | Purpose | Status |
|------|---------|--------|
| `.azure/deployment-plan.md` | Mandatory planning source of truth | ✅ Created/updated in this run |
| `azure.yaml` | AZD configuration | Not planned; repository uses Bicep/deploy script today |
| `infra/main.bicep` | Main infrastructure | Existing; no change made in this run |
| `infra/modules/**/*.bicep` | Reusable infrastructure modules | Existing; no change made in this run |
| `src/{component}/Dockerfile` | Container build files | Not applicable; existing plan uses upstream Dify images |

---

## 10. Questions Required Before Execution

1. What target classification should this deployment use: POC, Development, or Production?
2. What Azure subscription ID/name should be used?
3. Should the deployment region remain `japaneast`, or should it use another Azure region?
4. What corporate ingress CIDR ranges should be allowed?
5. Should optional APIM, Application Gateway, Key Vault, and bring-your-own-certificate paths be enabled?
6. What scale and budget profile should drive PostgreSQL, Redis, Container Apps, and monitoring sizing?

---

## 11. Next Steps

> Current: Phase 1 Planning is partially complete and blocked before approval/execution.

1. User provides requirements and Azure context listed above.
2. Quota checks are run in an Azure CLI-enabled environment.
3. The completed, quota-validated plan is presented for approval.
4. Only after approval, infrastructure/configuration changes are executed.
