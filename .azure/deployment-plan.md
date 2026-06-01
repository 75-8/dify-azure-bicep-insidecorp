# Azure Deployment Plan (Skeleton)

- Project: dify-azure-bicep-insidecorp
- Created: 2026-06-02
- Author: GitHub Copilot (assistant)
- Status: Draft

## Purpose
このファイルは `azure-prepare` のフェーズ1プランを段階的に記録するためのスケルトンです。

---

## 0. Specialized Technology Check (STEP 0)
- [ ] Check prompt and repository markers for specialized skills (e.g., copilot-sdk)
- Result: TODO
 - Result: No Copilot SDK or `CopilotClient` markers found in repository. Continue with `azure-prepare`.

## 1. Analyze Workspace
- Goal: Determine if this is NEW, MODIFY, or MODERNIZE
- Findings: TODO
 - Findings: MODIFY — repo already contains infrastructure-as-code using Bicep under `infra/`.
	 - `infra/main.bicep` and `infra/modules/*` define Container Apps environment, PostgreSQL Flexible Server, Storage, Redis (conditional), and networking.

## 2. Gather Requirements
- Classification (dev/staging/prod): TODO
- Expected scale (instances, RUs, QPS): TODO
- Budget/constraints: TODO
 - Classification: `dev`
 - Azure subscription: parameterize (do not hardcode). The deployment will accept `subscriptionId` as a parameter or via deployment script.
 - Region: `japaneast` (default)
 - Expected scale: dev-scale (small instance counts; `acaAppMinCount` default 0/1)
 - Budget/constraints: cost-conscious. Avoid high-cost managed WAF solutions.
 - Security constraints and design decisions:
	 - Do not deploy Azure WAF (cost concerns).
	 - Use Network Security Groups (NSG) for subnet-level filtering.
	 - Use Application Gateway (AppGW) for TLS termination and routing (chosen over WAF for cost reasons).
	 - Protect Web UI via `oauth2-proxy` (fronting the web app) for authentication.
	 - Protect APIs via API Management (APIM) for rate-limiting, authentication and per-API policies.
	 - Secrets: use Key Vault; do NOT store secrets in parameter files committed to repo.

## 3. Scan Codebase
- Components discovered: TODO
- Languages, runtimes, frameworks: TODO
- Existing infra artifacts: infra/ (Bicep) present
 - Components discovered:
	 - Azure Container Apps environment (ACA) and app modules (`infra/modules/aca-env`)
	 - PostgreSQL Flexible Server (`infra/modules/postgresql.bicep`) with `dify` and `vector` DBs and `pgvector` extension
	 - Virtual Network and subnets (`infra/modules/network.bicep`)
	 - Storage account and file shares for `nginx`, `sandbox`, `ssrfproxy`, `pluginstorage`
	 - Optional Redis cache module (conditional on `isAcaEnabled`)
	 - Mountfiles for nginx, sandbox, ssrfproxy under `infra/mountfiles`
 - Languages/runtimes: infrastructure: Bicep; application images referenced (Docker images) — no app source files found in repo root.

## 4. Select Recipe
- Candidate recipes: AZD (default), Bicep, Terraform, AZCLI
- Recommendation: TODO
 - Recommendation: Use existing Bicep templates as primary IaC (keep `infra/`).
	 - Chosen recipe: **Bicep** (use and extend `infra/`).
	 - Rationale: project already contains mature Bicep templates; minimal churn and preserves existing modules.
	 - Optionally add `azure.yaml`/AZD metadata if the team wants `azd` developer workflow, but do NOT run `azd init -t` in-place without approval.

## 5. Plan Architecture
- Map components to Azure services (Container Apps, PostgreSQL, Redis, Storage, VNet): TODO
- Security considerations: TODO
 - Architecture decisions (high level):
	 - Networking: VNet with subnets for ACA, Postgres, PrivateLink, protected by NSGs.
	 - Compute: Azure Container Apps environment (ACA) hosting Dify components (nginx, api, web, sandbox, plugin daemon).
	 - Data: PostgreSQL Flexible Server (with `dify` and `vector` DBs), Storage Account with file shares mounted into ACA.
	 - Cache: Azure Cache for Redis (optional; enabled by `isAcaEnabled`).
	 - Ingress: Application Gateway in front of ACA edge runtime for TLS termination and routing to public services.
	 - API Gateway: Azure API Management for API exposure, policy enforcement, rate-limiting, and auth integration.
	 - Auth: `oauth2-proxy` protecting Web UI; APIM protects APIs and integrates with identity provider.
 - Security considerations:
	 - Use NSGs on subnets to restrict ingress from allowed CIDRs and corporate IP ranges.
	 - Use Private Endpoints / Private DNS for PostgreSQL and Storage where possible.
	 - Store certificates and secrets in Key Vault; reference securely in Bicep using secure parameters or Key Vault references.
	 - Minimize public surface area; only expose required ports through AppGW.

	 - APIM approach: Implementation deferred due to implementation cost. Plan and preparatory artifacts will be created now to reduce future implementation effort:
		 - Record API interfaces and required policies in `infra/docs/apim-plan.md` (endpoints, auth, rate limits, CORS, policies).
		 - Provide a lightweight placeholder Bicep module `infra/modules/apim-placeholder.bicep` that declares an APIM service resource with minimal settings disabled by default (deployment gated by a parameter `deployApim`).
		 - Wire networking and NSG rules to allow future APIM's backend connectivity (private endpoints / VNet integration) where applicable.
		 - Document integration steps with Key Vault and identity provider (OIDC) for APIM in the plan.
		 - Do NOT enable or deploy APIM in this run unless explicitly requested.

## 6. Finalize Plan
- Consolidate decisions from steps 1-5
- Mark `Status:` to `Ready for Validation` when ready

## Current Status / Next Actions
- Status: Draft — plan updated with user requirements and architecture decisions.
- Next actions (Phase 1→Phase 2 prep):
	1. Add a parameter for `subscriptionId` to the deployment process and document how to pass it (deployment script / `az deployment` arguments). Do not embed subscription ID in repo files.
	2. Update `infra/` Bicep modules to include NSG and Application Gateway resources or add new modules for AppGW and NSG wiring; draft changes in a feature branch after plan approval.
	3. Add Key Vault integration pattern in Bicep modules and update `parameters.example.json` to point to secret references (placeholders only).
	4. Create APIM planning artifacts and a placeholder module (see APIM approach above). APIM implementation itself is deferred.
	5. Prepare `azure.yaml` metadata if the team requests `azd` developer experience (separate PR).
	6. After your approval, finalize this plan and mark `Status: Ready for Validation` so we can run `azure-validate`.

---

Please confirm if you want me to (A) draft the Bicep modules for AppGW/NSG and add Key Vault wiring now, or (B) only finalize the plan and stop before any code changes.

---

## Notes
- Follow `azure-prepare` skill: do not execute deployment commands. Invoke `azure-validate` after plan is Ready for Validation.
- Do NOT include secrets in plan. Use Key Vault and parameter files.


