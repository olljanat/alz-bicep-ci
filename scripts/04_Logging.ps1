param (
    [string]$DeployChanges = "false",
    [string]$environment = "lab"
)

. "$PSScriptRoot/.settings.ps1"

az account set --subscription $platformManagementSubscriptionID

Deploy-AlzResource `
    -DeploymentType "SubscriptionDeployment" `
    -ResourceType "Logging - ResourceGroup" `
    -TemplateFile "$PSScriptRoot/../standard/ALZ-Bicep/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/04_Logging/resourceGroup.logging.parameters.$($environment)ESLZ.json" `
    -DeploymentNamePrefix "create_logging_rg"


$resourceGroup = (Get-Content "$PSScriptRoot/../parameters/04_Logging/resourceGroup.logging.parameters.$($environment)ESLZ.json" | ConvertFrom-JSON).parameters.parResourceGroupName.value

Deploy-AlzResource `
    -DeploymentType "ResourceGroupDeployment" `
    -ResourceType "Logging" `
    -TemplateFile "$PSScriptRoot/../standard/ALZ-Bicep/infra-as-code/bicep/modules/logging/logging.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/04_Logging/logging.parameters.$($environment)ESLZ.json" `
    -ResourceGroup $ResourceGroup `
    -DeploymentNamePrefix "create_logging"
