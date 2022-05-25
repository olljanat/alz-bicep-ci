param (
    [string]$DeployChanges = "false",
    [string]$environment = "lab"
)

. "$PSScriptRoot/.settings.ps1"

Deploy-AlzResource `
    -DeploymentType "ManagementGroupDeployment" `
    -ResourceType "PolicyDefinitions" `
    -TemplateFile "$PSScriptRoot/../standard/ALZ-Bicep/infra-as-code/bicep/modules/policy/definitions/custom-policy-definitions.bicep" `
    -TemplateParameterFile "$PSScriptRoot/../parameters/02_PolicyDefinitions/custom-policy-definitions.parameters.$($environment)ESLZ.json" `
    -DeploymentNamePrefix "create_policy_defs"
