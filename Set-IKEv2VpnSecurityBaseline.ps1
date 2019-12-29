<#

.SYNOPSIS
    Configure baseline security settings for IPsec on Windows Server Routing and Remote Access Service (RRAS) servers.

.PARAMETER Restart
    Restarts the RemoteAccess service after implementing IPsec policy changes.

.EXAMPLE
    .\Set-IKEv2VpnSecurityBaseline.ps1

.EXAMPLE
    .\Set-IKEv2VpnSecurityBaseline.ps1 -Restart

.DESCRIPTION
    The default IPsec policy settings for Windows Server RRAS IKEv2 VPN connections are considered weak and should be updated. This script implements current minimum security best practices for IPsec.

.LINK
    https://directaccess.richardhicks.com/2018/12/10/always-on-vpn-ikev2-security-configuration/

.NOTES
    Version:        1.0
    Creation Date:  July 26, 2019
    Last Updated:   July 26, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param(

    [switch]$Restart

)

# Minimum recommended security settings for IPsec VPN
# Settings documented here: https://docs.microsoft.com/en-us/windows/client-management/mdm/vpnv2-csp

$Parameters = @{

    AuthenticationTransformConstants    = 'SHA256128'
    CipherTransformConstants            = 'AES128'
    DHGroup                             = 'Group14'
    EncryptionMethod                    = 'AES128'
    IntegrityCheckMethod                = 'SHA256'
    PFSgroup                            = 'PFS2048'
    SALifeTimeSeconds                   = '28800'
    SADataSizeForRenegotiationKilobytes = '102400'

}

# Implement new IPsec policy
Write-Verbose 'Configuring VPN server IPsec policy...'
[PSCustomObject]$Parameters | Set-VpnServerConfiguration -CustomPolicy

# Restart the RemoteAccess service or warn administrator that it must be restarted.
If ($Restart) {

    Write-Verbose 'Restarting the RemoteAccess service...'
    Restart-Service RemoteAccess -PassThru
}

Else {

    Write-Warning 'The RemoteAccess service must be restarted for changes to take effect.'
    
}
