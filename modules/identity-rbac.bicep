@description('Region for the user assigned managed identity')
param location string

@description('User assigned managed identity name')
param uamiName string

@description('Azure OpenAI resource ID to scope RBAC')
param aoaiResourceId string

@description('Role definition ID for AOAI access')
param roleDefinitionId string = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

var aoaiResourceName = last(split(aoaiResourceId, '/'))

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

resource aoaiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aoaiResourceName
}

resource aoaiUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aoaiResourceId, uami.properties.principalId, roleDefinitionId)
  scope: aoaiAccount
  properties: {
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

output uamiResourceId string = uami.id
output uamiClientId string = uami.properties.clientId
output uamiPrincipalId string = uami.properties.principalId
