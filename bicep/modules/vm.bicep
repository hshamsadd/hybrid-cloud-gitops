param location string
param vmName string
param subnetId string
param adminUsername string
param vmSize string
param imageSku string
param adminSshKey string

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [{
      name: 'ipconfig1'
      properties: {
        subnet: { id: subnetId }
        privateIPAllocationMethod: 'Dynamic'
        publicIPAddress: { id: publicIp.id }
      }
    }]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: { publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: imageSku, version: 'latest' }
      osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Premium_LRS' }, diskSizeGB: 64 }
    }
    networkProfile: { networkInterfaces: [{ id: nic.id }] }
  }
}

output publicIp string = publicIp.properties.ipAddress



// param location string
// param vmName string
// param subnetId string
// param adminUsername string
// param vmSize string
// param imageSku string
// param sshCaPubKey string

// var cloudInit = '''#cloud-config
// write_files:
//   - path: /etc/ssh/vault-user-ca.pub
//     permissions: '0644'
//     content: |
//       ${sshCaPubKey}
//   - path: /etc/ssh/sshd_config.d/90-vault-user-ca.conf
//     permissions: '0644'
//     content: |
//       TrustedUserCAKeys /etc/ssh/vault-user-ca.pub    
// runcmd:
//   - systemctl daemon-reload
//   - systemctl restart ssh ssh.socket
// '''

// resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
//   name: '${vmName}-pip'
//   location: location
//   sku: { name: 'Standard' }
//   properties: { publicIPAllocationMethod: 'Static' }
// }

// resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
//   name: '${vmName}-nic'
//   location: location
//   properties: {
//     ipConfigurations: [{
//       name: 'ipconfig1'
//       properties: { 
//         subnet: { id: subnetId }
//         privateIPAllocationMethod: 'Dynamic' 
//         publicIPAddress: { id: publicIp.id }
//       }
//     }]
//   }
// }

// resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
//   name: vmName
//   location: location
//   properties: {
//     hardwareProfile: { vmSize: vmSize }
//     osProfile: {
//       computerName: vmName
//       adminUsername: adminUsername
//       customData: base64(cloudInit)
//       linuxConfiguration: {
//         disablePasswordAuthentication: true
//         ssh: { 
//           publicKeys: [
//             { 
//               path: '/home/${adminUsername}/.ssh/authorized_keys'
//               keyData: sshCaPubKey
//             }
//           ] 
//         }
//       }
//     }
//     storageProfile: {
//       imageReference: { publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: imageSku, version: 'latest' }
//       // To force exactly 64GB Premium SSD to guarantee it consumes the Free P6 Tier meter
//       osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Premium_LRS' }, diskSizeGB: 64 }
//     }
//     networkProfile: { networkInterfaces: [{ id: nic.id }] }
//   }
// }

// output publicIp string = publicIp.properties.ipAddress
