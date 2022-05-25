# About
This repository contains code which is used to manage Azure Enterprise Scale Landing Zone with Bicep.

# Contributing
Deployment scripts on "scripts" folder are configured on way that without parameters those will run on [what if](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if) mode against of LAB environment.

You can trigger actual deployment by using `-DeployChanges "true"` parameter.

You can also run script against of Acceptance environment by using `-environment "acc"`

You can also run script against of Production environment by using `-environment "prd"`


However actual deployments against of production environment (`-DeployChanges "true" -environment "prd"`) is denied by script because purpose is validate code changes through pull requests first and let CI/CD on Azure DevOps to do actual deployments.

## Folder Structure
High level description of folder structure.
More detailed structure is described on subfolders.
```
|- custom                          # Root folder for SD Worx custom modules
|- standard                        # Root folder for standardized open source modules
|- parameters                      # Root folder for paramenter files
|- scrips                          # Folder for deployment scripts
|- definitions                     # Folder for Azure Pipelines YAML definitions
```

# Known issues and made decisions
Because of these known issues/not yet approved pull requests we are currently forced to use partly customized versions of ALZ-Bicep modules:
* https://github.com/Azure/ALZ-Bicep/issues/158

Because of these issues we are not currently using following parts of this of this solution:
* Logging: WhatIf does not works correctly because of https://github.com/Azure/arm-template-whatif/issues/176 and https://github.com/Azure/arm-template-whatif/issues/251 which why we currently cannot enable CI for logging.

# Setup
## Service connection for CI
* Create service connection like described on [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops#create-an-azure-resource-manager-service-connection-with-an-existing-service-principal)
* Try deployment and find object id from error message
* Assign full rights for service connections with command:
```powershell
az login
az role assignment create --role "Owner" --scope "/" --assignee "<object Id>"
```
* For more information look: https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin
