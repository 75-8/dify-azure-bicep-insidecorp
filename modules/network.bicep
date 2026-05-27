@description('Resource group location')
param location string

@description('IP prefix')
param ipPrefix string

// Create virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${ipPrefix}.0.0/16'
      ]
    }
    subnets: []
  }
}

// Private link subnet
resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'PrivateLinkSubnet'
  parent: vnet
  properties: {
    addressPrefix: '${ipPrefix}.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

// ACA subnet
resource acaSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'ACASubnet'
  parent: vnet
  properties: {
    addressPrefix: '${ipPrefix}.2.0/23'
    delegations: [
      {
        name: 'aca-delegation'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
  dependsOn: [
    privateLinkSubnet
  ]
}

// PostgreSQL subnet
resource postgresSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'PostgresSubnet'
  parent: vnet
  properties: {
    addressPrefix: '${ipPrefix}.4.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
    delegations: [
      {
        name: 'postgres-delegation'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
  dependsOn: [
    acaSubnet
  ]
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output privateLinkSubnetId string = privateLinkSubnet.id
output acaSubnetId string = acaSubnet.id
output postgresSubnetId string = postgresSubnet.id
