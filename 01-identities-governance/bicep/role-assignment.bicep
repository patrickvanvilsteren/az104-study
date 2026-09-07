// role-assignment.bicep
param principalId string
param principalType string = 'Group'
param contributorRoleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor role

var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, contributorRoleId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}
