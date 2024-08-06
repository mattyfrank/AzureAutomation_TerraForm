<#
.Synopsis
    Shutdown VMs that are in the Deleting State. 

.Description
    This script will power off VMs that are in the Deleting state.

.Notes
    Requires the following PowerShell Modules
        VMware.Vim
        VMware.VimAutomation.Cis.Core
        VMware.VimAutomation.Common
        VMware.VimAutomation.Core
        VMware.VimAutomation.Sdk
        VMware.VimAutomation.HorizonView
        VMware.Hv.Helper
#>

#requires -version 3
#requires -Module VMware.VimAutomation.Core, Vmware.Hv.Helper

#Region Variables
$VerbosePreference      =  "SilentlyContinue"
$ErrorActionPreference  = "stop"
$hvServers              = @("HorizonServer1.Domain.net","HorizonServer1.Domain.net")
$Credential_Name        = "Horizon Admin Service Account"

#EndRegion Variables

#Region Functions 

function Connect-Admin {
    <#
    .Synopsis 
        Import Creds and By Default Connect to Horizon Server, and optionally connect to vCenter...
    #>
    param($Credentials,$hvServer,$vCenter)
    Try{
        $AdminSession = Connect-HVServer $hvServer -Credential $Credentials
    }Catch{Write-Error "Could not connect to $($hvServer)"}

    if(@($vCenter)){
        #ignore security certificates are invalid
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
        Try{
            Connect-VIServer $vCenter -Credential $Credentials | Out-Null
        }Catch{Write-Error "Could not connect $($vCenter)"} 
    }
    return $AdminSession
}

function Clear-DeletingVMs {
    <#
    .Synopsis 
        Gracefully ShutDown horizon VMs stuck in the Deleting state
    
    .parameter failedSessions
        array of Horizon VMs in Deleting state
    #>     
    param($DeletingVMs)
    foreach ($x in $DeletingVMs){
        $VMName = $($x.Base.Name)
        $VM     = (Get-HVMachine -MachineName $VMName)
        if (($VM.Base.BasicState) -eq "DELETING"){
            try {
                Write-Output "Gracefully ShutDown: $($VMName)"
                Get-VM $VMName | Shutdown-VMGuest -Confirm:$false | Out-Null
            }catch {Write-Output "ShutDown Failed."}
        }
    }
}

#EndRegion Functions

Write-Output "Hybrid Worker: $([Net.Dns]::GetHostName())"

#Azure Automation Creds
Try{
    Write-Verbose "Retrieve Azure Automation Creds: $($Credential_Name)"
    $Credentials    = Get-AutomationPSCredential -Name "$Credential_Name" 
    If(!($Credentials)){Write-Error "Creds are missing"}
}Catch {Write-Error "Failed to retrieve creds"}

#Set PowerCLI Configuration
Set-PowerCLIConfiguration -Scope Session -ParticipateInCEIP $false -Confirm:$false | Out-Null

foreach ($hvServer in $hvServers){
    if ($hvServer -eq "HorizonServer1.Domain.net"){$Vcenter= "vCenter1.Domain.net"}
    if ($hvServer -eq "HorizonServer2.Domain.net"){$Vcenter= "vCenter2.Domain.net"}
    
    Write-Output "Connect to '$($hvServer)' & '$($vCenter)'"
    $AdminSession   = Connect-Admin -Credentials $Credentials -HVServer $hvServer -vCenter $vCenter
    
    Write-Output "Get VMs in Deleting State..."
    $DeletingVMs = (Get-HVMachine -State DELETING)

    if (($DeletingVMs.count) -gt 0){
        Write-Output "Gracefully Shutdown VMs in Deleting State..."
        Clear-DeletingVMs -DeletingVMs $DeletingVMs
    }else{Write-Output "No VMs in Deleting State."}

    Write-Output "Disconnect $($hvServer) & $($vCenter)`n"
    Disconnect-HVServer $hvServer -Confirm:$false -Force
    Disconnect-VIServer $vCenter -Confirm:$false

}