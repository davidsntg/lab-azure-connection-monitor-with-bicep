param connectionName string
param location string = resourceGroup().location
param connectionType string =  'IPSec'
param virtualNetworkGatewayId string
param enableBgp bool = true
param sharedKey string
param localNetworkGatewayId string

resource ConnectionVPN 'Microsoft.Network/connections@2021-02-01' = {
  name: connectionName
  location: location
  properties: {
    connectionType:  connectionType    
    virtualNetworkGateway1: {
      id: virtualNetworkGatewayId
      properties: {
        
      }
    }
    enableBgp: enableBgp
    sharedKey: sharedKey
    localNetworkGateway2: {
      id: localNetworkGatewayId
      properties: {
        
      }
    }
  }
  dependsOn: []
}
