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
    vnetName: 'vnet-bicep-prod-01'
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
    clusterName: 'aks-bicep-prod-01'
  }
}

// targetScope = 'subscription'

// param location string = 'swedencentral'
// param rgName string = 'rg-bicep-foundation-prod'
// param deployAks bool = false
// param deployVms bool = false

// @secure()
// param adminSshKey string

// resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   name: rgName
//   location: location
// }

// module vnetwork 'modules/network.bicep' = if (deployVms || deployAks) {
//   scope: rg
//   name: 'vnetworkDeployment'
//   params: {
//     location: location
//     vnetName: 'vnet-bicep-prod-01'
//   }
// }

// module vm_amd 'modules/vm.bicep' = if (deployVms) {
//   scope: rg
//   name: 'vmAmdDeployment'
//   params: {
//     location: location
//     vmName: 'cloud-node-02'
//     subnetId: deployVms ? vnetwork!.outputs.subnetId : ''
//     adminUsername: 'zshamsadd'
//     vmSize: 'Standard_B2ats_v2'
//     imageSku: '22_04-lts-gen2'
//     adminSshKey: adminSshKey
//   }
// }

// module vm_arm 'modules/vm.bicep' = if (deployVms) {
//   scope: rg
//   name: 'vmArmDeployment'
//   params: {
//     location: location
//     vmName: 'cloud-node-03'
//     subnetId: deployVms ? vnetwork!.outputs.subnetId : ''
//     adminUsername: 'zshamsadd'
//     vmSize: 'Standard_B2pts_v2'
//     imageSku: '22_04-lts-arm64'
//     adminSshKey: adminSshKey
//   }
// }

// module aks 'modules/aks.bicep' = if (deployAks) {
//   scope: rg
//   name: 'aksDeployment'
//   params: {
//     location: location
//     clusterName: 'aks-bicep-prod-01'
//   }
// }
