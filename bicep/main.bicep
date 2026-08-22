targetScope = 'subscription'

param location string = 'germanywestcentral'
param rgName string = 'rg-bicep-foundation-prod'
param deployAks bool = false
param deployVms bool = false

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

module vm 'modules/vm.bicep' = if (deployVms) {
  scope: rg
  name: 'vmDeployment'
  params: {
    location: location
    vmName: 'vm-bicep-prod-01'
    subnetId: deployVms ? vnetwork!.outputs.subnetId : ''
    adminUsername: 'azureadmin'
    sshPubKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... (mock-key-for-testing)' 
  }
}


module aks 'modules/aks.bicep' = if (deployAks) {
  scope: rg
  name: 'aksDeployment'
  params: {
    location: location
    clusterName: 'aks-bicep-prod-01'
  }
}
