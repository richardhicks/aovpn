<#

.SYNOPSIS
    PowerShell script to exctact ProfileXML from an existing VPN connection.

.PARAMETER ConnectionName
    The VPN connection name to extract ProfileXML from.

.PARAMETER FileName
    The name of the file to save the extracted ProfileXML.

.EXAMPLE
    .\Get-VPNClientProfileXML.ps1 -ConnectionName 'Always On VPN' -xmlFilePath .\Profile.XML

.DESCRIPTION
    Configuration settings for an Always On VPN connection are stored in ProfileXML. This PowerShell script can be used to view the existing ProfileXML for a given VPN connection in Windows 10.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.0
    Creation Date:  December 21, 2019
    Last Updated:   December 21, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param(

    [Parameter(Mandatory = $True, HelpMessage = "Enter the name of the VPN connection.")]
    [string]$ConnectionName,
    [string]$xmlFilePath = ".\ProfileXML.xml",
    [switch]$DeviceTunnel

)

If ($DeviceTunnel) {

    # validate VPN connection
    $VPN = Get-VpnConnection -AllUserConnection -Name $ConnectionName -ErrorAction SilentlyContinue

}

Else {

    # validate VPN connection
    $Vpn = Get-VpnConnection -Name $ConnectionName -ErrorAction SilentlyContinue
}

If ($Vpn -eq $null) {

    Write-Warning "The VPN connection $ConnectionName does not exist. Exiting script."
    Exit

}

# If file already exists, exit script
If (Test-Path $xmlFilePath) {

    Write-Warning "$xmlFilePath already exists. Exiting script."
    Exit
    
}
function Format-XML ([xml]$Xml, $Indent = 3) { 
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $XmlWriter.Formatting = "Indented"
    $XmlWriter.Indentation = $Indent 
    $Xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 
}

# Remove spaces from VPN connection name
$ConnectionNameEscaped = $ConnectionName -replace ' ', '%20'

# Extract ProfileXML
Write-Verbose 'Extracting ProfileXML from $ConnectionName...'

$NameSpace = 'root\cimv2\mdm\dmmap'
$Class = 'MDM_VPNv2_01'

$Xml = Get-CimInstance -Namespace $NameSpace -ClassName $Class -Filter "ParentID='./Vendor/MSFT/VPNv2' and InstanceID='$ConnectionNameEscaped'" | Select-Object -ExpandProperty ProfileXML

# Output ProfileXML to file
Write-Verbose "Writing ProfileXML to $xmlFilePath..."
Format-XML $xml | Out-File $xmlFilePath
