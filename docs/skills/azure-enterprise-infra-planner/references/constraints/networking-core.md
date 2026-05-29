# Networking (Core)

## Common resources

- Virtual Network and Subnet (`Microsoft.Network/virtualNetworks`, `Microsoft.Network/virtualNetworks/subnets`)
- Network Security Group (`Microsoft.Network/networkSecurityGroups`)
- Route Table (`Microsoft.Network/routeTables`)
- Network Interface (`Microsoft.Network/networkInterfaces`)
- Public IP (`Microsoft.Network/publicIPAddresses`)
- NAT Gateway (`Microsoft.Network/natGateways`)

## Planning notes

- Define address space to avoid overlap with on-premises and peer networks.
- Use NSGs, UDRs, and NAT gateways intentionally; document all public exposure.
- Delegated subnets and private endpoints can impose subnet constraints.
