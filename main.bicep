// =====================
// Params & switches
// =====================
param location string = resourceGroup().location
param baseName string

@description('Set to true to deploy Cosmos DB resources.')
param deployCosmos bool = false

@description('Cosmos region (used only when deployCosmos = true).')
param cosmosRegion string = 'eastus2'

@description('Cosmos autoscale max RU/s (used only when deployCosmos = true).')
param cosmosAutoscaleMaxRU int = 4000

// =====================
// Name helpers (unique where needed)
// =====================
var saBase = toLower('${baseName}adls${uniqueString(resourceGroup().id)}')
var saName = substring(saBase, 0, 24)

var cosmosBase = toLower('${baseName}-cosmos-${uniqueString(resourceGroup().id)}')
var cosmosName = substring(cosmosBase, 0, 44)

// =====================
// Key Vault
// =====================
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${baseName}-kv'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    networkAcls: { bypass: 'AzureServices', defaultAction: 'Deny' }
  }
}

// =====================
// ADLS Gen2 (storage)
// =====================
resource adls 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: saName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// =====================
// Cosmos DB (conditional)
// =====================
@description('Cosmos DB Account (SQL API)')
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = if (deployCosmos) {
  name: cosmosName
  location: cosmosRegion
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: cosmosRegion
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableAutomaticFailover: true
    isVirtualNetworkFilterEnabled: false
    publicNetworkAccess: 'Enabled'  // for demo; use Private Endpoints in prod
  }
}

@description('Cosmos SQL Database')
resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = if (deployCosmos) {
  name: '${cosmos.name}/opsdb'
  properties: {
    resource: { id: 'opsdb' }
  }
}

@description('Cosmos Container: customers')
resource customers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmos) {
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

// =====================
// Outputs
// =====================
output storageName string = adls.name
output cosmosEndpoint string = deployCosmos ? cosmos.properties.documentEndpoint : ''
