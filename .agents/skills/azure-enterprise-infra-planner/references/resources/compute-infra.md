# Compute (IaaS)

## Common resources

- Azure Kubernetes Service (`Microsoft.ContainerService/managedClusters`)
- Virtual Machines and VM Scale Sets (`Microsoft.Compute/virtualMachines`, `Microsoft.Compute/virtualMachineScaleSets`)
- Availability Sets (`Microsoft.Compute/availabilitySets`)
- Managed Disks (`Microsoft.Compute/disks`)

## Planning notes

- Select availability zones, update domains, backup policy, and patch strategy.
- Confirm subnet sizing, NSGs, outbound paths, and private control-plane requirements.
- Use managed identities and avoid embedding credentials in IaC.
