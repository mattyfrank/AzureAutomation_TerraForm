<#
.Synopsis
    Log off and delete old Horizon sessions and VMs.

.Description
    This script will log off and delete Horizon sessions older than a specified number of hours. If the session is older than 24 hours, the VM will be powered off.

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
[int]$maxSessionAge     = 12

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

function Get-OldSesions {
    <#
    .Synopsis 
        Floating sessions over an age will be forced to log off and delete the vm
    
    .parameter sessions
        array of Horizon Sessions
    .parameter pools
        array of Horizon pools, intended to be Floating assisgnments 
    .parameter maxSessionAge
        max number of hours
    #>    
    param($sessions,$pools,[int]$maxSessionAge)
    $oldSessions=@()
    foreach ($session in $sessions) {
        #Get Old Sessions that are in the floating pools
        if ($session.NamesData.DesktopName -in $pools.base.Name){
            #Caculate session age
            [int]$sessionAge = (New-TimeSpan -Start $session.SessionData.StartTime).TotalHours
            if ($sessionAge -gt $maxSessionAge){
                $oldSessions += $session
            }
        }
    }
    return $oldSessions
}

function Disconnect-OldSessions {
    <#
    .Synopsis 
        Disconnect Horizon Session
    
    .parameter oldSessions
        array of Horizon Sessions
    #>
    param($oldSessions,$AdminSession)

    #PS Object to Force Log Off and Delete VM
    $deletespec     = (New-Object VMware.Hv.machineDeleteSpec)
    $deletespec.DeleteFromDisk=$true
    $deletespec.ForceLogoffSession=$true
    
    foreach ($session in $oldSessions) {
        #create vars for the session data
        $sessionId  = $session.Id
        $userName   = $session.NamesData.UserName
        $machineName= $session.NamesData.MachineOrRDSServerName
        $sessionAge = (New-TimeSpan -Start $session.SessionData.StartTime).TotalHours
        $machineId  = $((Get-HVMachine -MachineName $machineName).Id)
        Write-Output "'$($userName)' connected to '$($machineName)' for '$($sessionAge.ToString("#,#"))' hours."
        Write-Verbose "Session Start Time: $($session.SessionData.StartTime)"
        try{
            Write-Output "Log Off Session." #Current Time: $(get-date -Format MM/dd/yy_HH:mm:ss)"
            $AdminSession.ExtensionData.Session.Session_Logoff($sessionId)
            #LogOff         $AdminSession.ExtensionData.Session.Session_Logoff($sessionId)
            #ForcedLogOff   $AdminSession.ExtensionData.Session.Session_LogoffForced($sessionId)
            #RecoverVM      $AdminSession.ExtensionData.Machine.Machine_Recover($machineId)
        }catch{
            Write-Output "Force logoff and Delete VM."
            $AdminSession.ExtensionData.Machine.Machine_Delete($machineId,$deletespec)
        }
    }
}

function Get-FailedSessions {
    <#
    .Synopsis 
        Create list of VMs with sessions over 24 hours
    
    .parameter oldSessions
        array of Horizon Sessions
    #>
    param($oldSessions)
    foreach ($session in $oldSessions) {
        $machineName = $session.NamesData.MachineOrRDSServerName   
        $sessionAge  = (New-TimeSpan -Start $session.SessionData.StartTime).TotalHours
        if ($sessionAge -ge 24){$failedSessions += $machineName}
    }
    return $failedSessions
}

function Stop-FailedSessions {
    <#
    .Synopsis 
        Hard Stop VMs
    
    .parameter failedSessions
        array of failed Horizon Sessions
    #>    
    param($failedSessions)
    foreach ($horizonVM in $failedSessions) {
        Write-Verbose `n"Get VM named '$($horizonVM)'"
        $VM = (Get-VM -Name $horizonVM)
        
        if(!($VM)){
            Write-Warning "VM '$($horizonVM)' Not Found!"
        }else{
            try{
                Write-Verbose "PowerOff $($VM.Name). CurrentTime:$(get-date -Format dd-MM-yy.hh:mm:ss)"`n
                Stop-VM -VM $VM -Confirm:$false | Out-Null
            }catch{Write-Warning "Failed to Power Off $($VM.Name)"}
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
    
    #init list of sessions older than 24 hours
    $failedSessions = @()
    
    Write-Output "Connect to '$($hvServer)' & '$($vCenter)'"
    $AdminSession   = Connect-Admin -Credentials $Credentials -HVServer $hvServer -vCenter $vCenter
    
    Write-Output "Get all sessions..."
    $sessions       = (Get-HVLocalSession)
    if (!($sessions) -or ($sessions.count) -eq 0){
        Write-Warning "No Sessions Found"
    }else{Write-Verbose "Number of all sessions: $($sessions.count)"}
    
    Write-Output "Get all pools with FLOATING assignments..."
    $floatingPools  = (Get-HVPool -UserAssignment FLOATING -Verbose)
    Write-Verbose "Floating Pools: $($floatingPools.base.displayname)"
    
    Write-Output "Get Sessions initiated over '$($maxSessionAge)' hours ago..."
    $oldSessions    = Get-OldSesions -sessions $sessions -pools $floatingPools -maxSessionAge $maxSessionAge
    Write-Output "$($oldSessions.count) sessions older than '$($maxSessionAge)' hours ago."

    if (($oldSessions.count) -gt 0){
        Write-Output "LogOff Old Sessions..."
        Disconnect-OldSessions -oldSessions $oldSessions -AdminSession $AdminSession
        
        Write-Output "Find sessions older than 24 hours..."
        $failedSessions = Get-FailedSessions -oldSessions $oldSessions

        if (($failedSessions.count) -gt 0){
            Write-Output "Stop VMs with sessions older than 24 hours..."
            Stop-FailedSessions -failedSessions $failedSessions
        }else{Write-Output "No sessions older than 24 hours."}
    }

    Write-Output "Disconnect $($hvServer) & $($vCenter)`n"
    Disconnect-HVServer $hvServer -Confirm:$false -Force
    Disconnect-VIServer $vCenter -Confirm:$false

}