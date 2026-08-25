using 'main.bicep'

param location = 'swedencentral'
param rgName = 'rg-bicep-foundation-prod'
param deployAks = false
param deployVms = true

param adminUsername = ''
param adminSshKey = ''

param vmConfigs = [
  {
    name: 'cloud-node-03'
    vmSize: 'Standard_B2ats_v2'
    imageSku: '22_04-lts-gen2'
  }
  {
    name: 'cloud-node-04'
    vmSize: 'Standard_B2pts_v2'
    imageSku: '22_04-lts-arm64'
  }
]
