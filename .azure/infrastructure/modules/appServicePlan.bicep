// modules/appServicePlan.bicep - App Service Plan module

@description('The location for all resources')
param location string

@description('The name of the App Service Plan')
param appServicePlanName string

@description('The SKU of the App Service Plan')
param sku string = 'B1'

// App Service Plan (Hosts web apps)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true // Required for Linux
  }
  sku: {
    name: sku // Default is B1 (Basic tier) - good for development
  }
  kind: 'linux'
}

// Outputs
output id string = appServicePlan.id
output name string = appServicePlan.name
