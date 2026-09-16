// main.bicep — AZ-104 lab VM, trimmed to match the original export's scope:
// VM + network settings (NIC) + OS disk. No NSG, no public IP — those were
// extras from the "fully self-contained" version, not part of what you
// originally exported.
//
// One thing this still needs that the original export didn't show: a VNet
// and subnet for the NIC to attach to. The original file didn't declare
// those because they already existed independently in the RG — but since
// we're deploying into an empty resource group, the NIC has nowhere to
// attach without them. This is the minimum possible network footprint to
// make that work: one VNet, one subnet, nothing else.

@description('Name of the VM')
param vmName string = 'vm-az104-lab'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@description('SSH public key for the admin user (paste your own — do not hardcode a private key here)')
@secure()
param sshPublicKey string

@description('VM size')
param vmSize string = 'Standard_D2s_v3'

@description('Tags applied to every resource in this deployment')
param tags object = {
  owner: 'patrick'
  'cost-centre': 'it-ops'
}

// --- Network settings ---

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-az104-lab'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-az104-lab'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmName}VMNic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// --- OS / compute ---

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmResourceId string = vm.id
