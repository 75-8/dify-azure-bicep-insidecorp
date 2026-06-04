@description('Resource group location')
param location string

@description('IP prefix')
param ipPrefix string

@description('NSG ID for AppGwSubnet')
param appGwNsgId string

@description('NSG ID for ACASubnet')
param acaNsgId string

@description('NSG ID for PrivateLinkSubnet')
param privateLinkNsgId string

@description('NSG ID for PostgresSubnet')
param postgresNsgId string

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
    networkSecurityGroup: {
      id: privateLinkNsgId
    }
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
    networkSecurityGroup: {
      id: acaNsgId
    }
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
    networkSecurityGroup: {
      id: postgresNsgId
    }
  }
  dependsOn: [
    acaSubnet
  ]
}

// Application Gateway subnet (dedicated, no delegations per Azure requirement)
resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: 'AppGwSubnet'
  parent: vnet
  properties: {
    addressPrefix: '${ipPrefix}.5.0/24'
    networkSecurityGroup: {
      id: appGwNsgId
    }
  }
  dependsOn: [
    postgresSubnet
  ]
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output privateLinkSubnetId string = privateLinkSubnet.id
output acaSubnetId string = acaSubnet.id
output postgresSubnetId string = postgresSubnet.id
output appGwSubnetId string = appGwSubnet.id
