# Pairing Checks

Pairing checks prevent incompatible Azure resource combinations from reaching IaC generation.

## Required checks

- Region availability for each resource and SKU.
- Zone support alignment across compute, ingress, and data services.
- Network integration compatibility for private endpoints, delegated subnets, and service endpoints.
- Identity and RBAC dependencies for services that access Key Vault, storage, databases, or registries.
- Data, backup, and DR pairings that satisfy the required RTO/RPO.
