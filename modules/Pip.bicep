param name string
param location string


resource Pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: name
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

output id string = Pip.id
output ipAddress string = Pip.properties.ipAddress
