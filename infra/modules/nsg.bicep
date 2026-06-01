@description('Resource location')
param location string

@description('Network Security Group name')
param nsgName string = 'dify-nsg'

@description('Security rules array - provide security rules when instantiating module')
param securityRules array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}

output nsgId string = nsg.id
