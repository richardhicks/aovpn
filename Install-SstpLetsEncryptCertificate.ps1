<#

.SYNOPSIS
    Example PowerShell script to install a Let's Encrypt certificate in Microsoft Windows Routing and Remote Access Service (RRAS) for Always On VPN.

.PARAMETER Hostname
    The public hostname in fully qualified domain name (FQDN) format of the Always On VPN server.

.PARAMETER AdditionalNames
    An array of additional public host names (FQDNs) to include in the Subject Alternative Name field of the certificate. The -Hostname parameter is automatically included.

.PARAMETER EC
    Use this switch to create an EC (Elliptic Curve) certificate.

.PARAMETER Staging
    Use this switch to create a certificate in the Let's Encrypt staging environment. This is useful for testing purposes.

.PARAMETER ApiToken
    The Cloudflare API token used for domain validation. This is required if using the Cloudflare DNS plugin for domain validation.

.PARAMETER Contact
    The contact email address used for Let's Encrypt account registration. Certificate expiration notices will be sent to this email address.

.PARAMETER InstallCertificate
    Use this switch to install the new certificate in the Remote Access configuration and restart the service. The old certificate will be removed.

.EXAMPLE
    .\Install-SstpLetsEncryptCertificate.ps1 -Hostname 'vpn.example.com' -AdditionalNames 'vpn1.example.com', 'vpn2.example.com' -Ec -Staging -Contact 'notifications@example.com' -InstallCertificate

    This example creates a new Let's Encrypt certificate for the specified host names, using EC encryption (recommended), in the Let's Encrypt staging environment, and installs it in the Remote Access configuration.

.EXAMPLE
    .\Install-SstpLetsEncryptCertificate.ps1 -Hostname 'vpn.example.com' -AdditionalNames 'vpn1.example.com', 'vpn2.example.com' -Contact 'notifications@example.com' -InstallCertificate

    This example creates a new Let's Encrypt certificate for the specified host names, using RSA encryption, in the Let's Encrypt production environment, and installs it in the Remote Access configuration.

.DESCRIPTION
    This example script demonstrates the automated process of obtaining and installing a Let's Encrypt certificate for Windows Server Routing and Remote Access Service (RRAS) Always On VPN servers. It uses the New-Csr cmdlet from the AovpnTools module to create a Certificate Signing Request (CSR) and the Posh-ACME module to request a certificate from Let's Encrypt. The script also handles the installation of the new certificate in the Remote Access configuration if specified. The script also includes options for using Elliptic Curve (EC) encryption (recommended), specifying additional host names, and working in the Let's Encrypt staging environment for testing purposes.
    This example script uses the Cloudflare DNS plugin for domain validation. You will need to provide your Cloudflare API token in the script. The script can be modified to use other DNS plugins as needed. Details here: https://poshac.me/docs/v4/Plugins/.

.LINK
    https://github.com/richardhicks/aovpn/blob/master/Install-SstpLetsEncryptCertificate.ps1

.LINK
    https://directaccess.richardhicks.com/2021/10/04/always-on-vpn-sstp-with-lets-encrypt-certificates/

.LINK
    https://directaccess.richardhicks.com/2025/04/22/always-on-vpn-sstp-and-47-day-tls-certificates/

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        2.0
    Creation Date:  April 21, 2025
    Last Updated:   January 6, 2026
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Website:        https://directaccess.richardhicks.com/

#>

[CmdletBinding()]

Param (

    [Parameter(Mandatory, HelpMessage = 'Enter the public hostname in FQDN format of the Always On VPN server.')]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname,
    [string[]]$AdditionalNames,
    [switch]$EC,
    [switch]$Staging,
    [Parameter(Mandatory, HelpMessage = 'Enter the Cloudflare API token used for domain validation.')]
    [ValidateNotNullOrEmpty()]
    [string]$ApiToken,
    [Parameter(Mandatory, HelpMessage = "Enter the contact email address used for Let's Encrypt certificate expiration notices.")]
    [string]$Contact,
    [switch]$InstallCertificate

)

#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Module RemoteAccess, AovpnTools, Posh-ACME

# Start transcript
Start-Transcript -Path $env:temp\$($MyInvocation.MyCommand).log

# Define Let's Encrypt environment
Switch ($Staging) {

    $True { $Environment = 'LE_STAGE' }
    Default { $Environment = 'LE_PROD' }

}

# Set LE environment
Write-Verbose "Setting environment to $Environment..."
Set-PAServer $Environment

# Find current TLS certificate
$OldCert = (Get-RemoteAccess).SslCertificate.Thumbprint

If ($Null -eq $OldCert) {

    Write-Verbose 'Old certificate not found.'

}

Else {

    Write-Verbose "Current TLS certificate thumbprint is $OldCert."

}

# Define path to INF and CSR files
$CsrPath = ".\$($env:computername).csr"
$InfPath = ".\$($env:computername).inf"

# Create new CSR
If ($EC) {

    Write-Verbose 'Creating EC CSR...'
    New-Csr -Hostname $Hostname -AdditionalNames $AdditionalNames -EC

}

Else {

    Write-Verbose 'Creating RSA CSR...'
    New-Csr -Hostname $Hostname -AdditionalNames $AdditionalNames

}

