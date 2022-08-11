Function Deploy-AlzResource {
    param (
        [Parameter(Mandatory = $true)][String]$DeploymentType,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ResourceType,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TemplateFile,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TemplateParameterFile,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$DeploymentNamePrefix
    )
    $DeploymentName = "$($(git config user.name) -replace ' ','')-$DeploymentNamePrefix-$(Get-Date -Format 'yyyyMMddhhmm')"
    if ($env:BUILD_BUILDNUMBER) {
        $DeploymentName = "AzureDevOps-$DeploymentNamePrefix-$env:BUILD_BUILDNUMBER"
    }
    switch($DeploymentType) {
        "TenantDeployment" {
            $result = az deployment tenant what-if `
                --template-file $TemplateFile `
                --parameters $TemplateParameterFile `
                --location $location `
                --exclude-change-types Ignore NoChange `
                --name "$($DeploymentName)-whatif" `
                --only-show-errors

            if (-not ($result | Where-Object {$_ -eq "Resource changes: no change."})) {
                if ($global:DeployChangesMode -ne $true) {
                    Write-Host "##vso[task.logissue type=warning;] $environment - $ResourceType - Found difference between code and environment" -ForegroundColor Yellow
                }

                Write-Host "##[warning]$ResourceType - Found following changes" -ForegroundColor Yellow
                $result

                if ($result | Where-Object {$_ -like "*- Delete*"}) {
                    throw "$ResourceType - Current code would trigger DELETE operation which is not allowed"
                }

                if ($global:DeployChangesMode -eq $true) {
                    Write-Host "##[section] $ResourceType - Will deploy changes..." -ForegroundColor Green
                    az deployment tenant create `
                        --template-file $TemplateFile `
                        --parameters $TemplateParameterFile `
                        --location $location `
                        --name $DeploymentName `
                        --only-show-errors
                }
            } else {
                Write-Host "##[section] $ResourceType - No changes found..." -ForegroundColor Green
            }
        }

        "ManagementGroupDeployment" {
            $result = az deployment mg what-if `
                --template-file $TemplateFile `
                --parameters $TemplateParameterFile `
                --location $location `
                --management-group-id $managementGroupId `
                --exclude-change-types Ignore NoChange `
                --name "$($DeploymentName)-whatif" `
                --only-show-errors

            if (-not ($result | Where-Object {$_ -eq "Resource changes: no change."})) {
                if ($global:DeployChangesMode -ne $true) {
                    Write-Host "##vso[task.logissue type=warning;] $environment - $ResourceType - Found difference between code and environment" -ForegroundColor Yellow
                }

                Write-Host "##[warning]$ResourceType - Found following changes" -ForegroundColor Yellow
                $result

                if ($result | Where-Object {$_ -like "*- Delete*"}) {
                    throw "$ResourceType - Current code would trigger DELETE operation which is not allowed"
                }

                if ($global:DeployChangesMode -eq $true) {
                    Write-Host "##[section] $ResourceType - Will deploy changes..." -ForegroundColor Green
                    az deployment mg create `
                        --template-file $TemplateFile `
                        --parameters $TemplateParameterFile `
                        --location $location `
                        --management-group-id $managementGroupId `
                        --name $DeploymentName `
                        --only-show-errors
                }
            } else {
                Write-Host "##[section] $ResourceType - No changes found..." -ForegroundColor Green
            }
        }

        "SubscriptionDeployment" {
            $result = az deployment sub what-if `
                --template-file $TemplateFile `
                --parameters $TemplateParameterFile `
                --location $location `
                --exclude-change-types Ignore NoChange `
                --name "$($DeploymentName)-whatif" `
                --only-show-errors

            if (-not ($result | Where-Object {$_ -eq "Resource changes: no change."})) {
                if ($global:DeployChangesMode -ne $true) {
                    Write-Host "##vso[task.logissue type=warning;] $environment - $ResourceType - Found difference between code and environment" -ForegroundColor Yellow
                }

                Write-Host "##[warning]$ResourceType - Found following changes" -ForegroundColor Yellow
                $result

                if ($result | Where-Object {$_ -like "*- Delete*"}) {
                    throw "$ResourceType - Current code would trigger DELETE operation which is not allowed"
                }

                if ($global:DeployChangesMode -eq $true) {
                    Write-Host "##[section] $ResourceType - Will deploy changes..." -ForegroundColor Green
                    az deployment sub create `
                        --template-file $TemplateFile `
                        --parameters $TemplateParameterFile `
                        --location $location `
                        --name $DeploymentName `
                        --only-show-errors
                }
            } else {
                Write-Host "##[section] $ResourceType - No changes found..." -ForegroundColor Green
            }
        }

        "ResourceGroupDeployment" {

            # Handle issue where WhatIf mode reports that all "virtualNetworkPeerings" and "remoteVirtualNetworkPeerings" values would be removed
            if ($ResourceType -eq "HubNetworking") {
                $global:result = "Resource changes: no change."

                $whatIfJSON = az deployment group what-if `
                    --template-file $TemplateFile `
                    --parameters $TemplateParameterFile `
                    --resource-group $ResourceGroup `
                    --exclude-change-types Ignore NoChange `
                    --name "$($DeploymentName)-whatif" `
                    --only-show-errors `
                    --no-pretty-print
                $whatIf = $whatIfJSON | ConvertFrom-Json -Depth 999

                $objectsToDelete = $whatIf.changes.delta | Where-Object {$_.propertyChangeType -eq "Delete" -and $_.path -ne "properties.virtualNetworkPeerings" -and $_.path -ne "properties.remoteVirtualNetworkPeerings"}
                if ($objectsToDelete) {
                    Write-Host "##[warning]$ResourceType - Found following changes including unsupported DELETE operations" -ForegroundColor Yellow
                    Write-Host "##[warning]Note that 'properties.virtualNetworkPeerings' and 'properties.remoteVirtualNetworkPeerings' deletes are noise, those will not be deployed" -ForegroundColor Yellow
                    az deployment group what-if `
                    --template-file $TemplateFile `
                    --parameters $TemplateParameterFile `
                    --resource-group $ResourceGroup `
                    --exclude-change-types Ignore NoChange `
                    --name "$($DeploymentName)-whatif" `
                    --only-show-errors

                    Write-Host "Here is also non-formatted JSON version of that output for debug reasons:"
                    $whatIfJSON
                    throw "$ResourceType - Current code would trigger DELETE operation which is not allowed"
                } else {
                    $changes = $whatIf.changes.delta | Where-Object {$_.propertyChangeType -ne "Delete" -and $_.propertyChangeType -ne "NoEffect"}
                    if ($changes) {
                        Write-Host "##[warning]$ResourceType - Found following changes" -ForegroundColor Yellow
                        $global:result = ""
                        az deployment group what-if `
                        --template-file $TemplateFile `
                        --parameters $TemplateParameterFile `
                        --resource-group $ResourceGroup `
                        --exclude-change-types Ignore NoChange `
                        --name "$($DeploymentName)-whatif" `
                        --only-show-errors
                    }
                }

            } else {
                $global:result = az deployment group what-if `
                    --template-file $TemplateFile `
                    --parameters $TemplateParameterFile `
                    --resource-group $ResourceGroup `
                    --exclude-change-types Ignore NoChange `
                    --name "$($DeploymentName)-whatif" `
                    --only-show-errors
            }

            if (-not ($result | Where-Object {$_ -eq "Resource changes: no change."})) {
                if ($global:DeployChangesMode -ne $true) {
                    Write-Host "##vso[task.logissue type=warning;] $environment - $ResourceType - Found difference between code and environment" -ForegroundColor Yellow
                }

                Write-Host "##[warning]$ResourceType - Found following changes" -ForegroundColor Yellow
                Write-Host "##[warning]Note that 'properties.virtualNetworkPeerings' and 'properties.remoteVirtualNetworkPeerings' deletes are noise, those will not be deployed" -ForegroundColor Yellow
                $result

                if ($result | Where-Object {$_ -like "*- Delete*"}) {
                    throw "$ResourceType - Current code would trigger DELETE operation which is not allowed"
                }

                if ($global:DeployChangesMode -eq $true) {
                    Write-Host "##[section] $ResourceType - Will deploy changes..." -ForegroundColor Green
                    az deployment group create `
                        --template-file $TemplateFile `
                        --parameters $TemplateParameterFile `
                        --resource-group $ResourceGroup `
                        --name $DeploymentName `
                        --only-show-errors
                }
            } else {
                Write-Host "##[section] $ResourceType - No changes found..." -ForegroundColor Green
            }
        }

        default {
            throw "Deployment type $DeploymentType is not supported"
        }
    }
}

Function Test-BicepVersion {
    $bicepVersion = (((az bicep version) -split "Bicep CLI version ")[1] -split " \(")[0]
    $bicepVersionParts = $bicepVersion -split "\."

    # Versions 1.x.x
    if ($bicepVersionParts[0] -gt 0) {
        return
    }

    # Version 0.9.1 - 0.9.999
    if ($bicepVersionParts[1] -eq 9 -and $bicepVersionParts[2] -ge 1) {
        return
    }

    # Version 0.10.0 ...
    if ($bicepVersionParts[1] -gt 9) {
        return
    }

    throw "Bicep version: $bicepVersion is older than expected version >= 0.9.1"
}
