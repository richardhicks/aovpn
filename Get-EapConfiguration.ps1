[CmdletBinding()]

Param(

    [string]$ConnectionName

    )

$UserName = Get-Content env:username
$Connection = $ConnectionName
$XMLpath = "C:\Users\" + $UserName + "\desktop\eapconfig.xml"

# delete EAP configuration XML file if it already exists...
If (Test-Path $XMLpath) {Remove-Item $XMLpath}

# extract EAP configuration from VPN connection...
$Vpn = Get-VpnConnection -Name $Connection
$Xml = $Vpn.EapConfigXmlStream.InnerXml | Out-File $XMLPath -Encoding ASCII
