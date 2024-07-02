$excludedNodeVersions = @('~8', '~10', '~12', '~14')
$nodeFunctionApps = @()

$subscriptions = az account list `
    --query "[?tenantDefaultDomain=='rentready.com'].{id: id}" `
    --output json | ConvertFrom-Json

foreach ($subscription in $subscriptions) {
    $functionApps = az functionapp list `
        --subscription $subscription.id `
        --query "[].{name: name, resourceGroup: resourceGroup}" `
        --output json | ConvertFrom-Json

    foreach ($functionApp in $functionApps) {
        $nodeFunctionApp = az functionapp show `
            --subscription $subscription.id `
            --name $functionApp.name `
            --resource-group $functionApp.resourceGroup `
            --query "[@][?starts_with(siteConfig.nodeVersion, '~')].{name: name, resourceGroup: resourceGroup, nodeVersion: siteConfig.nodeVersion}" `
            --output json | ConvertFrom-Json

        if ($nodeFunctionApp -and `
            $nodeFunctionApp.nodeVersion -and `
            ($excludedNodeVersions -contains $nodeFunctionApp.nodeVersion)) {
            $nodeFunctionApps += [pscustomobject]@{
                Name = $nodeFunctionApp.name
                ResourceGroup = $nodeFunctionApp.resourceGroup
                NodeVersion = $nodeFunctionApp.nodeVersion
            }
        }
    }
}

$nodeFunctionApps | Format-Table -AutoSize
