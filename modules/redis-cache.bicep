@description('Resource location')
param location string

@description('Redis name')
param redisName string

@description('Private link subnet ID')
param privateLinkSubnetId string

@description('Virtual network ID')
param vnetId string

// Private DNS zone
resource redisDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.redis.cache.windows.net'
  location: 'global'
}

// Virtual network link
resource redisVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'redis-dns-link'
  parent: redisDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Redis cache
resource redisCache 'Microsoft.Cache/Redis@2023-08-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      name: 'basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: true
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    redisVersion: '6'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

// Private endpoint
resource redisPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-redis'
  location: location
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-redis'
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
  }
}

// Private endpoint DNS group
resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'pdz-stor'
  parent: redisPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: redisDnsZone.id
        }
      }
    ]
  }
}

// Output
output redisHostName string = redisCache.properties.hostName
output redisPrimaryKey string = listKeys(redisCache.id, redisCache.apiVersion).primaryKey
