Write-Output "HostName: $([Net.Dns]::GetHostName())"
try {
	Get-Process | Format-Table -View priority
}catch {Write-Error $_}