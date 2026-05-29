# Monitoring

## Common resources

- Log Analytics workspace (`Microsoft.OperationalInsights/workspaces`)
- Application Insights (`Microsoft.Insights/components`)
- Diagnostic settings (`Microsoft.Insights/diagnosticSettings`)
- Action groups and metric alerts (`Microsoft.Insights/actionGroups`, `Microsoft.Insights/metricAlerts`)

## Planning notes

- Centralize logs where possible and define retention by compliance need.
- Enable diagnostics on network, compute, data, and security resources.
- Include actionable alerts and dashboards for service health.
