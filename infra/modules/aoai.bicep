@description('Resource group location')
param location string

@description('Azure OpenAI account name')
param aoaiAccountName string

@description('SKU for the Azure OpenAI account')
param aoaiSku string = 'S0'

@description('Model deployments to create. Each item must have: name, model.name, model.version, sku.capacity')
param modelDeployments array = [
  {
    name: 'gpt-5-4'
    model: {
      name: 'gpt-5.4'
      version: '2026-04-01'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'text-embedding-ada-003'
    model: {
      name: 'text-embedding-ada-003'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]

@description('Private Link subnet ID used by the AOAI private endpoint')
param privateLinkSubnetId string

@description('Virtual network ID linked to the AOAI private DNS zone')
param vnetId string

// Azure OpenAI (Cognitive Services) account
resource aoaiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aoaiAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: aoaiSku
  }
  properties: {
    customSubDomainName: aoaiAccountName
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Model deployments
@batchSize(1)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [
  for deployment in modelDeployments: {
    name: deployment.name
    parent: aoaiAccount
    sku: {
      name: deployment.sku.name
      capacity: deployment.sku.capacity
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: deployment.model.name
        version: deployment.model.version
      }
    }
  }
]

// Private DNS Zone for Azure OpenAI
resource aoaiDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
}

resource aoaiVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'aoai-dns-link'
  parent: aoaiDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Private Endpoint
resource aoaiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-aoai'
  location: location
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-aoai'
        properties: {
          privateLinkServiceId: aoaiAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource aoaiPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-aoai'
  parent: aoaiPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: aoaiDnsZone.id
        }
      }
    ]
  }
}

output aoaiEndpoint string = aoaiAccount.properties.endpoint
output aoaiAccountName string = aoaiAccount.name
output aoaiPrivateEndpointId string = aoaiPrivateEndpoint.id
