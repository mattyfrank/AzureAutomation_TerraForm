<#
.Synopsis
    Get dedicated VMs whose assigned userName is Missing or Disabled in the Domain.
    Mark the VMs as Maintenance Mode and Power Off the VMs, if they are not already in that state.
    If the VM is already in Maintenance Mode and Powered Off, delete the VM and remove the AD Object.

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
#requires -Module VMware.VimAutomation.Core, Vmware.Hv.Helper, ActiveDirectory

#Region Variables
$VerbosePreference      =  "SilentlyContinue"
$ErrorActionPreference  = "stop"
$hvServers              = @("HorizonServer1.Domain.net")
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

function Get-MachinesToRemove {
    <#
    .Synopsis 
        Get VMs whose assigned userName is Missing or Disabled in the Domain
    .parameter dedicatedPools
        Array or Horizon Dedicated Pools to Search
    .Notes
        Requires PowerShell Module ActiveDirectory 
    #>    
    param($DedicatedPools)
    [System.Collections.ArrayList]$results = @()
    
    Foreach ($Pool in $DedicatedPools){
        Write-Verbose "$($Pool.base.DisplayName)"
        $MachineData = Get-HVMachineSummary -poolname $($Pool.base.Name) | Select-Object -Property `
                                        @{Name = 'MachineName'; Expression = {$_.base.name}},
                                        @{Name = 'User'; Expression = {$_.namesdata.username}},
                                        @{Name = 'Pool'; Expression = {$_.namesdata.desktopname}}

        Write-Verbose "$($Pool.base.Name) has $($MachineData.count) VMs."
        Write-Verbose  "Remove Null Values (Machines without Users Assigned)"
        $MachineData = $MachineData | Where-Object user -ne $null
        Write-Verbose  "$($Pool.base.Name) has $($MachineData.count) VMs already assigned to users."

        foreach ($machine in $MachineData){
            #format the names
            [string]$userName       = $($machine.user).split("\")[1]
            [string]$machineName    = $machine.MachineName
            try {
                #Search AD for UserName
                $obj = (Get-ADUser $userName -Properties Enabled)
            }catch {
                Write-Verbose "$($userName) not found in domain"
                $value=[pscustomobject]@{'userName'= $userName;'machineName'= $machineName; 'state'="missing"}
                $results.Add($value) | Out-Null
                $value=$null
            }
            if ($obj.Enabled -eq $false){
                Write-Verbose  "$($userName) is disabled"
                $value=[pscustomobject]@{'userName'= $userName;'machineName'= $machineName; 'state'="disabled"}
                $results.Add($value) | Out-Null
                $value=$null
            }
        }
    }  
    return $results
}

function Remove-Machines {
    <#
    .Synopsis
        Remove Horizon VMs and AD Computer Objects
    .parameter RemoveVMs
        Custom Array generated from Get-MachinesToRemove
    .Notes
        Requires the ActiveDirectory PowerShell Module
    #>    
    param($RemoveVMs)
    foreach ($x in $RemoveVMs){
        Write-Output `n"The user account '$($x.UserName)' that is assigned to VM '$($x.machineName)' is $($x.state) in the domain."
        $vm = (Get-HVMachine -MachineName $x.MachineName)
        if(!($vm)){
            Write-Warning "$($x.MachineName) Not Found in Horizon..."
        }else{
           #Delete any VMs that are already Powered_Off and in MaintMode
            if (($VM.ManagedMachineData.VirtualCenterData.VirtualMachinePowerState -eq "POWERED_OFF") -and ($VM.ManagedMachineData.InMaintenanceMode -eq $true)){
                Write-Output "$($vm.base.Name) is Powered Off and Maintenance Mode is Enabled"
                try{
                    Write-Output "Remove Horizon VM: $($vm.base.Name)"
                    Remove-HVMachine -MachineNames $($vm.base.Name) -DeleteFromDisk:$true -Confirm:$false
                }catch{Write-Warning "$($vm.base.Name) Failed to Delete!"}
                try{
                    Write-Output "Remove AD Object: $($vm.base.Name)"
                    $ADcom = Get-ADComputer $($vm.base.Name)
                    $ADobj = Get-ADObject -Identity $($adcom.DistinguishedName)
                    Remove-ADObject $ADobj -Recursive -Confirm:$false -Credential $Credentials
                }catch{Write-Warning "$($vm.base.Name) Failed to Remove AD Computer Object!"}
            }else{
                if($($VM.ManagedMachineData.InMaintenanceMode) -eq $false){
                    try{
                        Write-Output "Enable Maintenance Mode: $($vm.base.Name)."
                        Set-HVMachine -MachineName $($vm.base.Name) -Maintenance ENTER_MAINTENANCE_MODE
                    }catch{Write-Warning "$($vm.base.Name) Failed to Enter MaintMode!"}
                }
                if ($($VM.ManagedMachineData.VirtualCenterData.VirtualMachinePowerState) -eq "POWERED_ON"){
                    Write-Verbose "$($vm.base.Name) is $($VM.ManagedMachineData.VirtualCenterData.VirtualMachinePowerState)"
                    try {
                        Write-Output "Shut Down: '$($vm.base.Name)'."
                        Shutdown-VMGuest -VM $($vm.base.Name) -Confirm:$false | Out-Null
                    }catch{
                        Write-Output "Failed to Shutdown Gracefully, Hard Power Off..."
                        Stop-VM -VM $($vm.base.Name) -Confirm:$false | Out-Null
                    }
                }
            } 
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

    Write-Output "Connect to '$($hvServer)' & '$($vCenter)'"
    $AdminSession   = Connect-Admin -Credentials $Credentials -HVServer $hvServer -vCenter $vCenter

    Write-Verbose "Get Pools with Dedicated User Assignments..."
    $DedicatedPools = (Get-HVPool -UserAssignment DEDICATED -Verbose)
    #select Unique IDs
    $DedicatedPools = $DedicatedPools | Sort-Object {$($_.Id).Id} -Unique
    
    Write-Output "Get list of Dedicated VMs where the user account is disabled or missing from the domain..."
    $RemoveVMs      = Get-MachinesToRemove -DedicatedPools $DedicatedPools
    #$RemoveVMs | Export-Csv -Path ".\Reports\$(Get-Date -f yyyy.MM.dd)_MachinesToDelete.csv"
    
    if(($RemoveVMs.count) -gt 0){
        Write-Output "Enter Maintenance Mode, ShutDown, and Delete Machines..."
        Remove-Machines -RemoveVMs $RemoveVMs
    }else{Write-Output "No VMs to Remove."}

    Write-Output "Disconnect $($hvServer) & $($vCenter)`n"
    Disconnect-HVServer $hvServer -Confirm:$false -Force
    Disconnect-VIServer $vCenter -Confirm:$false
}