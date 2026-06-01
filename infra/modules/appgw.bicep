@description('Resource location')
param location string

@description('Application Gateway name')
param appGwName string = 'dify-appgw'

@description('Subnet resource id for Application Gateway (must be dedicated subnet)')
param appGwSubnetId string

@description('Public IP name for Application Gateway')
param publicIpName string = 'dify-appgw-pip'

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Minimal Application Gateway (Standard_v2) placeholder
resource appGw 'Microsoft.Network/applicationGateways@2022-09-01' = {
  name: appGwName
  location: location
  sku: {
    name: 'Standard_v2'
    tier: 'Standard_v2'
    capacity: 1
  }
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: appGwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpPort'
        properties: { port: 80 }
      }
      {
        name: 'httpsPort'
        properties: { port: 443 }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultBackendPool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaultBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: ''
          }
          backendAddressPool: {
            id: ''
          }
          backendHttpSettings: {
            id: ''
          }
        }
      }
    ]
  }
  dependsOn: [publicIp]
}

output appGwId string = appGw.id
output publicIpId string = publicIp.id
