@description('Resource group location')
param location string

@description('APIM resource name')
param apimName string

@description('Publisher display name')
param publisherName string = 'insidecorp'

@description('Publisher email address')
param publisherEmail string = 'admin@example.com'

@description('SKU for APIM')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Consumption'

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: skuName
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    publicNetworkAccess: 'Enabled'
  }
}

output apimId string = apim.id
output apimNameOut string = apim.name
output principalId string = apim.identity.principalId
