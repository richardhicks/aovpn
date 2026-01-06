<#

.SYNOPSIS
    PowerShell Script to check the expiration of the current SSTP TLS certificate and optionally run another installation script to renew it.

.DESCRIPTION
    This script checks the expiration date of the current SSTP TLS certificate used by Windows Server Routing and Remote Access Service (RRAS). If the certificate is set to expire within a specified renewal period, the script will call another script to install a new Let's Encrypt certificate for SSTP VPN.

.PARAMETER RenewalPeriod
    The number of days before certificate expiration to trigger a renewal. Default is 15.

.INPUTS
    None.

.OUTPUTS
    None.

.EXAMPLE
    .\Get-VpnSstpCertificateExpiration.ps1

    Checks the SSTP TLS certificate expiration and renews it if it is set to expire within the default 15 days.

.EXAMPLE
    .\Get-VpnSstpCertificateExpiration.ps1 -RenewalPeriod 10

    Checks the SSTP TLS certificate expiration and renews it if it is set to expire within 10 days.

.LINK
    https://github.com/richardhicks/aovpn/blob/master/Get-VpnSstpCertificateExpiration.ps1

.LINK
    https://directaccess.richardhicks.com/2021/10/04/always-on-vpn-sstp-with-lets-encrypt-certificates/

.LINK
    https://directaccess.richardhicks.com/2025/04/22/always-on-vpn-sstp-and-47-day-tls-certificates/

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.0
    Creation Date:  January 1, 1980
    Last Updated:   January 1, 1980
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Website:        https://www.richardhicks.com/

#>

Param (

    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$RenewalPeriod = 15

)

# Prerequisites
#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Module RemoteAccess

# Start transcript
Start-Transcript -Path $env:temp\$($MyInvocation.MyCommand).log

# Identify current SSTP TLS certificate
Write-Verbose 'Identifying current SSTP TLS certificate...'
$CurrentCertificate = (Get-RemoteAccess).SslCertificate.Thumbprint

If ($CurrentCertificate) {

    Write-Verbose "Current SSTP TLS certificate thumbprint is $CurrentCertificate."
    Write-Verbose 'Checking expiration...'
    $Certificate = Get-Item -Path Cert:\LocalMachine\My\$CurrentCertificate -ErrorAction SilentlyContinue

    # Check certificate expiration
    If ($Certificate) {

        $DaysToExpire = ($Certificate.NotAfter - (Get-Date)).Days

        If ($DaysToExpire -gt $RenewalPeriod) {

            Write-Verbose "Current SSTP TLS certificate expires in $DaysToExpire days, which is greater than the specified renewal period of $RenewalPeriod days. Exiting script"
            Stop-Transcript
            Exit 0

        }

    }

    Else {

        Write-Warning "Unable to locate current SSTP TLS certificate with thumbprint $CurrentCertificate. Proceeding with installation..."

    }

}

Else {

    Write-Verbose 'SSTP TLS certificate missing or not configured. Proceeding with installation...'

}

# Run Install-SstpLetsEncryptCertificate script
Write-Verbose 'Running Install-SstpLetsEncryptCertificate script...'
# Path to .\Install-SstpLetsEncryptCertificate.ps1 script with included parameters

# Stop transcript
Stop-Transcript
