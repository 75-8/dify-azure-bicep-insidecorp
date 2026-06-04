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

@description('Storage container name')
param storageContainerName string

@description('Redis host name')
param redisHostName string = ''

@description('Redis primary key')
@secure()
param redisPrimaryKey string = ''

@description('PostgreSQL server fully qualified domain name')
param postgresServerFqdn string

@description('PostgreSQL administrator login')
param postgresAdminLogin string

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('Postgres Dify database name')
param postgresDifyDbName string

@description('Postgres Vector database name')
param postgresVectorDbName string

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

@description('Dify custom domain')
param acaDifyCustomerDomain string = ''

@description('ACA app minimum instance count')
param acaAppMinCount int = 0

@description('Dify API image')
param difyApiImage string

@description('Dify Sandbox image')
param difySandboxImage string

@description('Dify Web image')
param difyWebImage string

@description('Dify Plugin Daemon image')
param difyPluginDaemonImage string

@description('Blob endpoint')
param blobEndpoint string

@description('Allowed CIDR blocks for nginx ingress')
param allowedIngressCidrs array = [
  '10.0.0.0/8'
]

@description('OAuth2 Proxy container image')
param oauth2ProxyImage string = 'quay.io/oauth2-proxy/oauth2-proxy:v7.7.1'

@description('OAuth2 Proxy client ID (Entra App Registration)')
param oauth2ProxyClientId string

@description('OAuth2 Proxy client secret (Entra App Registration)')
@secure()
param oauth2ProxyClientSecret string

@description('OAuth2 Proxy tenant ID')
param oauth2ProxyTenantId string

@description('OAuth2 Proxy cookie secret')
@secure()
param oauth2ProxyCookieSecret string

// Platform owns the shared ACA foundation: logging, managed environment, certificates, and mounted storage handles.
module platform './aca-env/platform.bicep' = {
  name: 'aca-platform'
  params: {
    location: location
    acaLogaName: acaLogaName
    acaEnvName: acaEnvName
    acaSubnetId: acaSubnetId
    storageAccountName: storageAccountName
    storageAccountKey: storageAccountKey
    nginxShareName: nginxShareName
    ssrfProxyShareName: ssrfProxyShareName
    sandboxShareName: sandboxShareName
    pluginStorageShareName: pluginStorageShareName
    isProvidedCert: isProvidedCert
    acaCertBase64Value: acaCertBase64Value
    acaCertPassword: acaCertPassword
  }
}

// Edge runtime owns traffic-adjacent containers: public ingress and outbound SSRF proxy.
module edgeRuntime './aca-env/edge-runtime.bicep' = {
  name: 'aca-edge-runtime'
  params: {
    location: location
    acaEnvId: platform.outputs.acaEnvId
    nginxStorageName: platform.outputs.nginxStorageName
    ssrfProxyStorageName: platform.outputs.ssrfProxyStorageName
    isProvidedCert: isProvidedCert
    acaDifyCustomerDomain: acaDifyCustomerDomain
    difyCertificateId: platform.outputs.difyCertificateId
    acaAppMinCount: acaAppMinCount
    allowedIngressCidrs: allowedIngressCidrs
    oauth2ProxyImage: oauth2ProxyImage
    oauth2ProxyClientId: oauth2ProxyClientId
    oauth2ProxyClientSecret: oauth2ProxyClientSecret
    oauth2ProxyTenantId: oauth2ProxyTenantId
    oauth2ProxyCookieSecret: oauth2ProxyCookieSecret
  }
}

// Application owns Dify product workloads and integrations with data, cache, blob, plugin, and code execution services.
module application './aca-env/application.bicep' = {
  name: 'aca-application'
  params: {
    location: location
    acaEnvId: platform.outputs.acaEnvId
    storageAccountName: storageAccountName
    storageAccountKey: storageAccountKey
    storageContainerName: storageContainerName
    redisHostName: redisHostName
    redisPrimaryKey: redisPrimaryKey
    postgresServerFqdn: postgresServerFqdn
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
    postgresDifyDbName: postgresDifyDbName
    postgresVectorDbName: postgresVectorDbName
    sandboxStorageName: platform.outputs.sandboxStorageName
    pluginStorageName: platform.outputs.pluginStorageName
    acaAppMinCount: acaAppMinCount
    difyApiImage: difyApiImage
    difySandboxImage: difySandboxImage
    difyWebImage: difyWebImage
    difyPluginDaemonImage: difyPluginDaemonImage
    blobEndpoint: blobEndpoint
  }
  dependsOn: [
    edgeRuntime
  ]
}

// Deployment output
output difyAppUrl string = edgeRuntime.outputs.difyAppUrl
output acaDefaultDomain string = platform.outputs.acaDefaultDomain
