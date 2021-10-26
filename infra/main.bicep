
targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'
@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string
@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

// Azure Data Factory
@description('Specifies whether the self-hosted integration runtimes should be deployed. This only works, if the pwsh script was uploded and is available.')
param deploySelfHostedIntegrationRuntimes bool = false
@description('Specifies whether the deployment was submitted through the Azure Portal.')
param portalDeployment bool = false


// Azure Machine Learning
@description('Specifies the object ID of the user who gets assigned to compute instance 001 in the Machine Learning Workspace. If you do not want to create a Compute Instance, leave this value empty as is.')
param machineLearningComputeInstance001AdministratorObjectId string = ''
@secure()
@description('Specifies the public ssh key for compute instance 001 in the Machine Learning Workspace. This parameter is optional and allows the user to connect via Visual Studio Code to the Compute Instance.')
param machineLearningComputeInstance001AdministratorPublicSshKey string = ''
@description('Specifies whether role assignments should be enabled for Synapse (Blob Storage Contributor to default storage account).')
param enableRoleAssignments bool = false
@description('Specifies the list of resource IDs of Data Lake Gen2 Containers which will be connected as datastores in the Machine Learning workspace. If you do not want to connect any datastores, provide an empty list.')
param datalakeFileSystemIds array = []

// Network
@description('Specifies the address space of the vnet of the data landing zone.')
param vnetAddressPrefix string = '10.1.0.0/16'
@description('Specifies the address space of the subnet that is used for general services of the data landing zone.')
param servicesSubnetAddressPrefix string = '10.1.0.0/24'
param connectivityHubVnetId string = ''

// Synapse
@description('Azure Active Directory Group to be assigned as SQL Active Directory Admin')
param synapseSqlAdminGroupName string = ''
@description('Object ID of Azure Active Directory Group to be assigned as SQL Active Directory Admin')
param synapseSqlAdminGroupObjectID string = ''
@secure()
@description('Specifies the administrator password of the sql servers.')
param administratorPassword string


// Private DNS Zones
@description('Specifies the resource ID of the private DNS zone for Synapse Dev.')
param privateDnsZoneIdSynapseDev string = ''
@description('Specifies the resource ID of the private DNS zone for Synapse Sql.')
param privateDnsZoneIdSynapseSql string = ''
@description('Specifies the resource ID of the private DNS zone for Synapse Studio.')
param privateDnsZoneIdSynapseStudio string = ''
@description('Specifies the resource ID of the private DNS zone for Container Registry.')
param privateDnsZoneIdContainerRegistry string = ''
@description('Specifies the resource ID of the private DNS zone for Data Factory.')
param privateDnsZoneIdDataFactory string = ''
@description('Specifies the resource ID of the private DNS zone for Data Factory Portal.')
param privateDnsZoneIdDataFactoryPortal string = ''
@description('Specifies the resource ID of the private DNS zone for Blob Storage.')
param privateDnsZoneIdBlob string = ''
@description('Specifies the resource ID of the private DNS zone for Datalake Storage.')
param privateDnsZoneIdDfs string = ''
@description('Specifies the resource ID of the private DNS zone for Key Vault.')
param privateDnsZoneIdKeyVault string = ''
@description('Specifies the resource ID of the private DNS zone for Machine Learning API.')
param privateDnsZoneIdMachineLearningApi string = ''
@description('Specifies the resource ID of the private DNS zone for Machine Learning Notebooks.')
param privateDnsZoneIdMachineLearningNotebooks string = ''


// Variables
var name = toLower('${prefix}-${environment}')
var tagsDefault = {
  Owner: 'Data & AI Quickstart'
  Project: 'Data & AI Quickstart'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)
var administratorUsername = 'SuperMainUser'
var machineLearning001Name = '${name}-machinelearning001'
var containerRegistry001Name = '${name}-containerregistry001'


// Network resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-network'
  location: location
  tags: tagsJoined
  properties: {}
}

module networkServices 'modules/network.bicep' = {
  name: 'networkServices'
  scope: networkResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    vnetAddressPrefix: vnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    connectivityHubVnetId: connectivityHubVnetId
  }
}

// Runtime resources
resource runtimesResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-runtimes'
  location: location
  tags: tagsJoined
  properties: {}
}

module runtimeServices 'modules/runtimes.bicep' = {
  name: 'runtimeServices'
  scope: runtimesResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    deploySelfHostedIntegrationRuntimes: deploySelfHostedIntegrationRuntimes
    datafactoryIds: [
      sharedIntegrationServices.outputs.datafactoryIntegration001Id
    ]
    portalDeployment: portalDeployment
  }
}

// Storage resources
resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-storage'
  location: location
  tags: tagsJoined
  properties: {}
}

module storageServices 'modules/storage.bicep' = {
  name: 'storageServices'
  scope: storageResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
  }
}

// Metadata resources
resource metadataResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-metadata'
  location: location
  tags: tagsJoined
  properties: {}
}

