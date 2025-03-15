  @description('Location for all resources')
  param location string = 'canadacentral'

  @description('SQL administrator username')
  param sqlAdminUsername string

  @secure()
  @description('SQL administrator password')
  param sqlAdminPassword string
  @description('This is the target deployment platform (e.g. dev/QA)')
  param deployment string

  // Virtual Network Provisioning
  resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
    name: 'vnet-${deployment}-calicot-cc-6'
    location: location
    properties: {
      addressSpace: {
        addressPrefixes: [
          '10.0.0.0/16'
        ]
      }
      subnets: [
        {
          name: 'snet-${deployment}-web-cc-6'
          properties: {
            addressPrefix: '10.0.1.0/24'
          }
        }
        {
          name: 'snet-${deployment}-db-cc-6'
          properties: {
            addressPrefix: '10.0.2.0/24'
          }
        }
      ]
    }
  }

  // App Service Plan (Standard S1)
  resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
    name: 'plan-calicot-${deployment}-6'
    location: location
    sku: {
      tier: 'Standard'
      name: 'S1'
    }
  }

  // Web App with system-assigned managed identity, HTTPS only, Always On, and ImageUrl app setting
  resource webApp 'Microsoft.Web/sites@2022-09-01' = {
    name: 'app-calicot-${deployment}-6'
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
        // Removed connectionStrings block to break circular dependency
      }
    }
    dependsOn: [
      appServicePlan
    ]
  }

  // SQL Server
  resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
    name: 'sqlsrv-calicot-${deployment}-6'
    location: location
    properties: {
      administratorLogin: sqlAdminUsername
      administratorLoginPassword: sqlAdminPassword
      version: '12.0'
    }
  }

  // SQL Database
  resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
    name: 'sqldb-calicot-${deployment}-6'
    parent: sqlServer
    location: location
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
  }

  // Key Vault with access policy for the Web App managed identity
  resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
    name: 'kv-calicot-${deployment}-6'
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
  }
