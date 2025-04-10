// modules/postgresql.bicep - PostgreSQL Database module

@description('The location for all resources')
param location string

@description('The name of the PostgreSQL Flexible Server')
param serverName string

@description('The name of the PostgreSQL database')
param databaseName string

@description('The administrator login username')
param administratorLogin string

@description('The administrator login password')
@secure()
param administratorPassword string

@description('PostgreSQL version')
param version string = '14'

@description('The SKU for the PostgreSQL Flexible Server')
param skuName string = 'Standard_B1ms'

@description('The tier for the PostgreSQL Flexible Server')
param tier string = 'Burstable'

@description('Storage size in GB')
param storageSizeGB int = 32

// PostgreSQL Database Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: version
    storage: {
      storageSizeGB: storageSizeGB
    }
  }
  sku: {
    name: skuName
    tier: tier
  }
}

// PostgreSQL Database
resource postgresDB 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: databaseName
  parent: postgresServer
}

// Outputs
output serverName string = postgresServer.name
output serverFQDN string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = postgresDB.name
output connectionString string = 'postgresql://${administratorLogin}:${administratorPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/${databaseName}'