module metadataServices 'modules/metadata.bicep' = {
  name: 'metadataServices'
  scope: metadataResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

// Shared integration services
resource sharedIntegrationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-shared-integration'
  location: location
  tags: tagsJoined
  properties: {}
}

module sharedIntegrationServices 'modules/sharedintegration.bicep' = {
  name: 'sharedIntegrationServices'
  scope: sharedIntegrationResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    storageRawId: storageServices.outputs.storageRawId
    storageAccountRawFileSystemId: storageServices.outputs.storageRawFileSystemId
    storageEnrichedCuratedId: storageServices.outputs.storageEnrichedCuratedId
    storageAccountEnrichedCuratedFileSystemId: storageServices.outputs.storageEnrichedCuratedFileSystemId
    keyVault001Id: metadataServices.outputs.keyVault001Id
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
  }
}

// Shared product resources
resource sharedProductResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-shared-product'
  location: location
  tags: tagsJoined
  properties: {}
}

module sharedProductServices 'modules/sharedproduct.bicep' = {
  name: 'sharedProductServices'
  scope: sharedProductResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    synapseProduct001DefaultStorageAccountFileSystemId: storageServices.outputs.storageWorkspaceFileSystemId
    synapseSqlAdminGroupName: ''
    synapseSqlAdminGroupObjectID: ''
    synapseProduct001ComputeSubnetId: ''
    privateDnsZoneIdSynapseDev: privateDnsZoneIdSynapseDev
    privateDnsZoneIdSynapseSql: privateDnsZoneIdSynapseSql
  }
}

module containerRegistry001 'modules/services/containerregistry.bicep' = {
  name: 'containerRegistry001'
  scope: sharedProductResourceGroup
  params: {
    location: location
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    containerRegistryName: containerRegistry001Name
    privateDnsZoneIdContainerRegistry: privateDnsZoneIdContainerRegistry
  }
}

module machineLearning001 'modules/services/machinelearning.bicep' = {
  name: 'machineLearning001'
  scope: sharedProductResourceGroup
  params: {
    location: location
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    machineLearningName: machineLearning001Name
    //applicationInsightsId: applicationInsights001.outputs.applicationInsightsId
    containerRegistryId: containerRegistry001.outputs.containerRegistryId
    keyVaultId: metadataServices.outputs.keyVault001Id
    storageAccountId: storageServices.outputs.storageRawId
    datalakeFileSystemIds: array(storageServices.outputs.storageRawFileSystemId)
    //aksId: aksId
    //databricksAccessToken: databricksAccessToken
    //databricksWorkspaceId: databricksWorkspaceId
    //databricksWorkspaceUrl: databricksWorkspaceUrl
    synapseId: sharedProductServices.outputs.synapseId
    synapseBigDataPoolId: sharedProductServices.outputs.synapseBigDataPoolId
    machineLearningComputeInstance001AdministratorObjectId: machineLearningComputeInstance001AdministratorObjectId
    machineLearningComputeInstance001AdministratorPublicSshKey: machineLearningComputeInstance001AdministratorPublicSshKey
    privateDnsZoneIdMachineLearningApi: privateDnsZoneIdMachineLearningApi
    privateDnsZoneIdMachineLearningNotebooks: privateDnsZoneIdMachineLearningNotebooks
    enableRoleAssignments: enableRoleAssignments
  }
}

module machineLearning001RoleAssignmentContainerRegistry 'modules/auxiliary/machineLearningRoleAssignmentContainerRegistry.bicep' = if (enableRoleAssignments) {
  name: 'machineLearning001RoleAssignmentContainerRegistry'
  scope: resourceGroup(subscription().subscriptionId, sharedProductResourceGroup.name)
  params: {
    containerRegistryId: containerRegistry001.name
    machineLearningId: machineLearning001.outputs.machineLearningId
  }
}

module machineLearning001RoleAssignmentStorage 'modules/auxiliary/machineLearningRoleAssignmentStorage.bicep' = [ for (datalakeFileSystemId, i) in datalakeFileSystemIds : if(enableRoleAssignments) {
  name: 'machineLearning001RoleAssignmentStorage-${i}'
  scope: storageResourceGroup
  params: {
    machineLearningId: machineLearning001.outputs.machineLearningId
    storageAccountFileSystemId: datalakeFileSystemId
  }
}]

// Data integration resources 001
resource dataIntegration001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-di001'
  location: location
  tags: tagsJoined
  properties: {}
}

resource dataIntegration002ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-di002'
  location: location
  tags: tagsJoined
  properties: {}
}

// Data product resources 001
resource dataProduct001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-dp001'
  location: location
  tags: tagsJoined
  properties: {}
}

resource dataProduct002ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-dp002'
  location: location
  tags: tagsJoined
  properties: {}
}

// Outputs
output vnetId string = networkServices.outputs.vnetId
output artifactstorage001ResourceGroupName string = split(runtimeServices.outputs.artifactstorage001Id, '/')[4]
output artifactstorage001Name string = last(split(runtimeServices.outputs.artifactstorage001Id, '/'))
output artifactstorage001ContainerName string = runtimeServices.outputs.artifactstorage001ContainerName
