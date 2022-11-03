Function Invoke-AzureApiLogin {
    <#
    .SYNOPSIS
        Login to Azure API
    .EXAMPLE
        Invoke-AzureApiLogin 
    #>
    param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$TenantId = $env:TenantId,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$ClientId = $env:ClientId,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$ClientSecret = $env:ClientSecret
    )

    $Resource = "https://management.core.windows.net/"
    $RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"

    # https://docs.microsoft.com/en-us/azure/active-directory/develop/v1-oauth2-client-creds-grant-flow#request-an-access-token
    $resultody = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
    $Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $resultody -ContentType 'application/x-www-form-urlencoded'
    $global:AzureApiAuthenticationHeaders = @{"Authorization" = "$($Token.token_type) "+ "$($Token.access_token)"}
}

Function Invoke-AzureApiWhatIf {
    <#
    .SYNOPSIS
        Do What If deployment
    .EXAMPLE
        Invoke-AzureApiWhatIf
    #>
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DeploymentName
    )

    # detailLevel:
    # - none
    # - requestContent
    # - responseContent
    # - requestContent,responseContent

    $requestBody = @'
{
  "properties": {
    "parameters": {
        "virtualNetworks_test_net_name": {
            "value": "test-net"
        }
    },
    "template": {
        "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            "virtualNetworks_test_net_name": {
                "defaultValue": "test-net",
                "type": "String"
            }
        },
        "variables": {},
        "resources": [
            {
                "type": "Microsoft.Network/virtualNetworks",
                "apiVersion": "2022-01-01",
                "name": "[parameters('virtualNetworks_test_net_name')]",
                "location": "westeurope",
                "tags": {
                    "foo": "bar"
                },
                "properties": {
                    "addressSpace": {
                        "addressPrefixes": [
                            "10.0.0.0/16"
                        ]
                    },
                    "virtualNetworkPeerings": [],
                    "enableDdosProtection": false
                }
            },
            {
                "type": "Microsoft.Network/virtualNetworks/subnets",
                "apiVersion": "2022-01-01",
                "name": "[concat(parameters('virtualNetworks_test_net_name'), '/default')]",
                "dependsOn": [
                    "[resourceId('Microsoft.Network/virtualNetworks', parameters('virtualNetworks_test_net_name'))]"
                ],
                "properties": {
                    "addressPrefix": "10.0.0.0/24",
                    "delegations": [],
                    "privateEndpointNetworkPolicies": "Disabled",
                    "privateLinkServiceNetworkPolicies": "Enabled"
                }
            }
        ]
    },
    "mode": "incremental",
    "debugSetting": {
        "detailLevel": "none"
    },
    "whatIfSettings": {
        "resultFormat": "FullResourcePayloads"
    },
  }
}
'@

    # $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Resources/deployments/$DeploymentName/whatIf?api-version=2021-04-01"
    $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.Resources/deployments/$DeploymentName/whatIf?api-version=2022-05-01"
    # $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.Resources/deployments/$($DeploymentName)?api-version=2022-05-01"
    $request = Invoke-WebRequest -Method POST -Uri $Uri -Body $requestBody -ContentType 'application/json' -Headers $AzureApiAuthenticationHeaders

    for ($i=0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 5
        $result = Invoke-RestMethod -Uri $request.Headers.Location[0] -Headers $AzureApiAuthenticationHeaders
        if ($result) {
            return $result
        }
    }
    throw "Failed to fetch WhatIf result from URL: $($request.Headers.Location[0])"
}

