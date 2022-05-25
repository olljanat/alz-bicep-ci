// Customized version because of https://github.com/Azure/ALZ-Bicep/issues/158

targetScope = 'tenant'

param parTopLevelManagementGroupParentId string = ''

@description('Prefix for the management group hierarchy.  This management group will be created as part of the deployment.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'alz'

param parTopLevelManagementGroupSuffix string = ''

@description('Display name for top level management group.  This name will be applied to the management group prefix defined in parTopLevelManagementGroupPrefix parameter.')
@minLength(2)
param parTopLevelManagementGroupDisplayName string = 'Azure Landing Zones'

@description('Set Parameter to true to Opt-out of deployment telemetry')
param parTelemetryOptOut bool = false

// Platform and Child Management Groups
var varPlatformMG = {
  name: '${parTopLevelManagementGroupPrefix}-Platform'
  displayName: '${parTopLevelManagementGroupPrefix}-Platform'
}

var varPlatformManagementMG = {
  name: '${parTopLevelManagementGroupPrefix}-Management'
  displayName: '${parTopLevelManagementGroupPrefix}-Management'
}

var varPlatformConnectivityMG = {
  name: '${parTopLevelManagementGroupPrefix}-Connectivity'
  displayName: '${parTopLevelManagementGroupPrefix}-Connectivity'
}

var varPlatformIdentityMG = {
  name: '${parTopLevelManagementGroupPrefix}-Identity'
  displayName: '${parTopLevelManagementGroupPrefix}-Identity'
}

// Landing Zones & Child Management Groups
var varLandingZoneMG = {
  name: '${parTopLevelManagementGroupPrefix}-LandingZones'
  displayName: '${parTopLevelManagementGroupPrefix}-LandingZones'
}

var varLandingZonePrdMG = {
  name: '${parTopLevelManagementGroupPrefix}-prd'
  displayName: '${parTopLevelManagementGroupPrefix}-prd'
}

var varLandingZoneAccMG = {
  name: '${parTopLevelManagementGroupPrefix}-acc'
  displayName: '${parTopLevelManagementGroupPrefix}-acc'
}

var varLandingZoneDevMG = {
  name: '${parTopLevelManagementGroupPrefix}-dev'
  displayName: '${parTopLevelManagementGroupPrefix}-dev'
}

// Sandbox Management Group
var varSandboxManagementGroup = {
  name: '${parTopLevelManagementGroupPrefix}-Sandbox'
  displayName: '${parTopLevelManagementGroupPrefix}-Sandbox'
}

// Decomissioned Management Group
var varDecommissionedManagementGroup = {
  name: '${parTopLevelManagementGroupPrefix}-Decommissioned'
  displayName: '${parTopLevelManagementGroupPrefix}-Decommissioned'
}

// Customer Usage Attribution Id
var varCuaid = '9b7965a0-d77c-41d6-85ef-ec3dfea4845b'

// Level 1
resource resTopLevelMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${parTopLevelManagementGroupPrefix}${parTopLevelManagementGroupSuffix}'
  properties: {
    displayName: parTopLevelManagementGroupDisplayName
    details: {
      parent: {
        id: parTopLevelManagementGroupParentId
      }
    }
  }
}

// Level 2
resource resPlatformMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varPlatformMG.name
  properties: {
    displayName: varPlatformMG.displayName
    details: {
      parent: {
        id: resTopLevelMG.id
      }
    }
  }
}

resource resLandingZonesMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varLandingZoneMG.name
  properties: {
    displayName: varLandingZoneMG.displayName
    details: {
      parent: {
        id: resTopLevelMG.id
      }
    }
  }
}

resource resSandboxMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varSandboxManagementGroup.name
  properties: {
    displayName: varSandboxManagementGroup.displayName
    details: {
      parent: {
        id: resTopLevelMG.id
      }
    }
  }
}

resource resDecommissionedMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varDecommissionedManagementGroup.name
  properties: {
    displayName: varDecommissionedManagementGroup.displayName
    details: {
      parent: {
        id: resTopLevelMG.id
      }
    }
  }
}

// Level 3 - Child Management Groups under Platform MG
resource resPlatformManagementMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varPlatformManagementMG.name
  properties: {
    displayName: varPlatformManagementMG.displayName
    details: {
      parent: {
        id: resPlatformMG.id
      }
    }
  }
}

resource resPlatformConnectivityMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varPlatformConnectivityMG.name
  properties: {
    displayName: varPlatformConnectivityMG.displayName
    details: {
      parent: {
        id: resPlatformMG.id
      }
    }
  }
}

resource resPlatformIdentityMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varPlatformIdentityMG.name
  properties: {
    displayName: varPlatformIdentityMG.displayName
    details: {
      parent: {
        id: resPlatformMG.id
      }
    }
  }
}

// Level 3 - Child Management Groups under Landing Zones MG
resource resLandingZonesPrdMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varLandingZonePrdMG.name
  properties: {
    displayName: varLandingZonePrdMG.displayName
    details: {
      parent: {
        id: resLandingZonesMG.id
      }
    }
  }
}

resource resLandingZonesAccMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varLandingZoneAccMG.name
  properties: {
    displayName: varLandingZoneAccMG.displayName
    details: {
      parent: {
        id: resLandingZonesMG.id
      }
    }
  }
}

resource resLandingZonesDevMG 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: varLandingZoneDevMG.name
  properties: {
    displayName: varLandingZoneDevMG.displayName
    details: {
      parent: {
        id: resLandingZonesMG.id
      }
    }
  }
}

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../../standard/ALZ-Bicep/infra-as-code/bicep/CRML/customerUsageAttribution/cuaIdTenant.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params
  name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
  params: {}
}


// Output Management Group IDs
output outTopLevelMGId string = resTopLevelMG.id

output outPlatformMGId string = resPlatformMG.id
output outPlatformManagementMGId string = resPlatformManagementMG.id
output outPlatformConnectivityMGId string = resPlatformConnectivityMG.id
output outPlatformIdentityMGId string = resPlatformIdentityMG.id

output outLandingZonesMGId string = resLandingZonesMG.id
output outLandingZonesPrdMGId string = resLandingZonesPrdMG.id
output outLandingZonesAccMGId string = resLandingZonesAccMG.id
output outLandingZonesDevMGId string = resLandingZonesDevMG.id

output outSandboxMGId string = resSandboxMG.id

output outDecommissionedMGId string = resDecommissionedMG.id

// Output Management Group Names
output outTopLevelMGName string = resTopLevelMG.name

output outPlatformMGName string = resPlatformMG.name
output outPlatformManagementMGName string = resPlatformManagementMG.name
output outPlatformConnectivityMGName string = resPlatformConnectivityMG.name
output outPlatformIdentityMGName string = resPlatformIdentityMG.name

output outLandingZonesMGName string = resLandingZonesMG.name
output outLandingZonesPrdMGName string = resLandingZonesPrdMG.name
output outLandingZonesAccMGName string = resLandingZonesAccMG.name
output outLandingZonesDevMGName string = resLandingZonesDevMG.name

output outSandboxMGName string = resSandboxMG.name

output outDecommissionedMGName string = resDecommissionedMG.name
