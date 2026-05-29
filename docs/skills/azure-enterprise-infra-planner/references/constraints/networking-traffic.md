# Networking (Traffic)

## Common resources

- Application Gateway (`Microsoft.Network/applicationGateways`)
- Azure Front Door (`Microsoft.Cdn/profiles`)
- Load Balancer (`Microsoft.Network/loadBalancers`)
- API Management (`Microsoft.ApiManagement/service`)

## Planning notes

- Select ingress based on global routing, WAF, TLS, private backend, and API policy needs.
- Confirm certificate ownership, health probes, backend pools, and zone support.
- Avoid exposing management or internal-only endpoints publicly.
