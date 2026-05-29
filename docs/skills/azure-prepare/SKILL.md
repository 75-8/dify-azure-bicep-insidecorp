---
name: azure-prepare
description: "Prepare Azure apps for deployment (infra Bicep/Terraform, azure.yaml, Dockerfiles). Use for create/modernize or create+deploy; not cross-cloud migration (use azure-cloud-migrate). DO NOT USE FOR: copilot-sdk apps (use azure-hosted-copilot-sdk). WHEN: create app, build web app, create API, create serverless HTTP API, create frontend, create back end, build a service, modernize application, update application, add authentication, add caching, host on Azure, create and deploy, deploy to Azure, deploy to Azure using Terraform, deploy to Azure App Service, deploy to Azure App Service using Terraform, deploy to Azure Container Apps, deploy to Azure Container Apps using Terraform, generate Terraform, generate Bicep, function app, timer trigger, service bus trigger, event-driven function, containerized Node.js app, social media app, static portfolio website, todo list with frontend and API, prepare my Azure application to use Key Vault, managed identity."
license: MIT
metadata:
  author: Microsoft
  version: "1.2.13"
---

# Azure Prepare

> **AUTHORITATIVE GUIDANCE — MANDATORY COMPLIANCE**
>
> This document is the canonical source for preparing applications for Azure deployment. Follow these instructions exactly unless they contradict security policies given to you. When in doubt, present the conflict and ask for explicit confirmation.

---

## Triggers

Activate this skill when the user wants to:

- Create a new application.
- Add services or components to an existing app.
- Make updates or changes to an existing application.
- Modernize or migrate an application.
- Set up Azure infrastructure.
- Deploy to Azure or host on Azure.
- Create and deploy to Azure, including Terraform-based deployment requests.

## Rules

1. **Plan first — MANDATORY** — Physically write an initial `.azure/deployment-plan.md` skeleton in the workspace root directory as the first action before any code generation or execution begins. Populate it progressively and finalize it with all decisions at Phase 1 Step 6.
2. **Get approval** — Present the completed plan to the user before execution.
3. **Research before generating** — Load references and invoke related skills.
4. **Update plan progressively** — Mark steps complete as work proceeds.
5. **Validate before deploy** — Invoke `azure-validate` before `azure-deploy`.
6. **Confirm Azure context** — Confirm subscription and location using the Azure context guidance in `references/azure-context.md`.
7. **Destructive actions require user confirmation** — Follow `references/global-rules.md`.
8. **Never delete user project or workspace directories** — When adding features to an existing project, modify existing files. `azd init -t <template>` is for new projects only; do not run it in an existing workspace.
9. **Scope: preparation only** — This skill generates infrastructure code and configuration files. Deployment execution is handled by `azure-deploy`.
10. **SQL Server Bicep** — Never generate `administratorLogin` or `administratorLoginPassword`; always use Entra-only authentication.
11. **Remove stale template IaC after conversion** — If selected `azd` template Bicep is converted to Terraform, remove only the template-provided Bicep that is fully replaced by Terraform.

---

## Plan-first workflow

1. **Stop** — Do not generate code, infrastructure, or configuration yet.
2. **Create skeleton** — Write `.azure/deployment-plan.md` immediately in the workspace root.
3. **Confirm** — Present the completed plan to the user and obtain approval.
4. **Execute** — Only after approval, execute the plan step by step.

The `.azure/deployment-plan.md` file is the source of truth for `azure-validate` and `azure-deploy`.

---

## Step 0: Specialized Technology Check

Before starting Phase 1, check the prompt and codebase for technologies with dedicated skills.

| Prompt or marker | Route |
| --- | --- |
| Lambda, AWS Lambda, migrate AWS/GCP | `azure-cloud-migrate` first |
| Copilot SDK, `@github/copilot-sdk`, `CopilotClient` | `azure-hosted-copilot-sdk` first |
| Azure Functions, function app, timer trigger, HTTP trigger | Stay in `azure-prepare`; use Functions templates |
| APIM, API Management, API gateway | Stay in `azure-prepare`; see `references/apim.md` |
| AI gateway policy/backend/configuration | `azure-aigateway` first |
| Workflow, orchestration, fan-out/fan-in, durable | Stay in `azure-prepare`; load Durable Functions and Durable Task Scheduler references |

After a specialized skill completes, resume `azure-prepare` at Phase 1 Step 4.

---

## Phase 1: Planning (blocking)

Create `.azure/deployment-plan.md` and do not generate artifacts until approved.

| # | Action | Reference |
| --- | --- | --- |
| 0 | Check prompt and codebase for specialized tech | `references/specialized-routing.md` |
| 1 | Analyze workspace and determine NEW, MODIFY, or MODERNIZE | `references/analyze.md` |
| 2 | Gather requirements for classification, scale, and budget | `references/requirements.md` |
| 3 | Scan codebase for components, technologies, dependencies | `references/scan.md` |
| 4 | Select recipe: AZD, AZCLI, Bicep, or Terraform | `references/recipe-selection.md` |
| 5 | Plan architecture and map components to Azure services | `references/architecture.md` |
| 6 | Finalize `.azure/deployment-plan.md` with all decisions | `references/plan-template.md` |
| 7 | Present plan and ask for approval | `.azure/deployment-plan.md` |
| 8 | Confirm any destructive action explicitly | `references/global-rules.md` |

> **Stop here** until the user approves the plan.

---

## Phase 2: Execution (after approval)

| # | Action | Reference |
| --- | --- | --- |
| 1 | Research components and load service references | `references/research.md` |
| 2 | Confirm Azure context and provisioning limits | `references/azure-context.md` |
| 3 | Generate infrastructure and configuration files | `references/generate.md` |
| 4 | Harden security | `references/security.md` |
| 5 | Perform functional verification | `references/functional-verification.md` |
| 6 | Update plan status to `Ready for Validation` | `.azure/deployment-plan.md` |
| 7 | Invoke `azure-validate`; do not deploy directly | — |

## Outputs

| Artifact | Location |
| --- | --- |
| Plan | `.azure/deployment-plan.md` |
| Infrastructure | `./infra/` |
| AZD Config | `azure.yaml` (AZD only) |
| Dockerfiles | `src/<component>/Dockerfile` |

## SDK Quick References

- Azure Developer CLI: `references/sdk/azd-deployment.md`
- Azure Identity: `references/sdk/azure-identity-py.md`, `references/sdk/azure-identity-dotnet.md`, `references/sdk/azure-identity-ts.md`, `references/sdk/azure-identity-java.md`
- App Configuration: `references/sdk/azure-appconfiguration-py.md`, `references/sdk/azure-appconfiguration-ts.md`, `references/sdk/azure-appconfiguration-java.md`

## Next

Before invoking `azure-validate`, update `.azure/deployment-plan.md` status to `Ready for Validation`. The workflow is:

`azure-prepare` → `azure-validate` → `azure-deploy`
