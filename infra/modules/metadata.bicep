// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create metadata resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdKeyVault string = ''

// Variables
var keyVault001Name = '${prefix}-vault001'
var keyVault002Name = '${prefix}-vault002'

// Resources
module keyVault001 'services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyVault001Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

module keyVault002 'services/keyvault.bicep' = {
  name: 'keyVault002'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyVault002Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}


// Outputs
output keyVault001Id string = keyVault001.outputs.keyvaultId
