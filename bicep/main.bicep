targetScope = 'subscription'

param location string = 'germanywestcentral'
param rgName string = 'rg-bicep-foundation-prod'
param deployAks bool = false
param deployVms bool = false

var vaultCaPubKey = trim(loadTextContent('../vault/ssh/vault-ssh-user-ca.pub'))

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

// Node 1: AMD Architecture (Free Tier: 2 vCPU / 1GB RAM)
module vm_amd 'modules/vm.bicep' = if (deployVms) {
  scope: rg
  name: 'vmAmdDeployment'
  params: {
    location: location
    vmName: 'cloud-node-02'
    subnetId: deployVms ? vnetwork!.outputs.subnetId : ''
    adminUsername: 'zshamsadd'
    vmSize: 'Standard_B2ats_v2'
    imageSku: '22_04-lts-gen2'
    sshCaPubKey: vaultCaPubKey
  }
}

// Node 2: ARM Architecture (Free Tier: 2 vCPU / 1GB RAM)
module vm_arm 'modules/vm.bicep' = if (deployVms) {
  scope: rg
  name: 'vmArmDeployment'
  params: {
    location: location
    vmName: 'cloud-node-03'
    subnetId: deployVms ? vnetwork!.outputs.subnetId : ''
    adminUsername: 'zshamsadd'
    vmSize: 'Standard_B2pts_v2'
    imageSku: '22_04-lts-arm64'
    sshCaPubKey: vaultCaPubKey
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
