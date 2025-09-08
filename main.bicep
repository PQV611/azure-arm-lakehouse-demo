// =====================
// Params
// =====================
param location string = resourceGroup().location
@description('Lowercase letters/numbers only. Used as a prefix for resource names.')
param baseName string

// =====================
// Name helpers (unique storage name, <= 24 chars)
// =====================
var saBase = toLower('${baseName}adls${uniqueString(resourceGroup().id)}')
var saName = substring(saBase, 0, 24)

// =====================
// Key Vault
// =====================
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

// =====================
// ADLS Gen2 (StorageV2 with HNS)
// =====================
resource adls 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: saName
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

// =====================
// Outputs
// =====================
output storageAccountName string = adls.name
output keyVaultName string = kv.name
