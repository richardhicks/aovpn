<#
.SYNOPSIS
    Creates an Always On VPN device tunnel connection.

.PARAMETER xmlFilePath
    Path to the ProfileXML configuration file.

.PARAMETER ProfileName
    Name of the VPN profile to be created.

.EXAMPLE
    .\New-AovpnDeviceConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML.xml' -ProfileName 'Always On VPN Device Tunnel'

.DESCRIPTION
    This script will create an Always On VPN user tunnel on supported Windows 10 devices. 

.LINK
    https://directaccess.richardhicks.com/2017/12/11/always-on-vpn-windows-10-device-tunnel-step-by-step-configuration-using-powershell/

.NOTES
    Version:            1.02
    Creation Date:      May 28, 2019
    Last Updated:       December 19, 2019
    Special Note:       This script adapted from published guidance provided by Microsoft.
    Original Author:    Microsoft Corporation
    Original Script:    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/vpn-device-tunnel-config#deployment-and-testing
    Author:             Richard Hicks
    Organization:       Richard M. Hicks Consulting, Inc.
    Contact:            rich@richardhicks.com
    Web Site:           www.richardhicks.com

#>

[CmdletBinding()]

Param(

    [Parameter(Mandatory = $True, HelpMessage = 'Enter the path to the ProfileXML file.')]    
    [string]$xmlFilePath,
    [Parameter(Mandatory = $True, HelpMessage = 'Enter a name for the VPN profile.')]        
    [string]$ProfileName

)

# Import ProfileXML
$ProfileXML = Get-Content $xmlFilePath

# Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

# OMA URI information
$NodeCSPURI = './Vendor/MSFT/VPNv2'
$NamespaceName = "root\cimv2\mdm\dmmap"
$ClassName = "MDM_VPNv2_01"

$Session = New-CimSession

try {

    $NewInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $ClassName, $NamespaceName
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ParentID', "$nodeCSPURI", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('InstanceID', "$ProfileNameEscaped", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ProfileXML', "$ProfileXML", 'String', 'Property')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Session.CreateInstance($NamespaceName, $NewInstance)
    Write-Output "Created $ProfileName profile."

}

catch [Exception] {

    Write-Output "Unable to create $ProfileName profile: $_"
    Exit
    
}

Write-Output 'Script complete.'
