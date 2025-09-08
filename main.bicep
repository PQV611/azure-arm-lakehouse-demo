param location string = resourceGroup().location
param baseName string
param cosmosAutoscaleMaxRU int = 4000

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${baseName}-kv'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A'; name: 'standard' }
    enableRbacAuthorization: true
    networkAcls: { bypass: 'AzureServices'; defaultAction: 'Deny' }
  }
}

resource adls 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${baseName}adls'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: '${baseName}-cosmos'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [ { locationName: location, failoverPriority: 0 } ]
    enableAutomaticFailover: true
    isVirtualNetworkFilterEnabled: false
    publicNetworkAccess: 'Enabled' // simplify demo; use Private Endpoints in prod
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: '${cosmos.name}/opsdb'
  properties: { resource: { id: 'opsdb' } }
}

resource cosmosColl 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: '${cosmosDb.name}/customers'
  properties: {
    resource: {
      id: 'customers'
      partitionKey: { paths: ['/pk'], kind: 'Hash' }
      indexingPolicy: { indexingMode: 'consistent' }
    }
    options: { autoscaleSettings: { maxThroughput: cosmosAutoscaleMaxRU } }
  }
}

output storageName string = adls.name
output cosmosEndpoint string = cosmos.properties.documentEndpoint
