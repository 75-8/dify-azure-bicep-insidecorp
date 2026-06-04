@description('Resource location')
param location string

@description('Application Gateway name')
param appGwName string = 'dify-appgw'

@description('Subnet resource id for Application Gateway (must be dedicated subnet)')
param appGwSubnetId string

@description('Public IP name for Application Gateway')
param publicIpName string = 'dify-appgw-pip'

@description('Nginx ACA internal FQDN')
param acaNginxFqdn string

@description('Whether to provide a custom certificate')
param isProvidedCert bool = false

@description('Application Gateway SSL certificate Base64 data (PFX format)')
@secure()
param appGwCertBase64Value string = ''

@description('Application Gateway SSL certificate password')
@secure()
param appGwCertPassword string = ''

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

var sslCertificates = isProvidedCert ? [
  {
    name: 'appgw-cert'
    properties: {
      data: appGwCertBase64Value
      password: appGwCertPassword
    }
  }
] : []

var frontendPorts = isProvidedCert ? [
  {
    name: 'httpPort'
    properties: {
      port: 80
    }
  }
  {
    name: 'httpsPort'
    properties: {
      port: 443
    }
  }
] : [
  {
    name: 'httpPort'
    properties: {
      port: 80
    }
  }
]

var httpListeners = isProvidedCert ? [
  {
    name: 'httpListener'
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGwFrontendIP')
      }
      frontendPort: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'httpPort')
      }
      protocol: 'Http'
    }
  }
  {
    name: 'httpsListener'
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGwFrontendIP')
      }
      frontendPort: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'httpsPort')
      }
      protocol: 'Https'
      sslCertificate: {
        id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwName, 'appgw-cert')
      }
    }
  }
] : [
  {
    name: 'httpListener'
    properties: {
      frontendIPConfiguration: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGwFrontendIP')
      }
      frontendPort: {
        id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'httpPort')
      }
      protocol: 'Http'
    }
  }
]

// Redirect config
var redirectConfigurations = isProvidedCert ? [
  {
    name: 'httpToHttpsRedirect'
    properties: {
      redirectType: 'Permanent'
      targetListener: {
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'httpsListener')
      }
      includePath: true
      includeQueryString: true
    }
  }
] : []

// URL Path Maps
var urlPathMaps = [
  {
    name: 'urlPathMap'
    properties: {
      defaultBackendAddressPool: {
        id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'backendPool-ui')
      }
      defaultBackendHttpSettings: {
        id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, 'backendHttpSettings')
      }
      pathRules: [
        {
          name: 'apiRule'
          properties: {
            paths: [
              '/v1/*'
              '/console/api/*'
              '/api/*'
              '/files/*'
            ]
            backendAddressPool: {
              id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'backendPool-api')
            }
            backendHttpSettings: {
              id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, 'backendHttpSettings')
            }
          }
        }
      ]
    }
  }
]

var requestRoutingRules = isProvidedCert ? [
  {
    name: 'httpsRoutingRule'
    properties: {
      ruleType: 'PathBasedRouting'
      priority: 100
      httpListener: {
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'httpsListener')
      }
      urlPathMap: {
        id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwName, 'urlPathMap')
      }
    }
  }
  {
    name: 'httpRedirectRule'
    properties: {
      ruleType: 'Basic'
      priority: 200
      httpListener: {
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'httpListener')
      }
      redirectConfiguration: {
        id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', appGwName, 'httpToHttpsRedirect')
      }
    }
  }
] : [
  {
    name: 'httpRoutingRule'
    properties: {
      ruleType: 'PathBasedRouting'
      priority: 100
      httpListener: {
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'httpListener')
      }
      urlPathMap: {
        id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwName, 'urlPathMap')
      }
    }
  }
]

resource appGw 'Microsoft.Network/applicationGateways@2023-05-01' = {
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
    frontendPorts: frontendPorts
    sslCertificates: sslCertificates
    httpListeners: httpListeners
    urlPathMaps: urlPathMaps
    requestRoutingRules: requestRoutingRules
    redirectConfigurations: redirectConfigurations
    backendAddressPools: [
      {
        name: 'backendPool-ui'
        properties: {
          backendAddresses: [
            {
              fqdn: acaNginxFqdn
            }
          ]
        }
      }
      {
        name: 'backendPool-api'
        properties: {
          backendAddresses: [
            {
              fqdn: acaNginxFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpSettings'
        properties: {
          port: 4180
          protocol: 'Http'
          pickHostNameFromBackendAddress: true
          requestTimeout: 60
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwName, 'oauth2ProxyPingProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'oauth2ProxyPingProbe'
        properties: {
          protocol: 'Http'
          path: '/oauth2/ping'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIp
  ]
}

output appGwId string = appGw.id
output publicIpAddress string = publicIp.properties.ipAddress
