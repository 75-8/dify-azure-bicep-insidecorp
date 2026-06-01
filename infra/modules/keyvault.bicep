@description('Resource location')
param location string

@description('Key Vault name')
param keyVaultName string = 'dify-kv'

@description('Object Ids for access policies (optional)')
param accessPolicies array = []

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: accessPolicies
    enablePurgeProtection: false
    enableSoftDelete: true
  }
}

output keyVaultId string = kv.id
output keyVaultNameOutput string = kv.name
