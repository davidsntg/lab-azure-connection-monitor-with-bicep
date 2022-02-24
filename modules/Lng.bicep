param name string
param location string
param asn int
param bgpPeeringAddress string
param gatewayIpAddress string

resource Lng 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: name
  location: location
  properties: {
    bgpSettings: {
      asn: asn
      bgpPeeringAddress: bgpPeeringAddress
    }
    gatewayIpAddress: gatewayIpAddress
  }
}

output id string = Lng.id
