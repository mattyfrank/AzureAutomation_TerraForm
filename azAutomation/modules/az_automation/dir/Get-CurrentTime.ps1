Write-Output "HostName: $([Net.Dns]::GetHostName())"
try {
	[system.threading.thread]::currentThread.currentCulture = [system.globalization.cultureInfo]"en-US"
	$CurrentTime = $((Get-Date).ToShortTimeString())
	Write-Output "$CurrentTime"
} catch {Write-Error $_}