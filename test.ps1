Clear-Host

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

 
#Create Archive Folder 
#new-item -Name "Archive" -Force -ItemType directory -Path "$currentPath\CSVData"  | Out-Null

# Import-Module "$currentPath\Modules\PowerBIPS" -Force 
Install-Module PowerBIPS
Import-Module -Name PowerBIPS

while($true)
{

    # Iterate each CSV file and send to PowerBI

    Get-ChildItem "$currentPath\CSVData" -Filter "*.csv" |ForEach-Object { 

        $file=$_               

        #Import csv and add column with filename

        $data = Import-Csv $file.FullName | Select-Object @{Label="File";Expression={$file.Name}}, *

        # Send data to PowerBI

        $data |  Out-PowerBI -dataSetName "CSVSales" -tableName "Sales" -types @{"Sales.OrderDate"="datetime"; "Sales.SalesAmount"="double"; "Sales.Freight"="double"} -batchSize 300 -verbose

        # Archive the file

        Move-Item $file.FullName "$currentPath\CSVData\Archive\" -Force

    }

    Write-Output "Sleeping…"

    Start-Sleep -Seconds 5

}

# =======================================================================================================
# Importing the CSV file to PowerBI
Write-Host "`n===== Importing CSV file to PowerBI =====`n" 

#Installing PowerBIPS module
Install-Module PowerBIPS
#Importing PowerBIPS module
Import-Module -Name PowerBIPS

Get-ChildItem -Path $datapath -Filter "*.csv" |ForEach-Object {
    $file=$_               

    #Import csv and add column with filename
    $data = Import-Csv $file.FullName | Select-Object @{Label="File";Expression={$file.Name}}, *

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

}