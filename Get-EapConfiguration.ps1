<#
.SYNOPSIS
    Extract EAP configuration from existing Windows 10 VPN connection.

.PARAMETER Connection
    The name of the VPN connection to extract the EAP configuration from.

.PARAMETER xmlFilePath
    The full path and name of the file to export EAP configuration to.
    
.EXAMPLE
    Get-EapConfiguration.ps1 -Connection "Test VPN Connection" -xmlFilePath "C:\Users\rdeckard\desktop\eapconfig.xml"

.DESCRIPTION
    Use this script to extract the EAP configuration from an existing VPN connection. The output XML can be copied and pasted in to ProfileXML for configuring Windows 10 Always On VPN connections.

.LINK
    https://directaccess.richardhicks.com/always-on-vpn/

.NOTES
    Version:        1.0
    Creation Date:  5/27/2019
    Last Updated:   5/27/2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://www.richardhicks.com/

#>

[CmdletBinding()]

Param (

[string]$Connection,
[string]$xmlFilePath

)

If (Test-Path $xmlFilePath) {Remove-Item $xmlFilePath}

$VPN = Get-VpnConnection -Name $Connection
$xml = $VPN.EapConfigXmlStream.InnerXml
$xml -join "`r" | % { $_ -replace '>\s*<','><'} | Out-File $xmlFilePath -Encoding ASCII
