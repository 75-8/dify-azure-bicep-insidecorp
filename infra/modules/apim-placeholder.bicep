@description('Resource location')
param location string

@description('APIM service name')
param apimName string = 'dify-apim'

@description('Publisher email')
param publisherEmail string = 'ops@example.com'

@description('Publisher name')
param publisherName string = 'dify'

@description('APIM SKU name')
param skuName string = 'Developer'

@description('Whether to deploy APIM (default: false). Keep false to avoid deploying APIM by accident')
param deployApim bool = false

resource apim 'Microsoft.ApiManagement/service@2021-08-01' = if (deployApim) {
  name: apimName
  location: location
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

output apimId string = deployApim ? apim.id : ''
