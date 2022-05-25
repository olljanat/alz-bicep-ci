param (
    [string]$DeployChanges = "false",
    [string]$environment = "lab"
)

. "$PSScriptRoot/.settings.ps1"

Deploy-AlzResource `
    -DeploymentType "TenantDeployment" `
    -ResourceType "ManagementGroups" `
    -TemplateFile "$PSScriptRoot/../custom/modules/ALZ-Bicep/managementGroups.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/01_ManagementGroups/managementGroups.parameters.$($environment)ESLZ.json" `
    -DeploymentNamePrefix "create_mgs"
