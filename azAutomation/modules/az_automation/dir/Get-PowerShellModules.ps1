Write-Output "HostName: $([Net.Dns]::GetHostName())"
try {
	Get-Module | Format-Table -property Name,Version,ModuleType,ExportedCommands
} catch {Write-Error $_}