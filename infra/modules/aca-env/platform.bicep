@description('Resource location')
param location string

@description('ACA Log Analytics workspace name')
param acaLogaName string

@description('ACA environment name')
param acaEnvName string

@description('ACA subnet ID')
param acaSubnetId string

@description('Storage account name')
param storageAccountName string

@description('Storage account key')
@secure()
param storageAccountKey string

@description('Nginx file share name')
param nginxShareName string

@description('SSRF proxy file share name')
param ssrfProxyShareName string

@description('Sandbox file share name')
param sandboxShareName string

@description('Plugin file share name')
param pluginStorageShareName string

@description('Whether to provide a custom certificate')
param isProvidedCert bool = false

@description('Certificate content (Base64 encoded)')
@secure()
param acaCertBase64Value string = ''

@description('Certificate password')
@secure()
param acaCertPassword string = ''

var acaStorages = [
  {
    resourceName: 'nginxshare'
    shareName: nginxShareName
  }
  {
    resourceName: 'ssrfproxyfileshare'
    shareName: ssrfProxyShareName
  }
  {
    resourceName: 'sandbox'
    shareName: sandboxShareName
  }
  {
    resourceName: 'pluginstoragefileshare'
    shareName: pluginStorageShareName
  }
]

// Create Log Analytics workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: acaLogaName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Create ACA environment
resource acaEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: acaEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    vnetConfiguration: {
      infrastructureSubnetId: acaSubnetId
      internal: true
    }
  }
}

// Mount shared Azure Files to the ACA environment.
resource fileShares 'Microsoft.App/managedEnvironments/storages@2023-05-01' = [for storage in acaStorages: {
  name: storage.resourceName
  parent: acaEnv
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: storage.shareName
      accessMode: 'ReadWrite'
    }
  }
}]

// Add certificate to ACA environment (conditional)
resource difyCerts 'Microsoft.App/managedEnvironments/certificates@2023-05-01' = if (isProvidedCert) {
  name: 'difycerts'
  parent: acaEnv
  properties: {
    password: acaCertPassword
    value: acaCertBase64Value
  }
}

output acaEnvId string = acaEnv.id
output difyCertificateId string = isProvidedCert ? resourceId('Microsoft.App/managedEnvironments/certificates', acaEnv.name, 'difycerts') : ''
output nginxStorageName string = acaStorages[0].resourceName
output ssrfProxyStorageName string = acaStorages[1].resourceName
output sandboxStorageName string = acaStorages[2].resourceName
output pluginStorageName string = acaStorages[3].resourceName
