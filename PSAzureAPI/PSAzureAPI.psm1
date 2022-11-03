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
    $Body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
    $Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Body -ContentType 'application/x-www-form-urlencoded'
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

    $Body = @"
{
  "properties": {
    "templateLink": {
      "uri": "https://example.com/exampleTemplate.json"
    },
    "parameters": {},
    "mode": "incremental",
    "debugSetting": {
        "detailLevel": "responseContent"
    },
    "whatIfSettings": {
        "resultFormat": "FullResourcePayloads"
    },
  }
}
"@

    # $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Resources/deployments/$DeploymentName/whatIf?api-version=2021-04-01"
    $Uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName/providers/Microsoft.Resources/deployments/$DeploymentName/whatIf?api-version=2021-04-01"
    $result = Invoke-RestMethod -Method Post -Uri $Uri -Body $Body -ContentType 'application/json'  -Headers $AzureApiAuthenticationHeaders
    return $result
}
