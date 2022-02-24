param logAnalyticsWorkspaceName string
param location string
param sku string = 'PerGB2018'
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
  })
}

output WorkspaceId string = logAnalyticsWorkspace.properties.customerId 
output WorkspaceResourceId string = logAnalyticsWorkspace.id
output WorkspaceKey string =  listKeys(logAnalyticsWorkspace.id, '2015-03-20').primarySharedKey
