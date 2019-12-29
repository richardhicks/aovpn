<#

.SYNOPSIS
    Configures the trusted root certification authority to be used for IKEv2 VPN connection on Windows Server Routing and Remote Access Service (RRAS) servers.

.PARAMETER Thumbprint
    Certificate hash of the trusted root certification authority used for IKEv2 VPN connections.

.PARAMETER EnableCertificateAuthnetication
    Enables machine certificate authentication for IKEv2 VPN connections.

.PARAMETER Clear
    Clears the currently configured root certification authority.

.PARAMETER Restart
    Restarts the RemoteAccess service.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Clear

    Running this command will clear the existing root certification authority configuration.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332' -Restart

    Running this command will configure RRAS to use this certification authority as the exclusive trusted CA for all IKEv2 VPN connections. Including the -Restart swtich restarts the RemoteAccess service for changes to take effect.
    
.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332' -EnableCertificateAuthentication

    Running this command will configure RRAS to use this certification authority as the exclusive trusted CA for all IKEv2 VPN connections. Including the -EnableCertificateAuthentication switch will automatically add Certificate authentication to the list of accepted user authentication protocols (prerequisite for setting root CA cert).

.DESCRIPTION
    Use this script to configure the trusted root certification authority for IKEv2 VPN connections.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.11
    Creation Date:  August 2, 2019
    Last Updated:   October 29, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param (
    
    [string]$Thumbprint,
    [switch]$EnableCertificateAuthnetication,
    [switch]$Clear,
    [switch]$Restart

)

# Clear current root certificate configuration
If ($Clear) {

    Write-Verbose 'Clearing existing root certificate configuration...'
    Set-VpnAuthProtocol -RootCertificateNameToAccept $Null

    If ($Restart) {

        Write-Verbose 'Restarting the RemoteAccess Service...'
        Restart-Service RemoteAccess -PassThru
        
    }

    ElseIf (-Not $Restart) {
        
        Write-Warning 'The RemoteAccess service must be restarted for these changes to take effect.'
    }

    Exit

}

# Get current user authentication protocol configuration
$VpnAuthProtocol = (Get-VpnAuthProtocol | Select-Object -ExpandProperty UserAuthProtocolAccepted)

# Ensure that certificate authentication is enabled
If ($VpnAuthProtocol -like '*certificate*') {

    Write-Verbose 'Certificate authentication enabled.'

}

ElseIf (-Not $EnableCertificateAuthnetication) {

    Write-Warning 'Certificate authentication not enabled. Use the -EnableCertificateAuthnetication parameter to configure it.'
    Exit

}

# Assign root certificate 
$RootCACert = (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1)

# Create user authentication protocol array
$Protocols = @()
$Protocols = { $Protocols }.Invoke()

ForEach ($Protocol in $VpnAuthProtocol) {

    $Protocols.Add($Protocol)

}

# Add the Certificate authentication protocol is required
If ($EnableCertificateAuthnetication) {

    $Protocols.Add('Certificate')

}

Write-Verbose 'Updating trusted root certificate information...'
Set-VpnAuthProtocol -UserAuthProtocolAccepted $Protocols -RootCertificateNameToAccept $RootCACert -PassThru

If ($Restart) {
    
    Write-Verbose 'Restarting the RemoteAccess service...'
    Restart-Service RemoteAccess -PassThru

}

Else {

    Write-Warning 'The RemoteAccess service must be restarted for these changes to take effect.'

}
