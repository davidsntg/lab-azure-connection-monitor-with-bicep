
param networkWatcherName string
param connectionMonitorName string
param location string
param endpoints array
param testConfigurations array
param testGroups array
param workspaceResourceId string

resource connectionMonitor 'Microsoft.Network/networkWatchers/connectionMonitors@2021-05-01' = {
  name: '${networkWatcherName}/${connectionMonitorName}'
  location: location
  properties:{
    endpoints: endpoints
    testConfigurations: testConfigurations
    testGroups: testGroups
    outputs:[
      {
        type: 'Workspace'
        workspaceSettings:{
          workspaceResourceId: workspaceResourceId
        }
      }
    ]
  }
}
