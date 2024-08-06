<#
.Synopsis
    Shutdown Horizon VMs that are in Error States. 

.Description
    This script will power off VMs that are in basic error states.

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

function Get-ErrorVMs {
    <#
    .Synopsis 
        Get Horizon VMs that report any of the Basic Error States
    .parameter floatingPools
        Array or Horizon Floating Pools to Search for Error VMs
    #> 
    param($floatingPools)
    $basicStates = @(
        'PROVISIONING_ERROR',
        'ERROR',
        'AGENT_UNREACHABLE',
        'AGENT_ERR_STARTUP_IN_PROGRESS',
        'AGENT_ERR_DISABLED',
        'AGENT_ERR_INVALID_IP',
        'AGENT_ERR_NEED_REBOOT',
        'AGENT_ERR_PROTOCOL_FAILURE',
        'AGENT_ERR_DOMAIN_FAILURE',
        'AGENT_CONFIG_ERROR',
        'ALREADY_USED',
        'UNKNOWN'
    )
    $ErrorVMs=@()
    foreach ($state in $basicStates) {
        Write-Verbose -Verbose `n"Search for VMs in '$($state)' State"
        $ProblemVMs = Get-HVMachineSummary -State $state -SuppressInfo:$true
        if(($ProblemVMs.Count) -gt 0){
            #for each vm in $problemVMs, add the name to the $ErrorVM list
            $ProblemVMs | ForEach-Object {
                if(($_.Base.DesktopName) -in $FloatingPools){
                    Write-Verbose -Verbose "'$($_.Base.Name)' in pool '$($_.Base.DesktopName)'"
                    $ErrorVMs += "$($_.Base.Name)"
                }
            }
        }
    }
    return $ErrorVMs
}
 
function Clear-ErrorVMs {
    <#
    .Synopsis 
        Shutdown Horizon VMs in Error States
    .parameter floatingPools
        Array or Horizon Floating Pools to Search for Error VMs
    #> 
    param($ErrorVMs)
    foreach ($VM in $ErrorVMs) {
        Write-Output "Remove VM '$($VM)'"
        Remove-HVMachine -MachineNames $($VM) -DeleteFromDisk:$true -Confirm:$false | Out-Null
        #Get-VM $VM | Restart-VMGuest -Confirm:$false 
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

    Write-Output "Get List of Floating Pools..."
    $floatingPools = (Get-HVPool -UserAssignment FLOATING -Verbose).base.name

    Write-Output "Get Error VMs in Floating Pools..."
    $ErrorVMs = Get-ErrorVMs -floatingPools $floatingPools

    if($ErrorVMs.Count -gt 0){
        Write-Output "Clear Error VMs..."
        Clear-ErrorVMs -ErrorVMs $ErrorVMs
    }else{Write-Output "No VMs in Error State."}

    Write-Output "Disconnect $($hvServer) & $($vCenter)`n"
    Disconnect-HVServer $hvServer -Confirm:$false -Force
    Disconnect-VIServer $vCenter -Confirm:$false

}