# Well-Architected Framework Checklist

Use this checklist for every infrastructure plan.

## Reliability

- Define availability zones, region strategy, RTO/RPO, backups, and failover runbooks.
- Avoid single points of failure in ingress, compute, state, and identity dependencies.

## Security

- Prefer managed identities, least-privilege RBAC, private endpoints, encryption, and Key Vault.
- Document public exposure, firewall rules, diagnostics, and secret handling.

## Cost Optimization

- Choose SKUs based on workload requirements and document scale assumptions.
- Include autoscaling, budgets, tagging, and rightsizing review points.

## Operational Excellence

- Include monitoring, alerts, deployment rollback, patching, and incident response.
- Ensure infrastructure is reproducible with Bicep or Terraform.

## Performance Efficiency

- Validate regional latency, scaling limits, caching, and quota dependencies.
- Confirm resource pairings and SKU compatibility before IaC generation.
