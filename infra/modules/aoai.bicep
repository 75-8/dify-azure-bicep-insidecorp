@description('Resource group location')
param location string

@description('SKU for the Azure AI Services account')
param aiServicesSku string = 'S0'

@description('Azure AI Services name')
param aiServicesName string

@description('Azure AI Foundry Hub name')
param aiHubName string

@description('Azure AI Foundry Project name')
param aiProjectName string

@description('Private Link subnet ID used by private endpoints')
param privateLinkSubnetId string

@description('Virtual network ID linked to the private DNS zones')
param vnetId string

@description('Storage Account resource ID linked to the AI Hub')
param storageAccountId string

@description('Key Vault resource ID linked to the AI Hub')
param keyVaultId string

@description('Key Vault name used for access policy')
param keyVaultName string

// ----------------------------------------------------
// Monitoring resources for the AI Hub
// ----------------------------------------------------
resource aiLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${aiHubName}-loga'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource aiAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${aiHubName}-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: aiLogAnalytics.id
  }
}

// ----------------------------------------------------
// Azure AI Services (backend)
// ----------------------------------------------------
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  kind: 'AIServices'
  sku: {
    name: aiServicesSku
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// ----------------------------------------------------
// Azure AI Foundry Hub
// ----------------------------------------------------
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiHubName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: aiAppInsights.id
    publicNetworkAccess: 'Disabled'
  }
}

// ----------------------------------------------------
// Azure AI Services Connection
// ----------------------------------------------------
resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  name: '${aiHubName}-aisconnection'
  parent: aiHub
  properties: {
    category: 'AIServices'
    target: aiServices.properties.endpoint
    authType: 'ApiKey'
    credentials: {
      key: listKeys(aiServices.id, aiServices.apiVersion).key1
    }
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServices.id
    }
  }
}

// ----------------------------------------------------
// Azure AI Foundry Project
// ----------------------------------------------------
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiProjectName
  location: location
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiProjectName
    hubId: aiHub.id
  }
}

// ----------------------------------------------------
// Key Vault Access Policy for AI Hub
// ----------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: aiHub.identity.principalId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

// ----------------------------------------------------
// DNS Zone and Link for AI Services (OpenAI endpoints)
// ----------------------------------------------------
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

// ----------------------------------------------------
// DNS Zone and Link for AI Hub (api.azureml.ms)
// ----------------------------------------------------
resource hubDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.api.azureml.ms'
  location: 'global'
}

resource hubVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'hub-dns-link'
  parent: hubDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// ----------------------------------------------------
// Private Endpoints
// ----------------------------------------------------
resource aiServicesPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-aiservices'
  location: location
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-aiservices'
        properties: {
          privateLinkServiceId: aiServices.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource aiServicesPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-aiservices'
  parent: aiServicesPrivateEndpoint
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

resource aiHubPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-aihub'
  location: location
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-aihub'
        properties: {
          privateLinkServiceId: aiHub.id
          groupIds: [
            'amlworkspace'
          ]
        }
      }
    ]
  }
}

resource aiHubPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-aihub'
  parent: aiHubPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: hubDnsZone.id
        }
      }
    ]
  }
}

output aoaiEndpoint string = aiServices.properties.endpoint
output aoaiAccountName string = aiServices.name
output aiHubId string = aiHub.id
output aiProjectId string = aiProject.id
