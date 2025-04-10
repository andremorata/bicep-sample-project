// main.bicep - Orchestrator for the entire infrastructure
// This file demonstrates deploying a Next.js frontend and a .NET 9 WebAPI backend
// using a modular approach

// Parameters with default values
param location string = resourceGroup().location
param environmentName string = 'dev'
param appServicePlanName string = 'plan-${environmentName}'
param frontendAppName string = 'frontend-${environmentName}'  // Next.js app
param backendApiName string = 'backend-${environmentName}'    // .NET 9 WebAPI
param appInsightsName string = 'insights-${environmentName}'
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'
param postgreSqlServerName string = 'psql-${environmentName}-${uniqueString(resourceGroup().id)}'
param postgreSqlDbName string = 'mydb'
param administratorLogin string = 'adminuser'
param keyVaultName string = 'kv-${environmentName}-${uniqueString(resourceGroup().id)}'
param dbPasswordSecretName string = 'PostgresAdminPassword'

// Module: App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeploy'
  params: {
    location: location
    appServicePlanName: appServicePlanName
  }
}

// Module: Application Insights
module appInsights './modules/appInsights.bicep' = {
  name: 'appInsightsDeploy'
  params: {
    location: location
    appInsightsName: appInsightsName
  }
}

// Module: Storage Account
module storage './modules/storageAccount.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

// Module: Key Vault with Random Password - Generate the password first
module keyVault './modules/keyVault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    location: location
    keyVaultName: keyVaultName
    secretName: dbPasswordSecretName  // Generate PostgreSQL admin password
    // Initially creating without access policies to avoid circular dependency
    accessPolicies: []
  }
}

// Module: PostgreSQL Database - Using generated password
module postgres './modules/postgresql.bicep' = {
  name: 'postgresDeploy'
  params: {
    location: location
    serverName: postgreSqlServerName
    databaseName: postgreSqlDbName
    administratorLogin: administratorLogin
    administratorPassword: keyVault.outputs.genpwd // Use the generated password from Key Vault
  }
}

// Module: Frontend Web App (Next.js)
module frontendApp './modules/webApp.bicep' = {
  name: 'frontendAppDeploy'
  params: {
    location: location
    webAppName: frontendAppName
    appServicePlanId: appServicePlan.outputs.id
    runtimeStack: 'NODE|22-lts'  // For Next.js app
    appSettings: [
      // Only add environment variables needed for the frontend
      {
        name: 'NODE_ENV'
        value: 'production'
      }
      {
        name: 'BACKEND_API_URL'
        value: 'https://${backendApi.outputs.hostName}'
      }
      {
        name: 'KEY_VAULT_URI'
        value: keyVault.outputs.keyVaultUri
      }
    ]
  }
}

// Module: Backend Web App (.NET 9 WebAPI)
module backendApi './modules/webApp.bicep' = {
  name: 'backendApiDeploy'
  params: {
    location: location
    webAppName: backendApiName
    appServicePlanId: appServicePlan.outputs.id
    runtimeStack: 'DOTNET|9.0'  // For .NET 9 WebAPI
    appSettings: [
      // Application Insights configuration
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.connectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~3'
      }
      // Key Vault reference for DB connection string (using managed identity)
      {
        name: 'KeyVault__Uri'
        value: keyVault.outputs.keyVaultUri
      }
      {
        name: 'KeyVault__DbPasswordSecretName'
        value: dbPasswordSecretName
      }
      // For simpler access, we still add the direct connection strings
      // In a production environment, consider using only Key Vault references
      {
        name: 'ConnectionStrings__PostgresConnection'
        value: postgres.outputs.connectionString
      }
      {
        name: 'ConnectionStrings__StorageConnection'
        value: storage.outputs.connectionString
      }
      // Environment settings
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: 'Production'
      }
      // Enable Managed Identity for secure connections
      {
        name: 'WEBSITE_ENABLE_MANAGED_IDENTITY'
        value: 'true'
      }
    ]
  }
}

// Add access policies to Key Vault after web apps are created
resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: backendApi.outputs.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        objectId: frontendApp.outputs.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Outputs (important for accessing created resources)
output frontendUrl string = frontendApp.outputs.url
output backendUrl string = backendApi.outputs.url
output storageAccountName string = storage.outputs.name
output postgresServerFqdn string = postgres.outputs.serverFQDN
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
