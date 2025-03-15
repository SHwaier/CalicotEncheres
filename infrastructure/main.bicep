@description('Location for all resources')
param location string = 'canadacentral'

@description('SQL administrator username')
param sqlAdminUsername string

@secure()
@description('SQL administrator password')
param sqlAdminPassword string

// Virtual Network Provisioning
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-dev-calicot-cc-6'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-dev-web-cc-6'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-dev-db-cc-6'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}
