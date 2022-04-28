# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
# ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.

$context = Get-azContext

if (!$context)
{
    Write-Output "There is no existing session.  Logging into Azure."
    Clear-AzContext -Force
    Connect-AzAccount
}

# retrives region list across the resources, and pull all the subscriptions in the tenant.
$locations = Get-AzResource | ForEach-Object {$_.Location} | Sort-Object |  Get-Unique
$subscriptions = Get-AzSubscription

Write-Output $locations

$json = ''

# loops through subscription list
foreach($subscription in $subscriptions)
{
    # set the context from the current subscription
    Set-AzContext -Subscription $subscription
    $currentAzContext = Get-AzContext
    
    # Get VM Quota and Utilization
    foreach ($location in $locations)
    {
        # Get a list of Compute resources under the current subscription context
        $vmQuotas = Get-AzVMUsage -Location $location -ErrorAction SilentlyContinue 
        
        # Get usage data of each Compute resources 
        foreach($vmQuota in $vmQuotas)
        {
            $usage = 0
            
            if ($vmQuota.Limit -gt 0)
            {
                $usage = $vmQuota.CurrentValue / $vmQuota.Limit 
            }

            $json += @"
            { 
                "Name":"$($vmQuota.Name.LocalizedValue)", 
                "Category":"Compute", 
                "Location":"$location", 
                "CurrentValue":$($vmQuota.CurrentValue), 
                "Limit":$($vmQuota.Limit),
                "Usage":$usage
            },
"@
        }
    }

    # Get Network Quota and Utilization
    foreach ($location in $locations)
    {
        $networkQuotas = Get-AzNetworkUsage -Location $location -ErrorAction SilentlyContinue 
        foreach ($networkQuota in $networkQuotas)
        {  
            $usage = 0
            
            if ($networkQuota.limit -gt 0) 
            { 
                $usage = $networkQuota.currentValue / $networkQuota.limit 
            }
            
            $json += @"
            { 
                "Name":"$($networkQuota.name.localizedValue)", 
                "Category":"Network",
                "Location":"$location", 
                "CurrentValue":$($networkQuota.currentValue), 
                "Limit":$($networkQuota.limit),
                "Usage":$usage 
            },
"@
        }
    }
