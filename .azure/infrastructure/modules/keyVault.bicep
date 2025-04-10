// modules/keyVault.bicep - Key Vault module with random password generation

@description('The location for all resources')
param location string

@description('The name of the Key Vault')
param keyVaultName string

@description('An array of object IDs of the principals who should have access to the Key Vault')
param accessPolicies array = []

@description('The name of the secret to create')
param secretName string = 'RandomPassword'

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@description('Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = true

@description('Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = true

@description('SKU name to specify whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

// Key Vault resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    tenantId: subscription().tenantId
    accessPolicies: accessPolicies
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource randomPassword 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: '${keyVaultName}-random-password'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.5'  // Using the latest PowerShell version as of April 10, 2025
    retentionInterval: 'P1D'
    scriptContent: '''
      $chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&@_'
      $password = ''
      $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
      $passwordLength = 24
      $bytes = New-Object byte[]($passwordLength)
      
      # Ensure at least one of each character type
      $digits = $chars.Substring(0, 10).ToCharArray()
      $password += $digits[(Get-Random -Maximum $digits.Length)]  # Digit
      
      $uppercase = $chars.Substring(10, 26).ToCharArray()
      $password += $uppercase[(Get-Random -Maximum $uppercase.Length)]  # Uppercase
      
      $lowercase = $chars.Substring(36, 26).ToCharArray()
      $password += $lowercase[(Get-Random -Maximum $lowercase.Length)]  # Lowercase
      
      $special = $chars.Substring(62).ToCharArray()
      $password += $special[(Get-Random -Maximum $special.Length)]  # Special character
      
      # Fill the rest with random characters
      for ($i = 4; $i -lt $passwordLength; $i++) {
          $rng.GetBytes($bytes)
          $password += $chars[$bytes[0] % $chars.Length]
      }
      
      # Shuffle the password
      $passwordChars = $password.ToCharArray()
      $shuffledPassword = -join ($passwordChars | Get-Random -Count $passwordChars.Length)
      
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['password'] = $shuffledPassword
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
  }
}

// Create the secret in Key Vault with the generated password
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: secretName
  properties: {
    value: randomPassword.properties.outputs.password
    contentType: 'Generated on IaC Deployment'
  }
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output secretUri string = secret.properties.secretUri
output genpwd string = randomPassword.properties.outputs.password
