param location string
param vnetName string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${vnetName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*' // Allows Ansible to reach it
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.20.0.0/16'] }
    subnets: [
      {
        name: 'snet-vm'
        properties: { 
          addressPrefix: '10.20.1.0/24' 
          networkSecurityGroup: { id: nsg.id }
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
