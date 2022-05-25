param (
    [string]$DeployChanges = "false",
    [string]$environment = "lab"
)

. "$PSScriptRoot/.settings.ps1"

Deploy-AlzResource `
    -DeploymentType "ManagementGroupDeployment" `
    -ResourceType "CustomRoleDefinitions" `
    -TemplateFile "$PSScriptRoot/../standard/ALZ-Bicep/infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/03_CustomRoleDefinitions/customRoleDefinitions.parameters.$($environment)ESLZ.json" `
    -DeploymentNamePrefix "create_rbac_roles"

Deploy-AlzResource `
    -DeploymentType "ManagementGroupDeployment" `
    -ResourceType "custom - CustomRoleDefinitions" `
    -TemplateFile "$PSScriptRoot/../custom/modules/own/customRoleDefinitions.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/03_CustomRoleDefinitions/customRoleDefinitions.parameters.$($environment)ESLZ.json" `
    -DeploymentNamePrefix "create_rbac_roles-custom"
