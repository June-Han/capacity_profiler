$ErrorActionPreference = “Stop”

$dataPath = "$home/quotautil"

Install-Module -Name MicrosoftPowerBIMgmt -Force

Write-Host 'Logging into PowerBI Service Account...' -ForegroundColor Green
Connect-PowerBIServiceAccount

$WSName = "SubsOverview"
$DSName = "AllSubs"
$tblName = "ResourcesMgmt"

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


# Creating/Retrieving workspace in PowerBI
if (WorkSpaceCheck)
{
    Write-Host "`nIntended Workspace found. Retrieving...`n"  -ForegroundColor Green
    $workspace = Get-PowerBIWorkspace -Name $WSName
    $workspace
}
else
{
    Write-Host "`nIntended Workspace not found. Creating...`n"  -ForegroundColor Red
    $workspace = New-PowerBIWorkspace -Name $WSName #Uses shared capacity
    $workspace
}

# Creating/Retrieving dataset in PowerBI
if (DataSetCheck)
{
    Write-Host "`nIntended Dataset found. Retrieving`n" -ForegroundColor Green
    $wsdataset = Get-PowerBIDataset -Name $DSName -WorkspaceId $workspace.Id
    $wsdataset
}
else 
{
    Write-Host "`nIntended Dataset not found. Creating new dataset`n" -ForegroundColor Red
    
    #Creating PowerBI Table 
    $col1 = New-PowerBIColumn -Name "datetime_in_utc" -DataType String
    $col2 = New-PowerBIColumn -Name "subscription_name" -DataType String
    $col3 = New-PowerBIColumn -Name "resource_name" -DataType String
    $col4 = New-PowerBIColumn -Name "location" -DataType String
    $col5 = New-PowerBIColumn -Name "current_value" -DataType String
    $col6 = New-PowerBIColumn -Name "limit" -DataType String
    $col7 = New-PowerBIColumn -Name "usage" -DataType String
    $table = New-PowerBITable -Name $tblName -Columns $col1, $col2, $col3, $col4, $col5, $col6, $col7

    # Create Dataset (Subscription_Data)
    $dataset = New-PowerBIDataset -Name $DSName -Tables $table

    # Adding dataset to workspace
    $wsdataset = Add-PowerBIDataset -Dataset $dataset -WorkspaceId $workspace.Id

    Write-Host "`nCreated Workspace Dataset`n" -ForegroundColor Green
    $wsdataset
}

# Iterate each CSV file and send to PowerBI
Get-ChildItem $dataPath -Filter "*.csv" |ForEach-Object { 

    $file=$_              
    
    #Import csv and add column with filename
    Write-Host "`nPopulating table in dataset...`n" -ForegroundColor Green

    # Send data to PowerBI
    Add-PowerBIRow -DatasetId $wsdataset.Id -TableName $tblName -Rows (Import-Csv $file.FullName)
    Write-Host "`n===== Dataset Export to PowerBI is a success =====`n" -ForegroundColor Green
}