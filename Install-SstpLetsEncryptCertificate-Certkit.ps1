<#

.SYNOPSIS
    PowerShell script to automate the installation and assignment of a Let's Encrypt TLS certificate on Windows Server Routing and Remote Access Service (RRAS) servers using CertKit and the MinIO client.

.DESCRIPTION
    CertKit (https://certkit.io) is an online service that manages and monitors Let's Encrypt certificates. This script automates the process of downloading a TLS certificate from CertKit using the MinIO client, importing it into the local machine certificate store, assigning it to RRAS for SSTP use, and restarting the Remote Access service with verification that TCP port 443 is listening. If the service fails to restart properly after multiple attempts, the script will initiate a system reboot to recover from potential service hang issues.

    IMPORTANT! This script is designed to be run as a scheduled task and will automatically restart the RemoteAccess service, which will terminate all active VPN connections. Also, the server will be forcibly rebooted if the RemoteAccess services fails to restart successfully. Use this script with caution in production environments and ensure it runs during non-peak times.

.PARAMETER RenewalPeriod
    Specifies the number of days before certificate expiration to trigger a renewal. Default is 15 days. Valid range is 1 to 30 days.

.PARAMETER Force
    Forces the script to proceed with certificate installation even if the current certificate has more than the specified days remaining before expiration. Use this switch when performing initial server configuration or when you want to replace the existing certificate regardless of its expiration status.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    .\Install-SstpLetsEncryptCertificate-CertKit.ps1

    Runs the script to check the current SSTP certificate and install a new one if it is expiring within 15 days.

.EXAMPLE
    .\Install-SstpLetsEncryptCertificate-CertKit.ps1 -Force

    Runs the script to install a new SSTP certificate regardless of the current certificate's expiration status.

.EXAMPLE
    .\Install-SstpLetsEncryptCertificate-CertKit.ps1 -RenewalPeriod 10

    Runs the script to check the current SSTP certificate and install a new one if it is expiring within 10 days.

.LINK
    https://github.com/richardhicks/aovpn/blob/master/Install-SstpLetsEncryptCertificate-CertKit.ps1

.LINK
    https://certkit.io/

.LINK
    https://www.richardhicks.com/

.NOTES
    Version:        1.0
    Creation Date:  January 2, 2026
    Last Updated:   January 2, 2026
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Website:        https://www.richardhicks.com/

#>

[CmdletBinding()]

Param (

    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$RenewalPeriod = 15,
    [Switch]$Force

)

# Prerequisites
#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Module RemoteAccess

# Start transcript
Start-Transcript -Path $env:temp\$($MyInvocation.MyCommand).log

# CertKit S3 storage variables (these values can be obtained from the CertKit dashboard storage browser)
$s3_bucket = ''
$s3_certificate_id = ''
$s3_certificate_name = ''
$s3_certificate_path = Join-Path -Path certificate-$s3_certificate_id -ChildPath $s3_certificate_name

# CertKit S3 access credentials (credentials are hardcoded for demonstration purposes only; in production, use a secure method to store and retrieve credentials)
$s3_access_key = ''
$s3_secret_key = ''

Write-Verbose "Using CertKit S3 bucket $s3_bucket and certificate $s3_certificate_path."

# Set MinIO client path (can also reference a shared location such as \\server\share\mc.exe)
$MinIOPath = Join-Path -Path $env:TEMP -ChildPath 'mc.exe'
Write-Verbose "MinIO client path set to $MinIOPath."

# Download MinIO client if not present
If (Test-Path -Path $MinIOPath) {

    Write-Verbose 'MinIO client already exists. Skipping download.'

}

Else {

    Write-Verbose 'Downloading MinIO client...'
    Invoke-WebRequest -Uri 'https://dl.min.io/client/mc/release/windows-amd64/mc.exe' -OutFile $MinIOPath

}

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

        If (-not $Force -and $DaysToExpire -gt $RenewalPeriod) {

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

# Define certificate file path
$CertificatePath = Join-Path -Path $env:TEMP -ChildPath $s3_certificate_name
Write-Verbose "Certificate path set to $CertificatePath."

# Download certificate from CertKit S3 bucket using the MinIO client
& $MinIOPath alias set certkit https://storage.certkit.io $s3_access_key $s3_secret_key
& $MinIOPath cp "certkit/$s3_bucket/$s3_certificate_path" $CertificatePath

# Validate download
If (-Not (Test-Path -Path $CertificatePath)) {

    Write-Error 'Failed to download certificate from CertKit S3 bucket. Exiting script.'
    Stop-Transcript
    Exit 1

}

# Import certificate
Write-Verbose 'Importing new certificate...'
$Password = ConvertTo-SecureString -String $s3_secret_key -AsPlainText -Force
$NewCertificate = Import-PfxCertificate -FilePath $CertificatePath -CertStoreLocation Cert:\LocalMachine\My -Password $Password

Write-Verbose "New certificate thumbprint is $($NewCertificate.Thumbprint)."

# Add CertKit certificate ID to certificate friendly name field
$StoredCertificate = Get-Item -Path "Cert:\LocalMachine\My\$($NewCertificate.Thumbprint)"
$StoredCertificate.FriendlyName = "CertKit ID $($s3_certificate_id.ToUpper())"

# Assign new certificate to Remote Access
Write-Verbose 'Assigning new SSTP certificate...'
Set-RemoteAccess -SslCertificate $NewCertificate

# Cleanup
Write-Verbose 'Removing downloaded certificate file...'
Remove-Item -Path $CertificatePath -Force

# Remove old certificate if it exists and is different from the new one
If ($Null -ne $CurrentCertificate -and $CurrentCertificate -ne $NewCertificate.Thumbprint) {

    Write-Verbose "Removing old certificate with thumbprint $CurrentCertificate..."
    Remove-Item Cert:\LocalMachine\My\$CurrentCertificate

}

ElseIf ($CurrentCertificate -eq $NewCertificate.Thumbprint) {

    Write-Verbose 'Old certificate matches new certificate. Skipping removal.'

}

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

# Stop transcript
Stop-Transcript
