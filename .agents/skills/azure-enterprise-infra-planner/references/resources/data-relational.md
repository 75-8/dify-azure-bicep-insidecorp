# Data (Relational)

## Common resources

- Azure SQL Server and Database (`Microsoft.Sql/servers`, `Microsoft.Sql/servers/databases`)
- Azure Database for MySQL (`Microsoft.DBforMySQL/flexibleServers`)
- Azure Database for PostgreSQL (`Microsoft.DBforPostgreSQL/flexibleServers`)

## Planning notes

- Confirm private networking, firewall rules, backups, high availability, and maintenance windows.
- Prefer Microsoft Entra authentication and managed identity where supported.
- Define RTO/RPO, PITR retention, geo-redundancy, and encryption requirements.
