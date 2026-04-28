@description('Region for AOAI resources')
param location string

@description('Azure OpenAI account name')
param aoaiAccountName string

@description('Azure OpenAI SKU name')
param aoaiSkuName string = 'S0'

@description('Public network access setting for AOAI account')
@allowed([
  'Enabled'
  'Disabled'
])
param aoaiPublicNetworkAccess string = 'Enabled'

@description('AOAI deployment definitions')
param aoaiDeployments array

@description('Allowed public IP ranges for AOAI access. Empty means unrestricted when public access is enabled')
param aoaiAllowedIpRanges array = []

resource aoaiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aoaiAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: aoaiSkuName
  }
  properties: {
    customSubDomainName: aoaiAccountName
    publicNetworkAccess: aoaiPublicNetworkAccess
    networkAcls: {
      defaultAction: empty(aoaiAllowedIpRanges) ? 'Allow' : 'Deny'
      ipRules: [for ip in aoaiAllowedIpRanges: {
        value: ip
      }]
    }
  }
}

resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in aoaiDeployments: {
  name: deployment.name
  parent: aoaiAccount
  sku: {
    name: 'Standard'
    capacity: deployment.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: deployment.modelName
      version: deployment.modelVersion
    }
  }
}]

output aoaiResourceId string = aoaiAccount.id
output aoaiEndpoint string = 'https://${aoaiAccount.name}.openai.azure.com/'
output chatDeploymentName string = length(aoaiDeployments) > 0 ? aoaiDeployments[0].name : ''
output embeddingDeploymentName string = length(aoaiDeployments) > 1 ? aoaiDeployments[1].name : ''
