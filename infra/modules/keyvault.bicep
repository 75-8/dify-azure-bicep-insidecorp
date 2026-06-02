@description('Resource group location')
param location string

@description('Key Vault name')
param keyVaultName string

@description('Tenant ID for access policies')
param tenantId string = subscription().tenantId

@description('Explicit Key Vault access policies. RBAC authorization is disabled so these policies are used for data-plane permissions.')
param accessPolicies array = []

@description('Private Link subnet ID used by the Key Vault private endpoint')
param privateLinkSubnetId string

@description('Virtual network ID linked to the Key Vault private DNS zone')
param vnetId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: false
    accessPolicies: accessPolicies
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    enabledForTemplateDeployment: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enablePurgeProtection: false
    enableSoftDelete: true
  }
}

resource keyVaultDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource keyVaultVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'keyvault-dns-link'
  parent: keyVaultDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-keyvault'
  location: location
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-keyvault'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-keyvault'
  parent: keyVaultPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: keyVaultDnsZone.id
        }
      }
    ]
  }
}

output keyVaultId string = keyVault.id
output keyVaultNameOutput string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultPrivateEndpointId string = keyVaultPrivateEndpoint.id
