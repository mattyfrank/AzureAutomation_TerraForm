<#
Reset Azure Automation Account to a clean state
 & ".\ReSet-AZ_Automation.ps1"
#>

param(
    [string]$AutomationAccountName, 
    [string]$ResourceGroupName,
    [string]$SubscriptionId,
    [string]$VMSS_Name,
    [string]$AccountId
)

Write-Output "Connect to Azure and Select Subscription"
Connect-AzAccount -AccountId $AccountId | Out-Null
Set-AzContext  $SubscriptionId |Out-Null

$AA = Get-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName

Write-Output "Remove All Runbooks"
Get-AzAutomationRunbook -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName | Remove-AzAutomationRunbook -Force

Write-Output "Remove All Credentials"
Get-AzAutomationCredential -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName | Remove-AzAutomationCredential
Write-Output "Remove All Variables"
Get-AzAutomationVariable -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName | Remove-AzAutomationVariable

Write-Output "Remove All Schedules"
Get-AzAutomationSchedule -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName | Remove-AzAutomationSchedule -Force 

Write-Output "Remove All Scheduled Jobs"
Get-AzAutomationScheduledRunbook -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName | Unregister-AzAutomationScheduledRunbook -Force

Write-Output "Remove Hybrid Worker Group"
$HWG = Get-AzAutomationHybridWorkerGroup -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName
Remove-AzAutomationHybridWorkerGroup -ResourceGroupName $AA.ResourceGroupName -AutomationAccountName $AA.AutomationAccountName -Name $HWG.Name

Write-Output "Remove VMSS"
Get-AzVmss -ResourceGroupName $AA.ResourceGroupName -VMScaleSetName $VMSS_Name | Remove-AzVmss -Force

Write-Output "AZ Automation Reset to Clean State"