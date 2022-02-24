
targetScope = 'subscription'

// General parameters
param deployOnpremiseInfra bool = true

// Hub and Spokes parameters
param hubandspokesLocation string = 'centralindia'

param hubRgName string = 'rg-hub'
param hubVnetName string = 'vnet-hub'
param hubVnetAddressSpace string = '10.221.0.0/21'
param hubVnetSubnets array = [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: '10.221.0.0/24'
    }            
  }
  {
    name: 'snet-default'
    properties: {
      addressPrefix: '10.221.1.0/24'
    }
  }
]
param hubAsn int = 65000

param spoke01RgName string = 'rg-spoke01'
param spoke01VnetName string = 'vnet-spoke01'
param spoke01VnetAddressSpace string = '10.221.8.0/24'
param spoke01VnetSubnets array = [
  {
    name: 'snet-default'
    properties: {
      addressPrefix: '10.221.8.0/24'
    }            
  }
]

param spoke02RgName string = 'rg-spoke02'
param spoke02VnetName string = 'vnet-spoke02'
param spoke02VnetAddressSpace string = '10.221.9.0/24'
param spoke02VnetSubnets array = [
  {
    name: 'snet-default'
    properties: {
      addressPrefix: '10.221.9.0/24'
    }            
  }
]

// On-premise parameters
param onpremLocation string = 'canadacentral'
param onpremRgName string = 'rg-onpremise'
param onpremVnetName string = 'vnet-onpremise'
param onpremVnetAddressSpace string = '10.233.0.0/21'
param onpremVnetSubnets array = [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: '10.233.0.0/24'
    }            
  }
  {
    name: 'snet-default'
    properties: {
      addressPrefix: '10.233.1.0/24'
    }
  }
]
param onpremAsn int = 64000

// Network monitoring parameters
param networkMonitoringRgName string = 'rg-networkmonitoring'
param networkMonitoringRgLocation string = hubandspokesLocation
param networkMonitoringLawName string = 'law-networkmonitoring'

// VM parameters
param VmSize string = 'Standard_B1ls'
param adminUsername string = 'microsoft'
param adminPassword string = 'Microsoft=1Microsoft=1'
param VmOsType string = 'Linux' 
param VmOsPublisher string = 'canonical' 
param VmOsOffer string = 'UbuntuServer' 
param VmOsSku string = '18_04-lts-gen2' 
param VmOsVersion string = 'latest'

// S2S VPN parameters
param VpnSku string = 'VpnGw1'
param VpnSharedKey string = 'davidsantiago123'

// HUB
resource hubRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubRgName
  location: hubandspokesLocation
}

module hubVnet 'modules/Vnet.bicep' = {
  name: 'hubVnet'
  scope: hubRg
  params:{
    vnetname: hubVnetName
    location: hubandspokesLocation
    addressSpace: hubVnetAddressSpace
    subnets: hubVnetSubnets
  }
}

module hubVnetGwPip 'modules/Pip.bicep' = if (deployOnpremiseInfra) {
  name: 'hubVnetGwPip'
  scope: hubRg
  params:{
    name: 'hubgwpip01'
    location: hubandspokesLocation
  }
}

module hubVnetGw 'modules/VnetGw.bicep' = if (deployOnpremiseInfra) {
  name: 'hubVnetGw'
  scope: hubRg
  params:{
    name: 'hubgw01'
    location: hubandspokesLocation
    publicIpAddressId: hubVnetGwPip.outputs.id
    subnetId: '${hubVnet.outputs.id}/subnets/GatewaySubnet'
    sku: VpnSku
    asn: hubAsn
  }
}

module hubLng 'modules/Lng.bicep' = if (deployOnpremiseInfra) {
  name: 'hubLng'
  scope: hubRg
  params:{
    name: 'hublng01'
    location: hubandspokesLocation
    asn: onpremAsn
    bgpPeeringAddress: onpremVnetGw.outputs.bgpPeeringAddress
    gatewayIpAddress: onpremVnetGwPip.outputs.ipAddress
  }
}