# Create Let's Encrypt order
$Name = Get-Date -Format FileDateTime
Write-Verbose "Let's Encrypt order is $Name."
$Token = @{ CFToken = (ConvertTo-SecureString -String $ApiToken -AsPlainText -Force) } # ($ApiToken is passed at the command line for demonstration purposes only; in production, use a secure method to store and retrieve credentials)

# Request Let's Encrypt certificate
Write-Verbose "Requesting new Let's Encrypt certificate..."
$Params = @{

    CSRPath    = $CsrPath
    Name       = $Name
    Contact    = $Contact
    Plugin     = 'Cloudflare'
    PluginArgs = $Token
    AcceptTOS  = $True

}

$NewCert = New-PACertificate @Params

# Import certificate
Write-Verbose "Importing new Let's Encrypt certificate..."
[void](Import-Certificate -FilePath $NewCert.CertFile -CertStoreLocation Cert:\LocalMachine\My\)

If ($InstallCertificate) {

    # Bind new certificate in RRAS configuration
    Write-Verbose 'Binding new TLS certificate...'
    $Thumbprint = $NewCert.Thumbprint
    $Certificate = Get-ChildItem -Path Cert:\LocalMachine\My\$Thumbprint

    Set-RemoteAccess -SslCertificate $Certificate

    # Service restart parameters
    $RestartTimeout = 300
    $StartupTimeout = 60
    $PortCheckTimeout = 60
    $MaxRestartAttempts = 3
    $RestartAttempt = 0

    # Restart Remote Access service and validate TCP port 443 is listening
    While ($RestartAttempt -lt $MaxRestartAttempts) {

        $RestartAttempt++
        Write-Verbose "RemoteAccess service restart attempt $RestartAttempt of $MaxRestartAttempts..."
        Try {

            Write-Verbose 'Restarting the RemoteAccess service...'

            # Run service restart as a background job to prevent hanging
            $RestartJob = Start-Job -ScriptBlock {

                Restart-Service -Name RemoteAccess -Force -ErrorAction Stop

            }

            # Wait for the job to complete with timeout
            $JobCompleted = Wait-Job -Job $RestartJob -Timeout $RestartTimeout

            If ($Null -eq $JobCompleted) {

                # Job timed out (service restart operation is hanging)
                Write-Warning "Service restart operation timed out after $RestartTimeout seconds."
                Remove-Job -Job $RestartJob -Force
                Throw "RemoteAccess service restart hung and did not complete within $RestartTimeout seconds."

            }

            # Check if job encountered any errors and clean up
            Receive-Job -Job $RestartJob -ErrorAction Stop | Out-Null
            Remove-Job -Job $RestartJob -Force

            # Verify the service reached 'Running' state
            Write-Verbose 'Verifying the RemoteAccess service status...'
            $Service = Get-Service -Name RemoteAccess
            $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            While ($Service.Status -ne 'Running' -and $Stopwatch.Elapsed.TotalSeconds -lt $StartupTimeout) {

                Start-Sleep -Seconds 5
                $Service.Refresh()

            }

            # Final check
            If ($Service.Status -eq 'Running') {

                Write-Verbose 'The RemoteAccess service restarted successfully.'

            }

            Else {

                Throw "The RemoteAccess service did not return to 'Running' state within $StartupTimeout seconds."

            }

            # Verify TCP port 443 is listening
            Write-Verbose 'Verifying TCP port 443 is in a listening state...'
            $PortListening = $False
            $PortStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            While (-not $PortListening -and $PortStopwatch.Elapsed.TotalSeconds -lt $PortCheckTimeout) {

                $TcpConnection = Get-NetTCPConnection -LocalPort 443 -State Listen -ErrorAction SilentlyContinue

                If ($TcpConnection) {

                    $PortListening = $True
                    Write-Verbose 'TCP port 443 is listening.'
                    Break

                }

                Start-Sleep -Seconds 5

            }

            # Check if TCP port 443 is listening after timeout
            If (-not $PortListening) {

                Write-Warning "TCP port 443 is not listening after $PortCheckTimeout seconds."

                If ($RestartAttempt -ge $MaxRestartAttempts) {

                    Write-Error 'TCP port 443 failed to start listening after maximum restart attempts.'
                    Write-Warning 'Forcing reboot due to persistent port 443 issue.'
                    Stop-Transcript
                    Restart-Computer -Force

                }

                Else {

                    Write-Verbose 'Retrying RemoteAccess service restart...'

                }

            }

            Else {

                # Port is listening successfully, exit the restart loop
                Write-Verbose 'The RemoteAccess service restart completed successfully with TCP port 443 confirmed listening.'
                Break

            }

        }

        Catch {

            Write-Error "Failed to restart the RemoteAccess service on attempt $RestartAttempt. $_"

            If ($RestartAttempt -ge $MaxRestartAttempts) {

                Write-Warning 'Error restarting the RemoteAccess service after maximum attempts. Forcing reboot.'
                Stop-Transcript
                Restart-Computer -Force

            }

            Else {

                Write-Verbose 'Retrying the RemoteAccess service restart...'

            }

        }

    }

    # Remove old certificate
    If ($Null -ne $OldCert) {

        Remove-Item Cert:\LocalMachine\My\$OldCert

    }

}

# Clean up
Write-Verbose 'Cleaning up...'
Remove-Item $CsrPath
Remove-Item $InfPath

# Stop transcript
Stop-Transcript
