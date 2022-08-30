$ErrorActionPreference = “Stop”

$dataPath = "$home/quotautil"

Install-Module -Name MicrosoftPowerBIMgmt

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
    Write-Host "`nIntended Workspace found. Retrieving`n"  
    $workspace = Get-PowerBIWorkspace -Name $WSName
}
else
{
    Write-Host "`nIntended Workspace not found. Creating...`n"  
    $workspace = New-PowerBIWorkspace -Name $WSName #Uses shared capacity
}

# Creating/Retrieving dataset in PowerBI
if (DataSetCheck)
{
    Write-Host "`nIntended Workspace found. Retrieving`n"
    $wsdataset = Get-PowerBIDataset -Name $DSName -WorkspaceId $workspace.Id
}
else 
{
    Write-Host "`nIntended Workspace not found. Creating new dataset`n"
    
    #Creating PowerBI Table 
    $col1 = New-PowerBIColumn -Name "datetime_in_utc" -DataType DateTime
    $col2 = New-PowerBIColumn -Name "subscription_name" -DataType String
    $col3 = New-PowerBIColumn -Name "resource_name" -DataType String
    $col4 = New-PowerBIColumn -Name "location" -DataType String
    $col5 = New-PowerBIColumn -Name "current_value" -DataType Int64
    $col6 = New-PowerBIColumn -Name "limit" -DataType Int64
    $col7 = New-PowerBIColumn -Name "limit" -DataType Int64
    $table = New-PowerBITable -Name $tblName -Columns $col1, $col2, $col3, $col4, $col5, $col6, $col7

    # Create Dataset (Subscription_Data)
    $dataset = New-PowerBIDataset -Name $DSName -Tables $table

    # Adding dataset to workspace
    $wsdataset = Add-PowerBIDataset -Dataset $dataset -WorkspaceId $workspace.Id

    Write-Host "`nCreated Workspace Dataset`n"
    $wsdataset
}

# Iterate each CSV file and send to PowerBI
Get-ChildItem $dataPath -Filter "*.csv" |ForEach-Object { 

    $file=$_              
    
    #Import csv and add column with filename
    #$data = Import-Csv $file.FullName | Select-Object @{Label="File";Expression={$file.Name}}, *

    # Send data to PowerBI
    Add-PowerBIRow -DatasetId $wsdataset.Id -TableName $tblName -Rows (Import-Csv $file.FullName)
}