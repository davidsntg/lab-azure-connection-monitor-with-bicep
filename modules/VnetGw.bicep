param name string
param location string
param gatewayType string = 'Vpn'
param subnetId string
param publicIpAddressId string
param sku string = 'VpnGw1'
param asn int

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: name
  location: location
  properties: {
    gatewayType: gatewayType
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    vpnType: 'RouteBased'
    enableBgp: true
    sku: {
      name: sku
      tier: sku
    }
    bgpSettings:{
      asn: asn
    }
  }
}

output bgpPeeringAddress string = vnetGateway.properties.bgpSettings.bgpPeeringAddress
output id string = vnetGateway.id
