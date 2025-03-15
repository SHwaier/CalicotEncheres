@description('Location for all resources')
param location string = 'canadacentral'

@description('Unique identification code for resource naming (e.g., 6 or cc-6)')
param code string

@description('SQL administrator username')
param sqlAdminUsername string

@secure()
@description('SQL administrator password')
param sqlAdminPassword string

// Virtual Network Provisioning
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-dev-calicot-cc-${code}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-dev-web-cc-${code}'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-dev-db-cc-${code}'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// App Service Plan (Standard S1)
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: 'plan-calicot-dev-${code}'
  location: location
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
}

// Web App with system-assigned managed identity, HTTPS only, Always On, and ImageUrl app setting
resource webApp 'Microsoft.Web/sites@2021-03-01' = {
  name: 'app-calicot-dev-${code}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'ImageUrl'
          value: 'https://stcalicotprod000.blob.core.windows.net/images/'
        }
      ]
      // Optional: add connection string referencing the Key Vault secret
      connectionStrings: [
        {
          name: 'ConnectionStrings'
          connectionString: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/ConnectionStrings/)'
          type: 'SQLAzure'
        }
      ]
    }
  }
  dependsOn: [
    appServicePlan
  ]
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: 'sqlsrv-calicot-dev-${code}'
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name: 'sqldb-calicot-dev-${code}'
  parent: sqlServer
  location: location
  properties: {
    edition: 'Basic'
  }
}

// Key Vault with access policy for the Web App managed identity
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-calicot-dev-${code}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForTemplateDeployment: true
  }
  dependsOn: [
    webApp
  ]
}
