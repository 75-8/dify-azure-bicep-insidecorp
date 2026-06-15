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
param pgsqlPassword string

@description('Key Vault name')
param keyVaultName string = 'dify-kv'

@description('Explicit Key Vault access policies used for data-plane permissions')
param keyVaultAccessPolicies array = []

@description('Azure AI Services SKU name')
param aiServicesSku string = 'S0'

@description('Azure AI Services name base')
param aiServicesNameBase string = 'difyais'

@description('Azure AI Foundry Hub name base')
param aiHubNameBase string = 'dify-aihub'

@description('Azure AI Foundry Project name base')
param aiProjectNameBase string = 'dify-aiproject'

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
param acaCertPassword string = ''

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

@description('File share names used by Dify components')
param fileShareNames array = [
  'nginx'
  'sandbox'
  'ssrfproxy'
  'pluginstorage'
]

@description('OAuth2 Proxy container image')
param oauth2ProxyImage string = 'quay.io/oauth2-proxy/oauth2-proxy:v7.7.1'

@description('OAuth2 Proxy client ID (Entra App Registration)')
param oauth2ProxyClientId string = 'REPLACE_WITH_ENTRA_APP_CLIENT_ID'

@description('OAuth2 Proxy client secret (Entra App Registration)')
@secure()
param oauth2ProxyClientSecret string

@description('OAuth2 Proxy tenant ID')
param oauth2ProxyTenantId string = 'REPLACE_WITH_ENTRA_TENANT_ID'

@description('OAuth2 Proxy cookie secret')
@secure()
param oauth2ProxyCookieSecret string

@description('Application Gateway SSL certificate Base64 data (PFX format)')
@secure()
param appGwCertBase64Value string = ''

@description('Application Gateway SSL certificate password')
@secure()
param appGwCertPassword string = ''

@description('Dify API custom domain (reserved for future use, returns 404)')
param acaApiCustomerDomain string = 'api.example.com'

@description('Application Gateway API SSL certificate Base64 data (PFX format)')
@secure()
param appGwApiCertBase64Value string = ''

@description('Application Gateway API SSL certificate password')
@secure()
param appGwApiCertPassword string = ''

@description('Allowed source IP addresses/CIDRs for App Gateway HTTP/HTTPS inbound traffic')
param allow_ip array = [
  '*'
]

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${resourceGroupPrefix}-${location}'
  location: location
}

// Generate hash for unique resource names
var rgNameHex = uniqueString(subscription().id, rg.name)

// Deploy NSGs
module nsgs './modules/nsg.bicep' = {
  name: 'nsgsDeploy'
  scope: rg
  params: {
    location: location
    ipPrefix: ipPrefix
    allow_ip: allow_ip
  }
}

// Deploy network-related resources
module networkModule './modules/network.bicep' = {
  name: 'vnetDeploy'
  scope: rg
  params: {
    location: location
    ipPrefix: ipPrefix
    appGwNsgId: nsgs.outputs.appGwNsgId
    acaNsgId: nsgs.outputs.acaNsgId
    privateLinkNsgId: nsgs.outputs.privateLinkNsgId
    postgresNsgId: nsgs.outputs.postgresNsgId
  }
}

// Deploy Key Vault with explicit access policies over Private Link
module keyVaultModule './modules/keyvault.bicep' = {
  name: 'keyVaultDeploy'
  scope: rg
  params: {
    location: location
    keyVaultName: keyVaultName
    accessPolicies: keyVaultAccessPolicies
    privateLinkSubnetId: networkModule.outputs.privateLinkSubnetId
    vnetId: networkModule.outputs.vnetId
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
    privateLinkSubnetId: networkModule.outputs.privateLinkSubnetId
    vnetId: networkModule.outputs.vnetId
    fileShareNames: fileShareNames
  }
}

module postgresqlModule './modules/postgresql.bicep' = {
  name: 'postgresqlDeploy'
  scope: rg
  params: {
    location: location
    serverName: '${psqlFlexibleBase}${rgNameHex}'
    administratorLogin: pgsqlUser
    administratorLoginPassword: pgsqlPassword
    postgresSubnetId: networkModule.outputs.postgresSubnetId
    vnetId: networkModule.outputs.vnetId
  }
}

// Deploy Redis cache (conditional)
module redisModule './modules/redis-cache.bicep' = if (isAcaEnabled) {
  name: 'redisDeploy'
  scope: rg
  params: {
    location: location
    redisName: '${redisNameBase}${rgNameHex}'
    privateLinkSubnetId: networkModule.outputs.privateLinkSubnetId
    vnetId: networkModule.outputs.vnetId
  }
}

// Deploy Azure AI Services and Azure AI Foundry Hub/Project
module aoaiModule './modules/aoai.bicep' = {
  name: 'aoaiDeploy'
  scope: rg
  params: {
    location: location
    aiServicesSku: aiServicesSku
    aiServicesName: '${aiServicesNameBase}${rgNameHex}'
    aiHubName: '${aiHubNameBase}-${rgNameHex}'
    aiProjectName: '${aiProjectNameBase}-${rgNameHex}'
    privateLinkSubnetId: networkModule.outputs.privateLinkSubnetId
    vnetId: networkModule.outputs.vnetId
    storageAccountId: storageModule.outputs.storageAccountId
    keyVaultId: keyVaultModule.outputs.keyVaultId
    keyVaultName: keyVaultName
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
    acaSubnetId: networkModule.outputs.acaSubnetId
    isProvidedCert: isProvidedCert
    acaCertBase64Value: acaCertBase64Value
    acaCertPassword: acaCertPassword
    acaDifyCustomerDomain: acaDifyCustomerDomain
    acaAppMinCount: acaAppMinCount
    storageAccountName: storageModule.outputs.storageAccountName
    storageAccountKey: storageModule.outputs.storageAccountKey
    storageContainerName: storageAccountContainer
    nginxShareName: fileShareNames[0]
    sandboxShareName: fileShareNames[1]
    ssrfProxyShareName: fileShareNames[2]
    pluginStorageShareName: fileShareNames[3]
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
    oauth2ProxyImage: oauth2ProxyImage
    oauth2ProxyClientId: oauth2ProxyClientId
    oauth2ProxyClientSecret: oauth2ProxyClientSecret
    oauth2ProxyTenantId: oauth2ProxyTenantId
    oauth2ProxyCookieSecret: oauth2ProxyCookieSecret
  }
}

// Deploy Application Gateway
module appGwModule './modules/appgw.bicep' = {
  name: 'appGwDeploy'
  scope: rg
  params: {
    location: location
    appGwSubnetId: networkModule.outputs.appGwSubnetId
    acaNginxFqdn: 'nginx.${acaModule.outputs.acaDefaultDomain}'
    isProvidedCert: isProvidedCert
    appGwCertBase64Value: appGwCertBase64Value
    appGwCertPassword: appGwCertPassword
    acaApiCustomerDomain: acaApiCustomerDomain
    appGwApiCertBase64Value: appGwApiCertBase64Value
    appGwApiCertPassword: appGwApiCertPassword
  }
}

// Post-deployment output
output difyAppUrl string = acaModule.outputs.difyAppUrl
output keyVaultUri string = keyVaultModule.outputs.keyVaultUri
output appGwPublicIp string = appGwModule.outputs.publicIpAddress
output aoaiEndpoint string = aoaiModule.outputs.aoaiEndpoint
