<#
.Synopsis
    Log off and delete old Horizon sessions and VMs.

.Description
    This script will recycle floating VMs that were created greater than a period of time. If the VM is older than 24 hours, the VM will be powered off, and deleted from the Horizon View environment.

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
$time                   = $((Get-Date).AddDays(-1))
# $time                   = $((Get-Date).AddHours(-21))
# $time                   = $((Get-Date).AddMinutes(-30))

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

function Reset-OldVMs {
    <#
    .Synopsis 
        Reset Available VMS that are members of FLOATING Pools that were created before a period of time. 
    
    .Parameter oldVMs
        Array of Horizon VMs that were created before a period of time.
    .Parameter floatingPools
        Array of Horizon Desktop Pools with Floating Assignments
    #> 
    param($oldVMs, $floatingpools)
    foreach ($vm in $oldVMs){
        if($vm.Base.DesktopName -in $floatingpools){
            Write-Output "Remove HV Machine '$($vm.base.name)' from '$($vm.Base.DesktopName)'"
            try{
                Remove-HVMachine $vm.base.name -DeleteFromDisk -Confirm:$false | Out-Null
            }catch{Write-Warning "$($vm.base.name) Failed to Delete"}
        }else{<#VM is Not Member of Floating Pool#>}
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
    
    Write-Verbose "Get Desktop Pools with Floating Assignmnents."
    $pools   = (Get-HVPool -UserAssignment FLOATING -Verbose)
    $poolNames = $pools.base.Name
    
    <#
        $time = $((Get-Date).AddDays(-1))
        $time = $((Get-Date).AddHours(-21))
        $time = $((Get-Date).AddMinutes(-45))
    #>
    Write-Output "Get Available VMs that were created before '$($time)'..."
    $oldVMs  =  Get-HVMachine -State Available | Where-Object {$_.ManagedMachineData.CreateTime -lt $time}
    Write-Verbose "Reset $($oldVMs.Count) Old VMs..."
    
    if($($OldVMs.Count) -gt '0'){
        Write-Output "Remove the VMs..."
        Reset-OldVMs -oldVMs $oldVMs -floatingpools $poolNames
    }else{Write-Output "No Old VMs."}

    #Disconnect from Horizon and vCenter
    Write-Output "Disconnect $($hvServer) & $($vCenter)`n"
    Disconnect-HVServer $hvServer -Confirm:$false -Force
    Disconnect-VIServer $vCenter -Confirm:$false

}