Function Get-AzureApiWhatIfParsedResult {
    <#
    .SYNOPSIS
        Do What If deployment
    .EXAMPLE
        Get-AzureApiWhatIfParsedResult
    #>
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][object]$Result,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][switch]$AllowDelete
    )

    if ($result.status -ne "Succeeded") {
        $result.error
        throw
    }

    $foundDelete = $false
    forEach($change in $result.properties.changes) {
        switch($change.changeType) {
            "Ignore" { continue }
            "NoChange" {
                Write-Host "No changes found to: '$($change.resourceId)'" -ForegroundColor green
            }
            "Modify" {
                $effectiveChanges = @()
                forEach($propertyChange in $change.delta) {
                    switch($propertyChange.propertyChangeType) {
                        "NoEffect" { continue }
                        "Delete" {

                            # Filter out known WhatIf reporting issues
                            if ($propertyChange.path -eq "properties.remoteVirtualNetworkPeerings") { continue }
                            if ($propertyChange.path -eq "properties.virtualNetworkPeerings") { continue }

                            $effectiveChanges += $propertyChange
                            $foundDelete = $true
                        }
                        default {
                            $effectiveChanges += $propertyChange
                        }
                    }
                }
                Write-Host "Found following changes to $($change.resourceId)" -ForegroundColor green
                Write-Host $($effectiveChanges | ConvertTo-Json -Depth 100)
            }
            default {
                throw "'$($change.changeType)' is unsupported change type"
            }
        }
    }

    if ($foundDelete -eq $true -and (-not ($AllowDelete))) {
        throw "Found Delete and -AllowDelete switch is not given"
    }
}

Function Invoke-AzureApiDeployment {
    <#
    .SYNOPSIS
        Do What If deployment
    .EXAMPLE
        Invoke-AzureApiDeployment
    #>
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DeploymentName
    )

    # detailLevel:
    # - none
    # - requestContent
    # - responseContent
    # - requestContent,responseContent

    $requestBody = @'
{
  "properties": {
    "parameters": {
        "virtualNetworks_test_net_name": {
            "value": "test-net"
        }
    },
    "template": {
        "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            "virtualNetworks_test_net_name": {
                "defaultValue": "test-net",
                "type": "String"
            }
        },
        "variables": {},
        "resources": [
            {
                "type": "Microsoft.Network/virtualNetworks",
                "apiVersion": "2022-05-01",
                "name": "[parameters('virtualNetworks_test_net_name')]",
                "location": "westeurope",
                "tags": {
                    "foo": "bar"
                },
                "properties": {
                    "addressSpace": {
                        "addressPrefixes": [
                            "10.0.0.0/16"
                        ]
                    },
                    "virtualNetworkPeerings": [],
                    "enableDdosProtection": false
                }
            },
            {
                "type": "Microsoft.Network/virtualNetworks/subnets",
                "apiVersion": "2022-05-01",
                "name": "[concat(parameters('virtualNetworks_test_net_name'), '/default')]",
                "dependsOn": [
                    "[resourceId('Microsoft.Network/virtualNetworks', parameters('virtualNetworks_test_net_name'))]"
                ],
                "properties": {
                    "addressPrefix": "10.0.0.0/24",
                    "delegations": [],
                    "privateEndpointNetworkPolicies": "Disabled",
                    "privateLinkServiceNetworkPolicies": "Enabled"
                }
            },
            {
                "type": "Microsoft.Network/virtualNetworks/subnets",
                "apiVersion": "2022-05-01",
                "name": "[concat(parameters('virtualNetworks_test_net_name'), '/foo')]",
                "dependsOn": [
                    "[resourceId('Microsoft.Network/virtualNetworks', parameters('virtualNetworks_test_net_name'))]"
                ],
                "properties": {
                    "addressPrefix": "10.0.3.0/24",
                    "delegations": [],
                    "privateEndpointNetworkPolicies": "Disabled",
                    "privateLinkServiceNetworkPolicies": "Enabled",
                    "routeTable": {
                        "id": "/subscriptions/b747a63d-ddb4-4f44-ab3a-76a93d7b0f48/resourceGroups/oj-test/providers/Microsoft.Network/routeTables/routeIt"
                    }
                }
            }
        ]
    },
    "mode": "incremental",
    "debugSetting": {
        "detailLevel": "none"
    }
  }
}
'@

    $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.Resources/deployments/$($DeploymentName)?api-version=2022-05-01"
    $request = Invoke-WebRequest -Method PUT -Uri $Uri -Body $requestBody -ContentType 'application/json' -Headers $AzureApiAuthenticationHeaders
    return $request
}
