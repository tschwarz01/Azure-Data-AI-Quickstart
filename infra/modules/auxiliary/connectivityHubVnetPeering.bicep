// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a vnet peering connection.
targetScope = 'resourceGroup'

// Parameters
param connectivityHubVnetId string
param dataLandingZoneVnetId string

// Variables
var connectivityHubVnetName = length(split(connectivityHubVnetId, '/')) >= 9 ? last(split(connectivityHubVnetId, '/')) : 'incorrectSegmentLength'
var dataLandingZoneVnetName = length(split(dataLandingZoneVnetId, '/')) >= 9 ? last(split(dataLandingZoneVnetId, '/')) : 'incorrectSegmentLength'

// Resources
resource connectivityHubDataLandingZoneVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${connectivityHubVnetName}/${dataLandingZoneVnetName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: dataLandingZoneVnetId
    }
    useRemoteGateways: false
  }
}

// Outputs
