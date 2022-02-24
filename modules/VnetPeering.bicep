


param virtualNetworkName string
param remoteVirtualNetworkId string
param remoteVirtualNetworkName string
param allowVirtualNetworkAccess bool
param allowForwardedTraffic bool
param allowGatewayTransit bool
param useRemoteGateways bool

resource PeeringHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${virtualNetworkName}/Peering-To-${remoteVirtualNetworkName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkId
    }
  }
}

