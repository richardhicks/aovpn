<#

.SYNOPSIS
    Display custom IPsec policy configuration for VPN connections.

.PARAMETER Connection
    Name of the VPN connection to view custom IPsec policy.

.PARAMETER DeviceTunnel
    Specifieces the VPN connection is a device tunnel.

.EXAMPLE
    .\Show-VpnConnectionIpsecConfiguration.ps1 -Connection 'Always On VPN'

    Displays the custom IPsec policy for a user VPN connection, if configured.

.EXAMPLE
    .\Show-VpnConnectionIpsecConfiguration.ps1 -Connection 'Always On VPN Device Tunnel' -DeviceTunnel

    Displays the custome IPsec policy for a device tunnel VPN connection, if configured.

.DESCRIPTION
    Windows does not provide the ability to view custom IPsec policy configuration in the UI.
    In addition, Windows does not provide a native PowerShell command to view these settings.
    This script gives administrators the ability to easily view configured IPsec policy settings.

.LINK
    https://directaccess.richardhicks.com/2018/12/10/always-on-vpn-ikev2-security-configuration/

.NOTES
    Version:        1.1
    Creation Date:  August 20, 2019
    Last Updated:   December 18, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param (

    [Parameter(Mandatory = $True, HelpMessage = "Enter the name of the VPN connection.")]
    [string]$Connection,
    [switch]$DeviceTunnel
    
)

If ($DeviceTunnel) {

    $VPN = Get-VpnConnection -AllUserConnection -Name $Connection -ErrorAction SilentlyContinue
}

Else {
    
    $Vpn = Get-VpnConnection -Name $Connection -ErrorAction SilentlyContinue
}

If ($Vpn -eq $Null) {

    Write-Warning "The VPN connection $Connection does not exist. Exiting script."
    Exit

}

$Policy = ($Vpn | Select-Object -ExpandProperty IPsecCustomPolicy)

If ($Policy -eq $null) {

    Write-Warning 'Custom IPsec policy not configured.'
    Exit

}

Write-Output $Policy
