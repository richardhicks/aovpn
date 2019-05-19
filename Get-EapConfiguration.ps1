# // extract and scrub VPN connection EAP XML

[CmdletBinding()]

Param(

[string]$Connection,
[string]$xmlFilePath
)


If (Test-Path $xmlFilePath) {Remove-Item $xmlFilePath}

$VPN = Get-VpnConnection -Name $Connection
$xml = $VPN.EapConfigXmlStream.InnerXml
$xml -join "`r" | % { $_ -replace '>\s*<','><'} | Out-File $xmlFilePath -Encoding ASCII
