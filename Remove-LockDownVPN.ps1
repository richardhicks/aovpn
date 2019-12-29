<#

.SYNOPSIS
    PowserShell script to remove a LockDown Always On VPN connection.

.PARAMETER ConnectionName
    The LockDown VPN connection name to be removed.

.EXAMPLE
    .\Remove-LockDownVPN.ps1 -ConnectionName 'Always On LockDown VPN'

.DESCRIPTION
    A LockDown Always On VPN connection cannot be removed using traditional methods such as Remove-VpnConnection. This script allows the administrator to successfully remove a previously configured LockDown VPN connection. 
    
    NOTE: This script must be run in the context of the local SYSTEM account. Use the Sysinternals tools Psexec.exe with the -i and -s parameters to launch PowerShell and run the script. Refer to the link below for more information.

.LINK
    https://directaccess.richardhicks.com/2019/04/08/always-on-vpn-lockdown-mode/

.NOTES
    Version:        1.0
    Creation Date:  December 29, 2019
    Last Updated:   December 29, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param(

    [string]$ConnectionName
    
)

# Script must be running in the context of the SYSTEM account. Validate user, exit if not running as SYSTEM
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$CurrentUserName = $CurrentPrincipal.Identities.Name

If ($CurrentUserName -ne 'NT AUTHORITY\SYSTEM') {

    Write-Warning 'This script is not running in the SYSTEM context, as required.'
    Write-Warning 'Use the Sysinternals tool Psexec.exe with the -i and -s parameters to run this script in the context of the local SYSTEM account.'
    Write-Warning 'Details here - https://rmhci.co/2IhuLOC.'
    Write-Warning 'Exiting script.'
    Exit

}

# Validate lockdown VPN connection
Write-Verbose "Validating VPN connection ""$ConnectionName""..."
$Vpn = Get-VpnConnection -AllUserConnection -Name $ConnectionName -ErrorAction SilentlyContinue

If ($Vpn -eq $Null) {

    Write-Warning "LockDown VPN connection ""$ConnectionName"" not found. Exiting script."
    Exit

}

# Remove spaces from connection name
$ConnectionNameEscaped = $ConnectionName -replace ' ', '%20'

# Get lockdown VPN connection
$CimInstance = Get-CimInstance -Namespace 'root\cimv2\mdm\dmmap' -ClassName 'MDM_VPNv2_01' -Filter "ParentID='./Vendor/MSFT/VPNv2' and InstanceID='$ConnectionNameEscaped'"

# Remove lockdown VPN connection
Write-Output "Removing LockDown VPN Connection ""$ConnectionName""..."
Remove-CimInstance -CimInstance $CimInstance

Write-Output "LockDown VPN connection ""$ConnectionName"" removed."