module hubConnection 'modules/Connections.bicep' = if (deployOnpremiseInfra) {
  name: 'hubConnection'
  scope: hubRg
  params: {
    location: hubandspokesLocation
    connectionName: 'Connection_to_OnPremise'
    localNetworkGatewayId: hubLng.outputs.id
    virtualNetworkGatewayId: hubVnetGw.outputs.id
    sharedKey: VpnSharedKey
  }
}

module hubToSpoke01VnetPeering 'modules/VnetPeering.bicep' = {
  name: 'hubToSpoke01VnetPeering'
  scope: hubRg
  params: {
    virtualNetworkName: hubVnetName
    remoteVirtualNetworkId: spoke01Vnet.outputs.id
    remoteVirtualNetworkName: spoke01VnetName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

module hubToSpoke02VnetPeering 'modules/VnetPeering.bicep' = {
  name: 'hubToSpoke02VnetPeering'
  scope: hubRg
  params: {
    virtualNetworkName: hubVnetName
    remoteVirtualNetworkId: spoke02Vnet.outputs.id
    remoteVirtualNetworkName: spoke02VnetName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

module hubVm './modules/Vm.bicep' = {
  name: 'hubVm'
  scope: hubRg
  params: {
    VmName: 'vm-hub'
    VmSubnetId: '${hubVnet.outputs.id}/subnets/snet-default'
    VmLocation: hubandspokesLocation
    VmSize: VmSize
    VmOsType: VmOsType 
    VmOsPublisher: VmOsPublisher 
    VmOsOffer: VmOsOffer 
    VmOsSku: VmOsSku
    VmOsVersion: VmOsVersion
    adminUsername: adminUsername 
    adminPassword: adminPassword
    WorkspaceId: networkMonitoringLaw.outputs.WorkspaceId
    WorkspaceKey: networkMonitoringLaw.outputs.WorkspaceKey
  }
}

// SPOKE01
resource spoke01Rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spoke01RgName
  location: hubandspokesLocation
}

module spoke01Vnet 'modules/Vnet.bicep' = {
  name: 'spoke01Vnet'
  scope: spoke01Rg
  params:{
    vnetname: spoke01VnetName
    location: hubandspokesLocation
    addressSpace: spoke01VnetAddressSpace
    subnets: spoke01VnetSubnets
  }
}

module spoke01VnetPeering 'modules/VnetPeering.bicep' = if (!deployOnpremiseInfra) {
  name: 'spoke01VnetPeering'
  scope: spoke01Rg
  params: {
    virtualNetworkName: spoke01VnetName
    remoteVirtualNetworkId: hubVnet.outputs.id
    remoteVirtualNetworkName: hubVnetName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

module spoke01VnetPeering2 'modules/VnetPeering.bicep' = if (deployOnpremiseInfra) {
  name: 'spoke01VnetPeering2'
  scope: spoke01Rg
  params: {
    virtualNetworkName: spoke01VnetName
    remoteVirtualNetworkId: hubVnet.outputs.id
    remoteVirtualNetworkName: hubVnetName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
  dependsOn:[
    onpremVnetGw
    hubVnetGw
  ]
}

module spoke01Vm './modules/Vm.bicep' = {
  name: 'spoke01Vm'
  scope: spoke01Rg
  params: {
    VmName: 'vm-spoke01'
    VmSubnetId: '${spoke01Vnet.outputs.id}/subnets/snet-default'
    VmLocation: hubandspokesLocation
    VmSize: VmSize
    VmOsType: VmOsType 
    VmOsPublisher: VmOsPublisher 
    VmOsOffer: VmOsOffer 
    VmOsSku: VmOsSku
    VmOsVersion: VmOsVersion
    adminUsername: adminUsername 
    adminPassword: adminPassword
    WorkspaceId: networkMonitoringLaw.outputs.WorkspaceId
    WorkspaceKey: networkMonitoringLaw.outputs.WorkspaceKey
  }
}


// SPOKE02
resource spoke02Rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spoke02RgName
  location: hubandspokesLocation
}

module spoke02Vnet 'modules/Vnet.bicep' = {
  name: 'spoke02Vnet'
  scope: spoke02Rg
  params:{
    vnetname: spoke02VnetName
    location: hubandspokesLocation
    addressSpace: spoke02VnetAddressSpace
    subnets: spoke02VnetSubnets
  }
}

module spoke02VnetPeering 'modules/VnetPeering.bicep' = if (!deployOnpremiseInfra) {
  name: 'spoke02VnetPeering'
  scope: spoke02Rg
  params: {
    virtualNetworkName: spoke02VnetName
    remoteVirtualNetworkId: hubVnet.outputs.id
    remoteVirtualNetworkName: hubVnetName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

module spoke02VnetPeering2 'modules/VnetPeering.bicep' = if (deployOnpremiseInfra) {
  name: 'spoke02VnetPeering2'
  scope: spoke02Rg
  params: {
    virtualNetworkName: spoke02VnetName
    remoteVirtualNetworkId: hubVnet.outputs.id
    remoteVirtualNetworkName: hubVnetName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
  dependsOn:[
    onpremVnetGw
    hubVnetGw
  ]
}

module spoke02Vm './modules/Vm.bicep' = {
  name: 'spoke02Vm'
  scope: spoke02Rg
  params: {
    VmName: 'vm-spoke02'
    VmSubnetId: '${spoke02Vnet.outputs.id}/subnets/snet-default'
    VmLocation: hubandspokesLocation
    VmSize: VmSize
    VmOsType: VmOsType 
    VmOsPublisher: VmOsPublisher 
    VmOsOffer: VmOsOffer 
    VmOsSku: VmOsSku
    VmOsVersion: VmOsVersion
    adminUsername: adminUsername 
    adminPassword: adminPassword
    WorkspaceId: networkMonitoringLaw.outputs.WorkspaceId
    WorkspaceKey: networkMonitoringLaw.outputs.WorkspaceKey
  }
}

// ON-PREMISE
resource onpremRg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (deployOnpremiseInfra) {
  name: onpremRgName
  location: onpremLocation
}

module onpremVnet 'modules/Vnet.bicep' = if (deployOnpremiseInfra) {
  name: 'onpremVnet'
  scope: onpremRg
  params:{
    vnetname: onpremVnetName
    location: onpremLocation
    addressSpace: onpremVnetAddressSpace
    subnets: onpremVnetSubnets
  }
}

module onpremVnetGwPip 'modules/Pip.bicep' = if (deployOnpremiseInfra) {
  name: 'onpremVnetGwPip'
  scope: onpremRg
  params:{
    name: 'onpremisegwpip01'
    location: onpremLocation
  }
}

module onpremVnetGw 'modules/VnetGw.bicep' = if (deployOnpremiseInfra) {
  name: 'onpremVnetGw'
  scope: onpremRg
  params:{
    name: 'onpremisegw01'
    location: onpremLocation
    publicIpAddressId: onpremVnetGwPip.outputs.id
    subnetId: '${onpremVnet.outputs.id}/subnets/GatewaySubnet'
    sku: VpnSku
    asn: onpremAsn
  }
}

module onpremLng 'modules/Lng.bicep' = if (deployOnpremiseInfra) {
  name: 'onpremLng'
  scope: onpremRg
  params:{
    name: 'onpremiselng01'
    location: onpremLocation
    asn: hubAsn
    bgpPeeringAddress: hubVnetGw.outputs.bgpPeeringAddress
    gatewayIpAddress: hubVnetGwPip.outputs.ipAddress
  }
}

module onpremConnection 'modules/Connections.bicep' = if (deployOnpremiseInfra) {
  name: 'onpremConnection'
  scope: onpremRg
  params: {
    location: onpremLocation
    connectionName: 'Connection_to_AzureHub'
    localNetworkGatewayId: onpremLng.outputs.id
    virtualNetworkGatewayId: onpremVnetGw.outputs.id
    sharedKey: VpnSharedKey
  }
}

module onpremVm './modules/Vm.bicep' = if (deployOnpremiseInfra) {
  name: 'onpremVm'
  scope: onpremRg
  params: {
    VmName: 'vm-onprem'
    VmSubnetId: '${onpremVnet.outputs.id}/subnets/snet-default'
    VmLocation: onpremLocation
    VmSize: VmSize
    VmOsType: VmOsType 
    VmOsPublisher: VmOsPublisher 
    VmOsOffer: VmOsOffer 
    VmOsSku: VmOsSku
    VmOsVersion: VmOsVersion
    adminUsername: adminUsername 
    adminPassword: adminPassword
    WorkspaceId: networkMonitoringLaw.outputs.WorkspaceId
    WorkspaceKey: networkMonitoringLaw.outputs.WorkspaceKey
  }
}

// NETWORK MONITORING
resource networkMonitoringRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkMonitoringRgName
  location: networkMonitoringRgLocation
}

module networkMonitoringLaw 'modules/Law.bicep' = {
  name: 'networkMonitoringLaw'
  scope: networkMonitoringRg
  params: {
    logAnalyticsWorkspaceName: networkMonitoringLawName
    location: networkMonitoringRgLocation
  }
}

module networkWatcher 'modules/NetworkWatcher.bicep' = {
  name: 'networkWatcher'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    networkWatcherName: 'NetworkWatcher_${networkMonitoringRgLocation}'
    location: networkMonitoringRgLocation
  }
}

module connectionMonitor 'modules/ConnectionMonitor.bicep' = {
  name: 'connectionMonitor'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: networkMonitoringRgLocation
    networkWatcherName: 'NetworkWatcher_${networkMonitoringRgLocation}'
    connectionMonitorName: 'NetworkMonitoring'
    endpoints: [
      {
        name: 'hubVM'
        type: 'AzureVM'
        resourceId: hubVm.outputs.VirtualMachineId
      }
      {
        name: 'spoke1VM'
        type: 'AzureVM'
        resourceId: spoke01Vm.outputs.VirtualMachineId
      }
      {
        name: 'spoke2VM'
        type: 'AzureVM'
        resourceId: spoke02Vm.outputs.VirtualMachineId
      }
      {
        name: 'onpremVM'
        type: 'ExternalAddress'
        address: onpremVm.outputs.NicPrivateIpAddress
      }
      {
        name: 'ident.me'
        type: 'ExternalAddress'
        address: 'http://ident.me'
      }
    ]
    testConfigurations: [
      {
        name: 'ssh'
        testFrequencySec: 30
        protocol: 'Tcp'
        tcpConfiguration: {
          port: 22
          disableTraceRoute: false
        }
      }
      {
        name: 'http'
        testFrequencySec: 30
        protocol: 'Http'
        httpConfiguration: {
          method: 'Get'
          port: 80
          preferHTTPS: false
          requestHeaders: []
          validStatusCodeRanges: [
            '200'
          ]
        }
      }
    ]
    testGroups: [
      {
        name: 'Monitor_HubVM_to_Spoke1VM__SSH'
        disable: false
        testConfigurations:[
          'ssh'
        ]
        sources: [
          'hubVM'
        ]
        destinations:[
          'spoke1VM'
        ]
      }
      {
        name: 'Monitor_HubVM_to_Spoke2VM__SSH'
        disable: false
        testConfigurations:[
          'ssh'
        ]
        sources: [
          'hubVM'
        ]
        destinations:[
          'spoke2VM'
        ]
      }
      {
        name: 'Monitor_HubVM_to_OnpremVM__SSH'
        disable: false
        testConfigurations:[
          'ssh'
        ]
        sources: [
          'hubVM'
        ]
        destinations:[
          'onpremVM'
        ]
      }
      {
        name: 'Monitor_spoke2VM_to_Ident.me__HTTP'
        disable: false
        testConfigurations:[
          'http'
        ]
        sources: [
          'spoke2VM'
        ]
        destinations:[
          'ident.me'
        ]
      }
    ]
    workspaceResourceId: networkMonitoringLaw.outputs.WorkspaceResourceId
  }
}
