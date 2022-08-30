#Clear-Host

$ErrorActionPreference = “Stop”

$dataPath = "$home/quotautil"

 
#Create Archive Folder 

new-item -Name “Archive” -Force -ItemType directory -Path $dataPath  | Out-Null

<# 
Import-Module “$currentPath\Modules\PowerBIPS” -Force 
Install-Module PowerBIPS
Import-Module -Name PowerBIPS
#>

Install-Module -Name MicrosoftPowerBIMgmt -Force

$WSName = "SubsOverview"
$DSName = "AllSubs"

function WorkSpaceCheck() 
{
    if (Get-PowerBIWorkspace -Name $WSName) 
    { 
        Write-Host '[ YES ] Intended Workspace Found' -ForegroundColor Green
        return $true
    } 
    else
    { 
        Write-Host '[ NO ] Intended Workspace Not Found' -ForegroundColor Red
        return $false 
    }
}

function DataSetCheck() {
    if (Get-PowerBIDataset -Name $DSName -WorkspaceId $workspace.id)
    {
        Write-Host '[ YES ] Intended Dataset Found' -ForegroundColor Green
        return $true
    }
    else 
    {
        Write-Host '[ NO ] Intended Dataset Not Found' -ForegroundColor Red
        return $false
    }
}

if (WorkSpaceCheck)
{
    Write-Host "`nWorkspace found. Retrieving`n"  
    $workspace = Get-PowerBIWorkspace -Name $WSName
}
else
{
    Write-Host "`nWorkspace not found. Creating...`n"  
    $workspace = New-PowerBIWorkspace -Name $WSName #Uses shared capacity
}

if (DataSetCheck)
{

}
else 
{

}

# Iterate each CSV file and send to PowerBI

Get-ChildItem $dataPath -Filter "*.csv" |ForEach-Object { 

    $file=$_  
    Write-Host "`n===== Check 1 =====`n"              

    #Import csv and add column with filename

    $data = Import-Csv $file.FullName | Select-Object @{Label="File";Expression={$file.Name}}, *

    Write-Host "`n===== Check 2 =====`n" 
    Install-Module -Name MicrosoftPowerBIMgmt -Force
    Connect-PowerBIServiceAccount
    Write-Host "`n===== Check 3 =====`n" 
    # Send data to PowerBI
    $data |  Out-PowerBI -dataSetName "Subscription_Data" -tableName "Resources" 
    -types @{
        "Resources.datetime_in_utc"="datetime"; 
        "Resources.subscription_name"="string"; 
        "Resources.resource_name"="string";
        "Resources.location"="string";
        "Resources.current_value"="int64";
        "Resources.limit"="int64";
        "Resources.usage"="int64";
    } -batchSize 300 -verbose

    Write-Host "`n===== Check 4 =====`n" 

    # Archive the file
    Move-Item $file.FullName "$dataPath\Archive\" -Force

}
