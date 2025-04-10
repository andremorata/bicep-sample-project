// modules/webApp.bicep - Web App module

@description('The location for all resources')
param location string

@description('The name of the web app')
param webAppName string

@description('The ID of the App Service Plan to use')
param appServicePlanId string

@description('Runtime stack for the web app')
@allowed([
  'DOTNET|9.0'
  'NODE|22-lts'
])
param runtimeStack string = 'DOTNET|9.0'

@description('Docker image to use (only when using containers)')
param dockerImage string = ''

@description('Application settings for the web app')
param appSettings array = []

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: !empty(dockerImage) ? 'DOCKER|${dockerImage}' : runtimeStack
      appSettings: appSettings
      // Different configuration settings based on app type
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
    }
  }
  identity: {
    type: 'SystemAssigned' // Enable managed identity for the web app
  }
}

// Outputs
output name string = webApp.name
output hostName string = webApp.properties.defaultHostName
output url string = 'https://${webApp.properties.defaultHostName}'
output id string = webApp.id
output principalId string = webApp.identity.principalId
