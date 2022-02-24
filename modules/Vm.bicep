param VmName string
param VmSubnetId string
param VmLocation string
param VmSize string
param VmOsType string 
param VmOsPublisher string 
param VmOsOffer string 
param VmOsSku string 
param VmOsVersion string 
param adminUsername string
param adminPassword string

param WorkspaceId string
param WorkspaceKey string

resource Nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${VmName}ni01'
  location: VmLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: VmSubnetId
          }
          primary: true
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}


resource VirtualMachine 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: VmName
  location: VmLocation
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      osDisk: {
        name: '${VmName}od01'
        createOption: 'FromImage'
        osType: VmOsType
      }
      imageReference: {
        publisher: VmOsPublisher
        offer: VmOsOffer
        sku: VmOsSku
        version: VmOsVersion
      }
    }
    osProfile: {
      computerName: VmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Nic.id
        }
      ]
    }
  }
}

output VirtualMachineId string = VirtualMachine.id
output NicPrivateIpAddress string = Nic.properties.ipConfigurations[0].properties.privateIPAddress

resource VirtualMachineExtensionLawLinux 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (VmOsType == 'Linux') {
  name: '${VmName}/OmsAgentForLinux'
  location: VmLocation
  properties:{
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.14'
    autoUpgradeMinorVersion: true
    settings:{
      workspaceId: WorkspaceId
    }
    protectedSettings:{
      workspaceKey: WorkspaceKey 
    }
  }
  dependsOn:[
    VirtualMachine
  ]
}

resource VirtualMachineExtensionNetworkWatcherLinux 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (VmOsType == 'Linux') {
  name: '${VmName}/NetworkWatcherAgentLinux'
  location: VmLocation
  properties:{
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
  }
  dependsOn:[
    VirtualMachine
  ]
}


resource VirtualMachineExtensionLawWindows 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (VmOsType == 'Windows') {
  name: '${VmName}/MicrosoftMonitoringAgent'
  location: VmLocation
  properties:{
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings:{
      workspaceId: WorkspaceId
    }
    protectedSettings:{
      workspaceKey: WorkspaceKey
    }
  }
  dependsOn:[
    VirtualMachine
  ]
}

resource VirtualMachineExtensionNetworkWatcherWindows 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (VmOsType == 'Windows') {
  name: '${VmName}/NetworkWatcherAgentWindows'
  location: VmLocation
  properties:{
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
  }
  dependsOn:[
    VirtualMachine
  ]
}
