#requires -version 3
#requires -Module VMware.VimAutomation.Core, VMware.VimAutomation.HorizonView, Vmware.Hv.Helper
#VMware.PowerCLI

#Region Variables
$hvServers = @("HorizonServer1.domain.net","HorizonServer2.domain.net")


#EndRegion Variables

#Region Functions 

#Import Creds and Connect to Horizon Server. Also connects to vCenter if called...
function Connect-Admin {
    param($Credentials,$hvServer,$vCenter)
    Write-Host "Connect to '$($hvServer)'"
    Try{$AdminSession = Connect-HVServer $hvServer -Credential $Credentials}
    Catch{Write-Host "Could not connect To Horizon Server: $hvServer, Exiting"; exit}

    if(@($vCenter)){
        #ignore security certificates are invalid
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
        Write-Host "Connect to '$($vCenter)'"
        Try{Connect-VIServer $vCenter -Credential $Credentials | Out-Null}
        Catch{Write-Host "Could not connect To vCenter: $($vCenter), Exiting"; exit} 
    }
    return $AdminSession
}

function Get-OldSesions{
    param($sessions,$pools,[int]$maxSessionAge)
    $oldSessions=@()
    Write-Host "Get Sessions initiated over '$($maxSessionAge)' hours ago."
    foreach ($session in $sessions) {
        if ($session.NamesData.DesktopName -in $pools.base.Name){
            #Caculate session age
            [int]$sessionAge = (New-TimeSpan -Start $session.SessionData.StartTime).TotalHours
            if ($sessionAge -gt $maxSessionAge){
                $oldSessions += $session
            }
        }
    }
    Write-Host "$($oldSessions.count) sessions older than '$($maxSessionAge)' hours ago."
    return $oldSessions
}

function LogOff-OldSessions{
    param($oldSessions,$AdminSession)

    #PS Object to Force Log Off and Delete VM
    $deletespec     = (New-Object VMware.Hv.machineDeleteSpec)
    $deletespec.DeleteFromDisk=$true
    $deletespec.ForceLogoffSession=$true
    
    Write-Host "LogOff Old Sessions..."
    foreach ($session in $oldSessions) {
        #create vars for the session data
        $sessionId  = $session.Id
        $userName   = $session.NamesData.UserName
        $machineName= $session.NamesData.MachineOrRDSServerName
        $sessionAge = (New-TimeSpan -Start $session.SessionData.StartTime).TotalHours
        $machineId  = $((Get-HVMachine -MachineName $machineName).Id)
        Write-Host `n"'$($userName)' has been connected to '$($machineName)' for '$($sessionAge.ToString("#,#"))' hours."
        #Write-Host "Session Start Time: $($session.SessionData.StartTime)"
        try{
            Write-Host "Try to log off session." #Current Time: $(get-date -Format MM/dd/yy_HH:mm:ss)"
            $AdminSession.ExtensionData.Session.Session_Logoff($sessionId)
            #LogOff         $AdminSession.ExtensionData.Session.Session_Logoff($sessionId)
            #ForcedLogOff   $AdminSession.ExtensionData.Session.Session_LogoffForced($sessionId)
            #RecoverVM      $AdminSession.ExtensionData.Machine.Machine_Recover($machineId)
        }catch{
            Write-Host "Failed to logoff. Force logoff and Delete VM."
            $AdminSession.ExtensionData.Machine.Machine_Delete($machineId,$deletespec)
        }
    
        #create list of VMs with sessions over 24 hours
        if ($sessionAge -ge 24){$failedSessions += $machineName}
    }
    return $failedSessions
}

function Stop-OldVMs{
    param($failedSessions)
    if ($failedSessions -gt 0) {
        Write-Host `n "Power Off VMs with Sessions older than 24 hours..."
        foreach ($horizonVM in $failedSessions) {
            #Write-Host `n "Get VM named '$($horizonVM)'"
            $VM = (Get-VM -Name $horizonVM)
            if(!($VM)){Write-Host "VM '$($horizonVM)' not found!"}
            else{
                try{
                    #Write-Host "PowerOff $($VM.Name). CurrentTime:$(get-date -Format dd-MM-yy.hh:mm:ss)"`n
                    Stop-VM -VM $VM -Confirm:$false | Out-Null
                }catch{Write-Host"$($VM) failed to power off!"}
            }
        }
    }
}

#EndRegion Functions

#Import Creds
$CredPath = ".\creds.xml"
$Credentials = Import-Clixml -Path $CredPath

#Set PowerCLI Configuration
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false | Out-Null

foreach ($hvServer in $hvServers){
    if ($hvServer -eq "HorizonServer1.domain.net"){$Vcenter= "vCenter1.domain.net"}
    if ($hvServer -eq "HorizonServer2.domain.net"){$Vcenter= "vCenter2.domain.net"}
    
    #init list of sessions older than 24 hours
    $failedSessions = @()
    
    #Connect to Horizon and vCenter
    $AdminSession   = Connect-Admin -Credentials $Credentials -HVServer $hvServer -vCenter $vCenter
    
    Write-Host "Get all sessions..."
    $sessions       = (Get-HVLocalSession)
    if ($sessions -eq 0){Write-Error "No Sessions Found";break}
    
    Write-Host "Get all pools with FLOATING assignments..."
    $floatingPools  = (Get-HVPool -UserAssignment FLOATING -Verbose)
    #$poolNames      =  $floatingPools.base.displayname
    
    #Get Old Sessions
    [int]$maxSessionAge=8 #hours
    $oldSessions    = Get-OldSesions -sessions $sessions -pools $floatingPools -maxSessionAge $maxSessionAge

    #Log Off Old Sessions
    $failedSessions = LogOff-OldSessions -oldSessions $oldSessions -AdminSession $AdminSession

    #Stop VMs with over 24 hour sessions
    Stop-OldVMs -failedSessions $failedSessions

    Write-Host "Disconnect $($hvServer) & $($vCenter)"
    Disconnect-HVServer $hvServer -Confirm:$false -Force
    Disconnect-VIServer $vCenter -Confirm:$false

}