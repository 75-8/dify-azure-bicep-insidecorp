# Enterprise Infrastructure Planning Workflow

Execute the workflow in order and stop at each approval gate. Use MCP tools first when available; otherwise rely on the bundled reference files and clearly note the fallback.

| Phase | File | Required outcome | Gate |
|---|---|---|---|
| 1 | [1-extract-insights.md](phases/1-extract-insights.md) | Existing environment and requirement insights captured | Scope is understood |
| 2 | [2-research-best-practices.md](phases/2-research-best-practices.md) | WAF and service guidance collected | Research complete |
| 3 | [3-research-resources.md](phases/3-research-resources.md) | Candidate resource list and constraints identified | Resource list reviewed |
| 4 | [4-generate-plan.md](phases/4-generate-plan.md) | Infrastructure plan JSON written under `/.azure/` | User approves plan |
| 5 | [5-verify.md](phases/5-verify.md) | Plan validated against WAF, schema, and pairing constraints | Verification passes |
| 6 | [6-generate-iac.md](phases/6-generate-iac.md) | Bicep or Terraform generated under `/infra/` | IaC validates |
| 7 | [7-deploy.md](phases/7-deploy.md) | Deployment command prepared or executed | User confirms deployment |

## Required artifacts

- `/.azure/infra-plan.json` matching [schema.md](schema.md).
- `/.azure/infra-plan.md` human-readable summary.
- `/infra/` IaC files generated only after plan approval.
- Validation evidence from [verification.md](verification.md).
