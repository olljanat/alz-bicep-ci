Function Deploy-AlzResource {
    param (
        [Parameter(Mandatory = $true)][String]$DeploymentType,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ResourceType,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TemplateFile,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TemplateParameterFile,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$DeploymentNamePrefix
    )
    $DeploymentName = "$($env:USERNAME)-$DeploymentNamePrefix-$(Get-Date -Format 'yyyyMMddhhmm')"
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
            $result = az deployment group what-if `
                --template-file $TemplateFile `
                --parameters $TemplateParameterFile `
                --resource-group $ResourceGroup `
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
