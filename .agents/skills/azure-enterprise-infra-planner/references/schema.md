# Infrastructure Plan Schema

The plan document is the contract between research, review, IaC generation, and deployment.

## Required top-level fields

| Field | Type | Description |
|---|---|---|
| `meta` | object | Status, timestamps, target cloud, generator, and approval state. |
| `requirements` | object | User goals, workload characteristics, compliance, RTO/RPO, and assumptions. |
| `architecture` | object | Regions, topology, resource groups, subscriptions, and dependencies. |
| `resources` | array | Planned Azure resources with names, types, SKUs, region, dependencies, and configuration. |
| `security` | object | Identity, RBAC, secrets, network security, encryption, and policy controls. |
| `operations` | object | Monitoring, backup, DR, logging, patching, and runbook requirements. |
| `cost` | object | SKU rationale, scaling assumptions, and optimization notes. |
| `validation` | object | WAF checks, pairing checks, schema checks, and unresolved risks. |

## Approval states

`meta.status` must be one of `draft`, `reviewed`, `approved`, or `rejected`. IaC generation is allowed only when `meta.status` is `approved`.
