
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
# ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
# CUSTOMER SUCCESS UNIT, MICROSOFT CORP. APAC.

##########################################################################################
# a quick and dirty way to check and setup running environment.
##########################################################################################

function IsPowerShell7() 
{
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\PowerShellCore') 
    { 
        return $true
    } 
    else
    { 
        Write-Host '[ NO ] No PowerShell 7+ is found on your system.' -ForegroundColor Red
        return $false 
    }
}

function IsWindows() 
{
    if (([System.Environment]::OSVersion.Platform) -match 'Win32NT') 
    { 
        return $true 
    } 
    else 
    { 
        return $false 
    }
}

function IsAzModulesFound() 
{
    If (-not ($null) -eq (Get-InstalledModule -Name Az -ErrorAction SilentlyContinue))
    { 
        return $true 
    } 
    else 
    { 
        return $false 
    }
}

function IsAzureRmModulesFound() 
{
    if ($null -ne (Get-InstalledModule -Name AzureRm -ErrorAction SilentlyContinue)) 
    { 
        return $true 
    } 
    else
    {
        return $false 
    }
}

function Install-AzModules()
{
    Write-Host '[INFO] Installing Az Modules on your OS now. It may take a while...' -ForegroundColor Blue
    if (IsWindows)
    {
        if (IsPowerShell7) 
        {
            Start-Process pwsh.exe '-c', { 
                If ($null -eq (Get-InstalledModule -Name Az -ErrorAction SilentlyContinue))
                {
                    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -AllowClobber -Force -SkipPublisherCheck -PassThru 
                }
            } -Wait            
        }
    }
    else
    {
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -AllowClobber -Force -SkipPublisherCheck -PassThru
    }
}

function Install-PowerShell7()
{
    Write-Host '[INFO] Installing the latest PowerShell on your system now...' -ForegroundColor Blue
    try 
    {
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
        {
            Invoke-Expression  "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet -AddExplorerContextMenu  -EnablePSRemoting"
        }
        else
        {
            Invoke-Expression  "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -AddExplorerContextMenu  -EnablePSRemoting"
        }
    } 
    catch
    {
        Write-Host '[ NO ] An error occurred during pulling the data from the remote server.  Please try again later...' -ForegroundColor Red
    }
}

function Uninstall-AzureRmModules() 
{
    Write-Host "[INFO] Uninstalling AzureRm Modules now... This will take a while..." -ForegroundColor Blue
    if (IsWindows)
    {
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
        {
            Uninstall-AzureRm -PassThru; Write-Host '[INFO] The legacy AzureRm Modules are removed from your system.' -ForegroundColor Blue
        }
        else
        {
            Invoke-Command -ScriptBlock { Start-Process pwsh.exe '-c', { Uninstall-AzureRm -PassThru; Write-Host '[INFO] The legacy AzureRM Modules are removed from your system.' -ForegroundColor Blue } -Verb RunAs -Wait }
        }
    }
    else
    {
        Uninstall-AzureRm -PassThru; Write-Host '[INFO] The legacy AzureRM Modules are removed from your system.' -ForegroundColor Blue
    }
}

function Set-PSEnvironment()
{
    if (IsWindows) 
    {
        Clear-Host
        if (-not (IsPowerShell7))    { Install-PowerShell7      } 
        if (-not (IsAzModulesFound)) { Install-AzModules        }
        if (IsAzureRmModulesFound)   { Uninstall-AzureRmModules }
    } 
    else 
    {
        if (-not (IsAzModulesFound)) { Install-AzModules        }
        if (IsAzureRmModulesFound)   { Uninstall-AzureRmModules }
    }
}

Set-PSEnvironment

function Get-PSEnvironment()
{
    $flag = $false;
    if (IsWindows) 
    {

        if ((IsPowerShell7))                { Write-Host '[ OK ] PowerShell 7+ is found on your system.' -ForegroundColor Green            ; $flag = $true } 
        if ((IsAzModulesFound))             { Write-Host '[ OK ] Az Modules are found on your system.' -ForegroundColor Green              ; $flag = $true }
        if (-not (IsAzureRmModulesFound))   { Write-Host '[ OK ] No conflict with AzureRm is found on your system.' -ForegroundColor Green ; $flag = $true }
    } 
    else 
    {
        if ((IsAzModulesFound))             { Write-Host '[ OK ] Az Modules are found on your system.' -ForegroundColor Green                ; $flag = $true }
        if (-not (IsAzureRmModulesFound))   { Write-Host '[ OK ] No conflict with AzureRm is found on your system.' -ForegroundColor Green   ; $flag = $true }
    }

    return $flag
}

if (Get-PSEnvironment) 
{
    Write-Host ''
    Write-Host '[INFO] Your setting meets the Prerequisites.  Please proceed with running the Get-AzQuotaUtil.ps1 script as described in Usage section in README.' -ForegroundColor Blue 
}
else
{
    Write-Host '[INFO] Your settings do not seem to meet the Rerequisites.  Please make sure that you go through Pre-Requisite Second of the REAMDE !!' -ForegroundColor Red 
}
