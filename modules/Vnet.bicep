@description('Specifies the Azure location where the resource should be created.')
param location string 

@description('Specifies the name to use for the VNet.')
param vnetname string

@description('Specifies the VNet Address Space.')
param addressSpace string 

@description('Specifies the Subnet Address Prefix for the server subnet')
param subnets array 

resource vnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetname
  location: location
  properties: {
      addressSpace: {
          addressPrefixes: [
            addressSpace
          ]
      }
      subnets: subnets
  }
}

output id string = vnet.id
//output defaultsubnetid string = '${vnet.id}/subnets/default'
