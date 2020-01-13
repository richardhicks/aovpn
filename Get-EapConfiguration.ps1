<#
.SYNOPSIS
    Extract EAP configuration from existing Windows 10 VPN connection.

.PARAMETER ConnectionName
    The name of the VPN connection to extract the EAP configuration from.

.PARAMETER xmlFilePath
    The full path and name of the file to export EAP configuration to.
    
.EXAMPLE
    .\Get-EapConfiguration.ps1 -Connection 'Test VPN Connection' 

    Extracts the EAP configuration from a VPN connection named "Test VPN Connection". The file will be automatically saved to the user's desktop as eapconfig.xml.

.EXAMPLE
    .\Get-EapConfiguration.ps1 -Connection 'Test VPN Connection' -xmlFilePath 'C:\temp\eapconfig.xml'

    Extracts the EAP configuration from a VPN connection named "Test VPN Connection and the file is saved to a custom location."

.DESCRIPTION
    Use this script to extract the EAP configuration from an existing VPN connection. The output XML can be copied and pasted in to ProfileXML for configuring Windows 10 Always On VPN connections.

.LINK
    https://directaccess.richardhicks.com/always-on-vpn/

.NOTES
    Version:        1.22
    Creation Date:  May 27, 2019
    Last Updated:   Jauary 13, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://www.richardhicks.com/

#>

[CmdletBinding()]

Param (

    [Parameter(Mandatory = $True, HelpMessage = "Enter the name of the VPN template connection.")]
    [string]$ConnectionName,
    [string]$xmlFilePath = '.\eapconfig.xml'

)

# Format XML
function Format-XML ([xml]$Xml, $indent = 3) { 

    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $XmlWriter.Formatting = "Indented"
    $XmlWriter.Indentation = $Indent 
    $Xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 

} # function Format-XML

# validate VPN connection
$Vpn = Get-VpnConnection -Name $ConnectionName -ErrorAction SilentlyContinue

If ($Vpn -eq $null) {

    Write-Warning "The VPN connection $ConnectionName does not exist. Exiting script."
    Exit

}

# Remove existing EAP configuration file if it exists
If (Test-Path $xmlFilePath) {

    Write-Verbose 'Old EAP configuration file found. Deleting...'
    Remove-Item $xmlFilePath

}

# Create EAP configuration object
Write-Verbose "Extracting EAP configuration from template connection $ConnectionName"
$EapConfig = $Vpn.EapConfigXmlStream.InnerXml

# Convert text stream to XML format
Write-Verbose 'Converting text stream to XML format...'
Format-XML $EapConfig | Out-File $xmlFilePath

# Save the file
Write-Verbose 'Saving EAP configuration to file...'
Write-Output "EAP configuration saved to $xmlFilePath."
