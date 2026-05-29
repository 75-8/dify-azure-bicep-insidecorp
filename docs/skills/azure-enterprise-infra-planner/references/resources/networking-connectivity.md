# Networking (Connectivity)

## Common resources

- Azure Bastion (`Microsoft.Network/bastionHosts`)
- Azure Firewall (`Microsoft.Network/azureFirewalls`)
- VPN Gateway (`Microsoft.Network/virtualNetworkGateways`)
- DNS zones and Private DNS zones (`Microsoft.Network/dnsZones`, `Microsoft.Network/privateDnsZones`)
- Private Endpoint (`Microsoft.Network/privateEndpoints`)

## Planning notes

- Confirm hub-and-spoke routing, DNS resolution, and firewall policy flow.
- Private endpoints require DNS planning and subnet capacity.
- VPN and firewall SKUs affect throughput, zones, and cost.
