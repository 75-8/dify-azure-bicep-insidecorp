@description('Resource location')
param location string

@description('IP address prefix for subnets')
param ipPrefix string

@description('Allowed source IP addresses/CIDRs for App Gateway HTTP/HTTPS inbound traffic')
param allow_ip array = [
  '*'
]

resource nsgAppGw 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-appgw'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-HTTPS-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: length(allow_ip) == 1 && allow_ip[0] == '*' ? '*' : null
          sourceAddressPrefixes: length(allow_ip) == 1 && allow_ip[0] == '*' ? null : allow_ip
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-GatewayManager-Inbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer-Inbound'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgAca 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-aca'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-AppGW-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4180'
          sourceAddressPrefix: '${ipPrefix}.5.0/24'
          destinationAddressPrefix: '${ipPrefix}.2.0/23'
        }
      }
      {
        name: 'Allow-ACA-Internal-Inbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '${ipPrefix}.2.0/23'
          destinationAddressPrefix: '${ipPrefix}.2.0/23'
        }
      }
    ]
  }
}

resource nsgPrivateLink 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-privatelink'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-ACA-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '443'
            '6379'
          ]
          sourceAddressPrefix: '${ipPrefix}.2.0/23'
          destinationAddressPrefix: '${ipPrefix}.0.0/24'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 900
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgPostgres 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-postgres'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-ACA-Postgres-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: '${ipPrefix}.2.0/23'
          destinationAddressPrefix: '${ipPrefix}.4.0/24'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 900
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output appGwNsgId string = nsgAppGw.id
output acaNsgId string = nsgAca.id
output privateLinkNsgId string = nsgPrivateLink.id
output postgresNsgId string = nsgPostgres.id
