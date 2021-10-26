targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object

param vnetAddressPrefix string = '10.1.0.0/16'
param servicesSubnetAddressPrefix string = '10.1.0.0/24'
param connectivityHubVnetId string = ''
var connectivityHubVnetSubscriptionId = length(split(connectivityHubVnetId, '/')) >= 9 ? split(connectivityHubVnetId, '/')[2] : subscription().subscriptionId
var connectivityHubVnetResourceGroupName = length(split(connectivityHubVnetId, '/')) >= 9 ? split(connectivityHubVnetId, '/')[4] : resourceGroup().name
var connectivityHubVnetName = length(split(connectivityHubVnetId, '/')) >= 9 ? last(split(connectivityHubVnetId, '/')) : 'incorrectSegmentLength'

var servicesSubnetName = 'ServicesSubnet'

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: '${prefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
    }
    enableDdosProtection: false
    subnets: [
      {
        name: servicesSubnetName
        properties: {
          addressPrefix: servicesSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
    ]
  }
}

resource connectivityHubVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = if (!empty(connectivityHubVnetId)) {
  name: connectivityHubVnetName
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: connectivityHubVnetId
    }
    useRemoteGateways: false
  }
}

module connectivityHubDataLandingZoneVnetPeering 'auxiliary/connectivityHubVnetPeering.bicep' = if (!empty(connectivityHubVnetId)) {
  name: 'dataManagementZoneDataLandingZoneVnetPeering-${prefix}'
  scope: resourceGroup(connectivityHubVnetSubscriptionId, connectivityHubVnetResourceGroupName)
  params: {
    dataLandingZoneVnetId: vnet.id
    connectivityHubVnetId: connectivityHubVnetId
  }
}

output vnetId string = vnet.id
output servicesSubnetId string = vnet.properties.subnets[0].id
