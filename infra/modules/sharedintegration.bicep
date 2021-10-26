// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create integration resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param storageAccountRawFileSystemId string
param storageAccountEnrichedCuratedFileSystemId string
param subnetId string
param storageRawId string
param storageEnrichedCuratedId string
param keyVault001Id string
param privateDnsZoneIdDataFactory string = ''
param privateDnsZoneIdDataFactoryPortal string = ''

// Variables
var datafactoryIntegration001Name = '${prefix}-integration-datafactory001'
var storageAccountRawSubscriptionId = length(split(storageAccountRawFileSystemId, '/')) >= 13 ? split(storageAccountRawFileSystemId, '/')[2] : subscription().subscriptionId
var storageAccountRawResourceGroupName = length(split(storageAccountRawFileSystemId, '/')) >= 13 ? split(storageAccountRawFileSystemId, '/')[4] : resourceGroup().name
var storageAccountEnrichedCuratedSubscriptionId = length(split(storageAccountEnrichedCuratedFileSystemId, '/')) >= 13 ? split(storageAccountEnrichedCuratedFileSystemId, '/')[2] : subscription().subscriptionId
var storageAccountEnrichedCuratedResourceGroupName = length(split(storageAccountEnrichedCuratedFileSystemId, '/')) >= 13 ? split(storageAccountEnrichedCuratedFileSystemId, '/')[4] : resourceGroup().name

// Resources


module datafactoryIntegration001 'services/datafactorysharedintegration.bicep' = {
  name: 'datafactoryIntegration001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    datafactoryName: datafactoryIntegration001Name
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    storageRawId: storageRawId
    storageEnrichedCuratedId: storageEnrichedCuratedId
    keyVault001Id: keyVault001Id
  }
}

module datafactory001StorageRawRoleAssignment 'auxiliary/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactory001StorageRawRoleAssignment'
  scope: resourceGroup(storageAccountRawSubscriptionId, storageAccountRawResourceGroupName)
  params: {
    datafactoryId: datafactoryIntegration001.outputs.datafactoryId
    storageAccountFileSystemId: storageAccountRawFileSystemId
  }
}

module datafactory001StorageEnrichedCuratedRoleAssignment 'auxiliary/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactory001StorageEnrichedCuratedRoleAssignment'
  scope: resourceGroup(storageAccountEnrichedCuratedSubscriptionId, storageAccountEnrichedCuratedResourceGroupName)
  params: {
    datafactoryId: datafactoryIntegration001.outputs.datafactoryId
    storageAccountFileSystemId: storageAccountEnrichedCuratedFileSystemId
  }
}

// Outputs
output datafactoryIntegration001Id string = datafactoryIntegration001.outputs.datafactoryId
