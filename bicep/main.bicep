targetScope = 'subscription'

param location string
param rgName string
param deployAks bool
param deployVms bool

@secure()
param adminSshKey string
param adminUsername string

param vmConfigs array

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

module vnetwork 'modules/network.bicep' = if (deployVms || deployAks) {
  scope: rg
  name: 'vnetworkDeployment'
  params: {
    location: location
    vnetName: 'vnet-bicep-prod-02'
  }
}

module vms 'modules/vm.bicep' = [for vm in vmConfigs: if (deployVms) {
  scope: rg
  name: 'vmDeployment-${vm.name}'
  params: {
    location: location
    vmName: vm.name
    subnetId: deployVms ? vnetwork!.outputs.subnetId : ''
    adminUsername: adminUsername
    vmSize: vm.vmSize
    imageSku: vm.imageSku
    adminSshKey: adminSshKey
  }
}]

module aks 'modules/aks.bicep' = if (deployAks) {
  scope: rg
  name: 'aksDeployment'
  params: {
    location: location
    clusterName: 'aks-bicep-prod-02'
  }
}
