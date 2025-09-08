// ---------- Params ----------
param location string = resourceGroup().location
param baseName string
param cosmosAutoscaleMaxRU int = 4000

// ---------- Key Vault ----------
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${baseName}-kv'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// ---------- ADLS Gen2 ----------
resource adls 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${baseName}adls'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// ---------- Cosmos DB Account (SQL API) ----------
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: '${baseName}-cosmos'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableAutomaticFailover: true
    isVirtualNetworkFilterEnabled: false
    publicNetworkAccess: 'Enabled' // demo simplicity; use Private Endpoints in prod
    capabilities: []
  }
}

// ---------- Cosmos SQL Database ----------
resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: '${cosmos.name}/opsdb'
  properties: {
    resource: {
      id: 'opsdb'
    }
    // options optional
  }
}

// ---------- Cosmos Container ----------
resource customers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: '${cosmosDb.name}/customers'
  properties: {
    resource: {
      id: 'customers'
      partitionKey: {
        paths: ['/pk']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: cosmosAutoscaleMaxRU
      }
    }
  }
}

// ---------- Outputs ----------
output storageName string = adls.name
output cosmosEndpoint string = cosmos.properties.documentEndpoint
