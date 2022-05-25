param (
    [string]$DeployChanges = "false",
    [string]$environment = "lab"
)

. "$PSScriptRoot/.settings.ps1"

az account set --subscription $connectivitySubscriptionId

Deploy-AlzResource `
    -DeploymentType "SubscriptionDeployment" `
    -ResourceType "HubNetworking - ResourceGroup" `
    -TemplateFile "$PSScriptRoot/../standard/ALZ-Bicep/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/05_HubNetworking/resourceGroup.hubNetworking.parameters.$($environment)ESLZ.json" `
    -DeploymentNamePrefix "create_hub_network_rg"


$resourceGroup = (Get-Content "$PSScriptRoot/../parameters/05_HubNetworking/resourceGroup.hubNetworking.parameters.$($environment)ESLZ.json" | ConvertFrom-JSON).parameters.parResourceGroupName.value

Deploy-AlzResource `
    -DeploymentType "ResourceGroupDeployment" `
    -ResourceType "HubNetworking" `
    -TemplateFile "$PSScriptRoot/../standard/ALZ-Bicep/infra-as-code/bicep/modules/hubNetworking/hubNetworking.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/05_HubNetworking/hubNetworking.parameters.$($environment)ESLZ.json" `
    -ResourceGroup $ResourceGroup `
    -DeploymentNamePrefix "create_hub_network"
