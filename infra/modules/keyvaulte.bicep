@description('Resource group location')
param location string

@description('Key Vault name')
param keyVaultName string

@description('Tenant ID for access policies')
param tenantId string

@description('Enable RBAC authorization on Key Vault')
param enableRbacAuthorization bool = true

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: 'Enabled'
    enabledForTemplateDeployment: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
