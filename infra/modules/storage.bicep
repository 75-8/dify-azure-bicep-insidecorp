@description('Resource location')
param location string
param storageAccountName string
param containerName string
param privateLinkSubnetId string
param vnetId string

@description('File share names to create')
param fileShareNames array = []

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: containerName
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = [for shareName in fileShareNames: {
  name: shareName
  parent: fileService
  properties: {
    shareQuota: 50
  }
}]

resource blobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}
resource fileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'global'
}
resource blobVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'blob-dns-link'
  parent: blobDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: { id: vnetId }
  }
}
resource fileVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'file-dns-link'
  parent: fileDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: { id: vnetId }
  }
}
resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-blob'
  location: location
  properties: {
    subnet: { id: privateLinkSubnetId }
    privateLinkServiceConnections: [{
      name: 'psc-blob'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds: ['blob']
      }
    }]
  }
}
resource filePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-file'
  location: location
  properties: {
    subnet: { id: privateLinkSubnetId }
    privateLinkServiceConnections: [{
      name: 'psc-file'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds: ['file']
      }
    }]
  }
}
resource blobPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-blob'
  parent: blobPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [{
      name: 'config1'
      properties: { privateDnsZoneId: blobDnsZone.id }
    }]
  }
}
resource filePrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-file'
  parent: filePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [{
      name: 'config1'
      properties: { privateDnsZoneId: fileDnsZone.id }
    }]
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output storageAccountKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output fileShareNames array = fileShareNames
