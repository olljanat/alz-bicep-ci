$global:location = "westeurope"
$global:DeployChangesMode = $false
if ($DeployChanges -eq "true") {
    $global:DeployChangesMode = $true
}

switch($environment) {
    "lab" {
        $global:tenantID = "13a69a3b-cf5f-4204-b274-3e9ce5240a60"
        $global:managementGroupId = "mg-sdw-root"
        $platformManagementSubscriptionID = "ed7cb4e2-3819-437c-b99e-eaf8d73438e3"
        $connectivitySubscriptionId = "ed7cb4e2-3819-437c-b99e-eaf8d73438e3"
    }
    "acc" {
        $global:tenantID = "13a69a3b-cf5f-4204-b274-3e9ce5240a60"
        $global:managementGroupId = "mg-sdw-root"
        $platformManagementSubscriptionID = "ed7cb4e2-3819-437c-b99e-eaf8d73438e3"
        $connectivitySubscriptionId = "ed7cb4e2-3819-437c-b99e-eaf8d73438e3"
    }
    "prd" {
        $global:tenantID = "13a69a3b-cf5f-4204-b274-3e9ce5240a60"
        $global:managementGroupId = "mg-sdw-root"
        $platformManagementSubscriptionID = "ed7cb4e2-3819-437c-b99e-eaf8d73438e3"
        $connectivitySubscriptionId = "ed7cb4e2-3819-437c-b99e-eaf8d73438e3"
        if ((-not $env:BUILD_BUILDNUMBER) -and $DeployChanges -eq "true") {
            Write-Host "Deployment to Production outside of CI/CD is not allowed. Switching to '-DeployChanges `"false`"'" -ForegroundColor Yellow
            $global:DeployChangesMode = $false
        }
    }
    default {
        throw "Environment $environment is not supported"
    }
}

. "$PSScriptRoot/.functions.ps1"

Test-BicepVersion

if ((az account show | ConvertFrom-JSON).homeTenantId -ne $tenantID) {
    Write-Host "##[warning] No valid session to correct Azure tenant. Will re-login..." -ForegroundColor Yellow
    az logout
    az login --tenant $tenantID | ConvertFrom-JSON
}
