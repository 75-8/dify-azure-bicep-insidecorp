targetScope = 'subscription'

@description('Region to deploy')
param location string = 'japaneast'

@description('Resource group name prefix')
param resourceGroupPrefix string = 'rg'

@description('IP address prefix')
param ipPrefix string = '10.99'

@description('Storage account name base')
param storageAccountBase string = 'acadifytest'

@description('Storage account container name')
param storageAccountContainer string = 'dfy'

@description('Redis name base')
param redisNameBase string = 'acadifyredis'

@description('PostgreSQL name base')
param psqlFlexibleBase string = 'acadifypsql'

@description('PostgreSQL user name')
param pgsqlUser string = 'user'

@description('PostgreSQL password')
@secure()
param pgsqlPassword string = '#QWEASDasdqwe'

@description('ACA environment name')
param acaEnvName string = 'dify-aca-env'

@description('ACA Log Analytics workspace name')
param acaLogaName string = 'dify-loga'

@description('Whether to provide a custom certificate')
param isProvidedCert bool = true

@description('Certificate content (Base64 encoded)')
@secure()
param acaCertBase64Value string = ''

@description('Certificate password')
@secure()
param acaCertPassword string = 'password'

@description('Dify custom domain')
param acaDifyCustomerDomain string = 'dify.example.com'

@description('Minimum instance count for ACA app')
param acaAppMinCount int = 0

@description('Whether to enable ACA')
param isAcaEnabled bool = false

@description('Allowed CIDR blocks for nginx ingress (corporate network only)')
param allowedIngressCidrs array = [
  '10.0.0.0/8'
]

@description('Dify API image')
param difyApiImage string = 'langgenius/dify-api:1.13.3'

@description('Dify sandbox image')
param difySandboxImage string = 'langgenius/dify-sandbox:0.2.14'

@description('Dify web image')
param difyWebImage string = 'langgenius/dify-web:1.13.3'

@description('Dify plugin daemon image')
param difyPluginDaemonImage string = 'langgenius/dify-plugin-daemon:0.5.3-local'


// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${resourceGroupPrefix}-${location}'
  location: location
}

// Generate hash for unique resource names
var rgNameHex = uniqueString(subscription().id, rg.name)

// Deploy network-related resources
module vnetModule './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  scope: rg
  params: {
    location: location
    ipPrefix: ipPrefix
  }
}

// Deploy storage account and file share
module storageModule './modules/storage.bicep' = {
  name: 'storageDeploy'
  scope: rg
  params: {
    location: location
    storageAccountName: '${storageAccountBase}${rgNameHex}'
    containerName: storageAccountContainer
    privateLinkSubnetId: vnetModule.outputs.privateLinkSubnetId
    vnetId: vnetModule.outputs.vnetId
  }
}

// Deploy file shares
module nginxFileShareModule './modules/fileshare.bicep' = {
  name: 'nginxFileShareDeploy'
  scope: rg
  params: {
    storageAccountName: storageModule.outputs.storageAccountName
    shareName: 'nginx'
    localMountDir: 'mountfiles/nginx'
  }
}

module sandboxFileShareModule './modules/fileshare.bicep' = {
  name: 'sandboxFileShareDeploy'
  scope: rg
  params: {
    storageAccountName: storageModule.outputs.storageAccountName
    shareName: 'sandbox'
    localMountDir: 'mountfiles/sandbox'
  }
}

module ssrfProxyFileShareModule './modules/fileshare.bicep' = {
  name: 'ssrfProxyFileShareDeploy'
  scope: rg
  params: {
    storageAccountName: storageModule.outputs.storageAccountName
    shareName: 'ssrfproxy'
    localMountDir: 'mountfiles/ssrfproxy'
  }
}

module pluginStorageFileShareModule './modules/fileshare.bicep' = {
  name: 'pluginStorageFileShareDeploy'
  scope: rg
  params: {
    storageAccountName: storageModule.outputs.storageAccountName
    shareName: 'pluginstorage'
    localMountDir: 'mountfiles/pluginstorage'
  }
}

// Deploy PostgreSQL server
module postgresqlModule './modules/postgresql.bicep' = {
  name: 'postgresqlDeploy'
  scope: rg
  params: {
    location: location
    serverName: '${psqlFlexibleBase}${rgNameHex}'
    administratorLogin: pgsqlUser
    administratorLoginPassword: pgsqlPassword
    postgresSubnetId: vnetModule.outputs.postgresSubnetId
    vnetId: vnetModule.outputs.vnetId
  }
}

// Deploy Redis cache (conditional)
module redisModule './modules/redis-cache.bicep' = if (isAcaEnabled) {
  name: 'redisDeploy'
  scope: rg
  params: {
    location: location
    redisName: '${redisNameBase}${rgNameHex}'
    privateLinkSubnetId: vnetModule.outputs.privateLinkSubnetId
    vnetId: vnetModule.outputs.vnetId
  }
}

// Deploy ACA environment and apps
module acaModule './modules/aca-env.bicep' = {
  name: 'acaEnvDeploy'
  scope: rg
  params: {
    location: location
    acaEnvName: acaEnvName
    acaLogaName: acaLogaName
    acaSubnetId: vnetModule.outputs.acaSubnetId
    isProvidedCert: isProvidedCert
    acaCertBase64Value: acaCertBase64Value
    acaCertPassword: acaCertPassword
    acaDifyCustomerDomain: acaDifyCustomerDomain
    acaAppMinCount: acaAppMinCount
    storageAccountName: storageModule.outputs.storageAccountName
    storageAccountKey: storageModule.outputs.storageAccountKey
    storageContainerName: storageAccountContainer
    nginxShareName: nginxFileShareModule.outputs.shareName
    sandboxShareName: sandboxFileShareModule.outputs.shareName
    ssrfProxyShareName: ssrfProxyFileShareModule.outputs.shareName
    pluginStorageShareName: pluginStorageFileShareModule.outputs.shareName
    postgresServerFqdn: postgresqlModule.outputs.serverFqdn
    postgresAdminLogin: pgsqlUser
    postgresAdminPassword: pgsqlPassword
    postgresDifyDbName: postgresqlModule.outputs.difyDbName
    postgresVectorDbName: postgresqlModule.outputs.vectorDbName
    redisHostName: isAcaEnabled ? redisModule.outputs.redisHostName : ''
    redisPrimaryKey: isAcaEnabled ? redisModule.outputs.redisPrimaryKey : ''
    difyApiImage: difyApiImage
    difySandboxImage: difySandboxImage
    difyWebImage: difyWebImage
    difyPluginDaemonImage: difyPluginDaemonImage
    blobEndpoint: storageModule.outputs.blobEndpoint
    allowedIngressCidrs: allowedIngressCidrs
  }
}

// Post-deployment output
output difyAppUrl string = acaModule.outputs.difyAppUrl
